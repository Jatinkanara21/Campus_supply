const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth, getFirestore } = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { Buffer } = require("buffer");

initializeApp();

const GITHUB_TOKEN = defineSecret("GITHUB_TOKEN");

const OWNER = "Jatinkanara21";
const REPO = "Campus_supply";
const BRANCH = "main";
const MAX_BYTES = 8 * 1024 * 1024;
const ALLOWED_EXTENSIONS = new Set(["jpg", "jpeg", "png", "webp", "gif"]);

function sendError(res, status, message) {
  return res.status(status).json({ ok: false, error: message });
}

function detectImage(buffer) {
  if (buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff) {
    return { extension: "jpg", contentType: "image/jpeg" };
  }

  if (
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47 &&
    buffer[4] === 0x0d &&
    buffer[5] === 0x0a &&
    buffer[6] === 0x1a &&
    buffer[7] === 0x0a
  ) {
    return { extension: "png", contentType: "image/png" };
  }

  if (
    buffer.length >= 6 &&
    ((buffer.toString("ascii", 0, 6) === "GIF89a") ||
      (buffer.toString("ascii", 0, 6) === "GIF87a"))
  ) {
    return { extension: "gif", contentType: "image/gif" };
  }

  if (
    buffer.length >= 12 &&
    buffer.toString("ascii", 0, 4) === "RIFF" &&
    buffer.toString("ascii", 8, 12) === "WEBP"
  ) {
    return { extension: "webp", contentType: "image/webp" };
  }

  return null;
}

function safeBaseName(name) {
  const cleaned = String(name || "image")
    .trim()
    .replace(/\.[^.]*$/, "")
    .toLowerCase()
    .replace(/[^a-z0-9._-]+/g, "_")
    .replace(/_+/g, "_")
    .replace(/^\.+|\.+$/g, "");

  return cleaned || "image";
}

function sanitizeExtension(fileName, detected) {
  const provided = String(fileName || "")
    .trim()
    .split(".")
    .pop()
    ?.toLowerCase();

  if (provided && ALLOWED_EXTENSIONS.has(provided)) {
    return provided;
  }

  return detected.extension;
}

function getRequestBody(req) {
  if (!req.body) return {};
  if (typeof req.body === "object") return req.body;
  if (typeof req.body === "string") {
    try {
      return JSON.parse(req.body);
    } catch {
      return {};
    }
  }
  return {};
}


class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function parseBearer(req) {
  const header = String(req.get("authorization") || "").trim();
  if (header.substring(0, 6).toLowerCase() !== "bearer") {
    throw new ApiError(401, "Please sign in to continue.");
  }
  const token = header.substring(6).trim();
  if (!token) throw new ApiError(401, "Please sign in to continue.");
  return token;
}

async function authenticatedUser(req) {
  try {
    return await getAuth().verifyIdToken(parseBearer(req));
  } catch (error) {
    if (error instanceof ApiError) throw error;
    throw new ApiError(401, "Your session is invalid or expired. Please sign in again.");
  }
}

async function requireAdmin(uid) {
  const userSnapshot = await getFirestore().collection("users").doc(uid).get();
  const userData = userSnapshot.exists ? userSnapshot.data() : {};
  if (userData.role !== "admin" && userData.admin !== true) {
    throw new ApiError(403, "Only an administrator can update order status.");
  }
}

function cleanText(value) {
  return String(value == null ? "" : value).trim();
}

function numberValue(value, fallback) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

function stockValue(productData) {
  return Math.max(0, Math.floor(numberValue(productData && productData.stock, 0)));
}

function addRequiredStock(required, productId, quantity) {
  const cleanId = cleanText(productId);
  if (!cleanId) throw new ApiError(400, "An order item is missing its product information.");
  required.set(cleanId, (required.get(cleanId) || 0) + quantity);
}

function orderStockRequirements(items) {
  if (!Array.isArray(items) || items.length === 0) {
    throw new ApiError(400, "Your bag is empty. Add an item before checkout.");
  }
  const required = new Map();
  for (const item of items) {
    const quantity = Number(item && item.quantity);
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
      throw new ApiError(400, "Each order quantity must be between 1 and 99.");
    }
    const isBundle = item && item.itemType === "bundle";
    if (isBundle) {
      const rawIds = Array.isArray(item.includedProductIds) && item.includedProductIds.length
        ? item.includedProductIds
        : Array.isArray(item.includedItems)
          ? item.includedItems.map((entry) => entry && entry.productId).filter(Boolean)
          : [];
      if (!rawIds.length) {
        throw new ApiError(400, cleanText(item.name) + " has no included products configured.");
      }
      for (const productId of rawIds) addRequiredStock(required, productId, quantity);
    } else {
      addRequiredStock(required, item && item.productId, quantity);
    }
  }
  return required;
}

async function readProductInTransaction(transaction, db, productSnapshots, productId) {
  if (productSnapshots.has(productId)) return productSnapshots.get(productId);
  const snapshot = await transaction.get(db.collection("products").doc(productId));
  productSnapshots.set(productId, snapshot);
  return snapshot;
}

exports.placeOrder = onRequest(
  { region: "us-central1", timeoutSeconds: 60, memory: "256MiB", cors: true },
  async (req, res) => {
    if (req.method !== "POST") return sendError(res, 405, "POST is required.");

    try {
      const identity = await authenticatedUser(req);
      const payload = getRequestBody(req);
      const customerName = cleanText(payload.customerName);
      const customerPhone = cleanText(payload.customerPhone);
      const deliveryAddress = cleanText(payload.deliveryAddress);
      const deliveryCity = cleanText(payload.deliveryCity);
      const deliveryPinCode = cleanText(payload.deliveryPinCode);
      if (!customerName || !customerPhone || !deliveryAddress || !deliveryCity || !deliveryPinCode) {
        throw new ApiError(400, "Please complete all required delivery details.");
      }

      const requestedTotal = Number(payload.total);
      if (!Number.isFinite(requestedTotal) || requestedTotal < 0) {
        throw new ApiError(400, "The order total is invalid. Please review your bag.");
      }

      const requestedLines = Array.isArray(payload.items) ? payload.items : [];
      if (requestedLines.length === 0) {
        throw new ApiError(400, "Your bag is empty. Add an item before checkout.");
      }
      const db = getFirestore();
      const orderRef = db.collection("orders").doc();
      let finalTotal = 0;

      await db.runTransaction(async (transaction) => {
        const productSnapshots = new Map();
        const bundleSnapshots = new Map();
        const requiredStock = new Map();
        const resolvedLines = [];

        for (const line of requestedLines) {
          const quantity = Number(line && line.quantity);
          if (!Number.isInteger(quantity) || quantity < 1 || quantity > 99) {
            throw new ApiError(400, "Each order quantity must be between 1 and 99.");
          }

          if (line && line.itemType === "bundle") {
            const bundleId = cleanText(line.bundleId);
            if (!bundleId) throw new ApiError(400, "A bundle in your bag is missing its ID.");
            let bundleSnapshot = bundleSnapshots.get(bundleId);
            if (!bundleSnapshot) {
              bundleSnapshot = await transaction.get(db.collection("bundles").doc(bundleId));
              bundleSnapshots.set(bundleId, bundleSnapshot);
            }
            if (!bundleSnapshot.exists) {
              throw new ApiError(409, "A bundle in your bag is no longer available. Please refresh your bag.");
            }
            const bundleData = bundleSnapshot.data() || {};
            const productIds = Array.isArray(bundleData.productIds)
              ? bundleData.productIds.map((id) => cleanText(id)).filter(Boolean)
              : [];
            if (!productIds.length) {
              throw new ApiError(409, cleanText(bundleData.name || bundleData.title || "This bundle") + " has no included products configured.");
            }
            const bundlePrice = numberValue(bundleData.price, NaN);
            if (!Number.isFinite(bundlePrice) || bundlePrice < 0) {
              throw new ApiError(409, "This bundle has an invalid package price. Please contact the store admin.");
            }
            for (const productId of productIds) {
              addRequiredStock(requiredStock, productId, quantity);
            }
            resolvedLines.push({
              itemType: "bundle",
              bundleId,
              bundleData,
              productIds,
              quantity,
              unitPrice: bundlePrice,
            });
          } else {
            const productId = cleanText(line && line.productId);
            if (!productId) throw new ApiError(400, "A product in your bag is missing its ID.");
            const productSnapshot = await readProductInTransaction(transaction, db, productSnapshots, productId);
            if (!productSnapshot.exists) {
              throw new ApiError(409, "A product in your bag is no longer available. Please refresh your bag.");
            }
            const productData = productSnapshot.data() || {};
            const price = numberValue(productData.price, NaN);
            if (!Number.isFinite(price) || price < 0) {
              throw new ApiError(409, cleanText(productData.name || productId) + " has an invalid price.");
            }
            addRequiredStock(requiredStock, productId, quantity);
            resolvedLines.push({
              itemType: "product",
              productId,
              productData,
              quantity,
              unitPrice: price,
            });
          }
        }

        // Load every product referenced by bundles before any writes are issued.
        for (const productId of requiredStock.keys()) {
          const snapshot = await readProductInTransaction(transaction, db, productSnapshots, productId);
          if (!snapshot.exists) {
            throw new ApiError(409, "A product included in your order is no longer available. Please refresh your bag.");
          }
        }

        const nextStock = new Map();
        for (const [productId, requestedQuantity] of requiredStock.entries()) {
          const snapshot = productSnapshots.get(productId);
          const productData = snapshot.data() || {};
          const available = stockValue(productData);
          if (available < requestedQuantity) {
            const productName = cleanText(productData.name || productId);
            throw new ApiError(
              409,
              productName + " has only " + available + " in stock, but your order needs " +
                requestedQuantity + ". Please update your bag and try again."
            );
          }
          nextStock.set(productId, available - requestedQuantity);
        }

        const orderItems = resolvedLines.map((line) => {
          if (line.itemType === "bundle") {
            const bundle = line.bundleData;
            const includedItems = line.productIds.map((productId) => {
              const productData = productSnapshots.get(productId).data() || {};
              return {
                productId,
                name: cleanText(productData.name || productId),
                price: numberValue(productData.price, 0),
                imageUrl: cleanText(productData.imageUrl),
              };
            });
            return {
              itemType: "bundle",
              bundleId: line.bundleId,
              name: cleanText(bundle.name || bundle.title || "Student Bundle"),
              price: line.unitPrice,
              imageUrl: cleanText(bundle.imageUrl || bundle.image),
              quantity: line.quantity,
              includedProductIds: line.productIds,
              includedItems,
            };
          }
          return {
            itemType: "product",
            productId: line.productId,
            name: cleanText(line.productData.name || line.productId),
            price: line.unitPrice,
            imageUrl: cleanText(line.productData.imageUrl),
            quantity: line.quantity,
          };
        });

        finalTotal = resolvedLines.reduce((sum, line) => sum + line.unitPrice * line.quantity, 0);
        if (Math.abs(finalTotal - requestedTotal) > 0.01) {
          throw new ApiError(
            409,
            "A product or bundle price changed while your bag was open. Please return to your bag and check the updated total."
          );
        }

        // Stock decrements and order creation commit together as one transaction.
        for (const [productId, remaining] of nextStock.entries()) {
          transaction.update(db.collection("products").doc(productId), {
            stock: remaining,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        transaction.set(orderRef, {
          userId: identity.uid,
          items: orderItems,
          total: finalTotal,
          status: "pending",
          customerName,
          customerPhone,
          customerEmail: cleanText(identity.email || payload.customerEmail),
          deliveryAddress,
          deliveryCity,
          deliveryPinCode,
          stockDeducted: true,
          stockRestocked: false,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });
      });

      return res.status(200).json({ ok: true, orderId: orderRef.id, total: finalTotal });
    } catch (error) {
      console.error("placeOrder failed", error);
      const status = error instanceof ApiError ? error.status : 500;
      return sendError(
        res,
        status,
        error && error.message ? error.message : "Could not place the order. Please try again."
      );
    }
  }
);

exports.updateOrderStatus = onRequest(
  { region: "us-central1", timeoutSeconds: 60, memory: "256MiB", cors: true },
  async (req, res) => {
    if (req.method !== "POST") return sendError(res, 405, "POST is required.");

    try {
      const identity = await authenticatedUser(req);
      await requireAdmin(identity.uid);
      const payload = getRequestBody(req);
      const orderId = cleanText(payload.orderId);
      const nextStatus = cleanText(payload.status).toLowerCase();
      const allowedStatuses = new Set(["pending", "confirmed", "shipped", "delivered", "cancelled"]);
      if (!orderId || !allowedStatuses.has(nextStatus)) {
        throw new ApiError(400, "A valid order ID and status are required.");
      }

      const db = getFirestore();
      const orderRef = db.collection("orders").doc(orderId);
      await db.runTransaction(async (transaction) => {
        const orderSnapshot = await transaction.get(orderRef);
        if (!orderSnapshot.exists) throw new ApiError(404, "This order could not be found.");

        const orderData = orderSnapshot.data() || {};
        const currentStatus = cleanText(orderData.status || "pending").toLowerCase();
        const stockWasDeducted = orderData.stockDeducted === true;
        const wasRestocked = orderData.stockRestocked === true;
        const shouldRestock = stockWasDeducted && !wasRestocked &&
          currentStatus !== "cancelled" && nextStatus === "cancelled";
        const shouldDeductAgain = stockWasDeducted && wasRestocked &&
          currentStatus === "cancelled" && nextStatus !== "cancelled";

        const items = Array.isArray(orderData.items) ? orderData.items : [];
        const requirements = (shouldRestock || shouldDeductAgain)
          ? orderStockRequirements(items)
          : new Map();
        const productSnapshots = new Map();

        for (const productId of requirements.keys()) {
          const snapshot = await transaction.get(db.collection("products").doc(productId));
          productSnapshots.set(productId, snapshot);
        }

        const nextStock = new Map();
        for (const [productId, quantity] of requirements.entries()) {
          const snapshot = productSnapshots.get(productId);
          if (!snapshot.exists) {
            if (shouldRestock) continue;
            throw new ApiError(409, "A product from this order is no longer in the catalog; the order cannot be reopened.");
          }
          const productData = snapshot.data() || {};
          const currentStock = stockValue(productData);
          if (shouldDeductAgain && currentStock < quantity) {
            throw new ApiError(
              409,
              cleanText(productData.name || productId) + " has only " + currentStock +
                " in stock. There is not enough stock to reopen this order."
            );
          }
          nextStock.set(productId, shouldRestock ? currentStock + quantity : shouldDeductAgain ? currentStock - quantity : currentStock);
        }

        for (const [productId, quantity] of nextStock.entries()) {
          transaction.update(db.collection("products").doc(productId), {
            stock: quantity,
            updatedAt: FieldValue.serverTimestamp(),
          });
        }

        transaction.update(orderRef, {
          status: nextStatus,
          updatedAt: FieldValue.serverTimestamp(),
          ...(shouldRestock ? { stockRestocked: true } : {}),
          ...(shouldDeductAgain ? { stockRestocked: false } : {}),
        });
      });

      return res.status(200).json({ ok: true, orderId, status: nextStatus });
    } catch (error) {
      console.error("updateOrderStatus failed", error);
      const status = error instanceof ApiError ? error.status : 500;
      return sendError(
        res,
        status,
        error && error.message ? error.message : "Could not update order status. Please try again."
      );
    }
  }
);

exports.uploadImageToGitHub = onRequest(
  {
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: [GITHUB_TOKEN],
    cors: true,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      return sendError(res, 405, "POST is required.");
    }

    try {
      const authHeader = req.get("authorization") || "";
      const match = authHeader.match(/^Bearer\s+(.+)$/i);
      if (!match) {
        return sendError(res, 401, "Unauthorized");
      }

      const decoded = await getAuth().verifyIdToken(match[1]);
      const userDoc = await getFirestore().collection("users").doc(decoded.uid).get();
      const role = userDoc.exists ? userDoc.data()?.role : null;

      if (role !== "admin") {
        return sendError(res, 403, "Only administrators can upload catalog images.");
      }

      const payload = getRequestBody(req);
      const { fileName, base64, folder } = payload;
      if (!fileName || !base64) {
        return sendError(res, 400, "fileName and base64 are required.");
      }

      const decodedImage = Buffer.from(String(base64), "base64");
      if (!decodedImage.length) {
        return sendError(res, 400, "The selected image is empty.");
      }
      if (decodedImage.length > MAX_BYTES) {
        return sendError(res, 413, "Image is larger than 8 MB.");
      }

      const detected = detectImage(decodedImage);
      if (!detected) {
        return sendError(res, 400, "Unsupported image. Use JPG, JPEG, PNG, WEBP or GIF.");
      }

      const safeName = safeBaseName(fileName);
      const extension = sanitizeExtension(fileName, detected);
      const timestamp = Date.now();
      const path = `assets/uploaded/${timestamp}-${safeName}.${extension}`;
      const targetUrl = `https://api.github.com/repos/${OWNER}/${REPO}/contents/${encodeURI(path)}`;

      const response = await fetch(targetUrl, {
        method: "PUT",
        headers: {
          Accept: "application/vnd.github+json",
          Authorization: `Bearer ${GITHUB_TOKEN.value()}`,
          "X-GitHub-Api-Version": "2022-11-28",
          "Content-Type": "application/json",
          "User-Agent": "Campus-Supply-Image-Uploader",
        },
        body: JSON.stringify({
          message: `Upload catalog image: ${safeName}.${extension}`,
          content: decodedImage.toString("base64"),
          branch: BRANCH,
        }),
      });

      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        const message = data && data.message ? data.message : "GitHub rejected the upload.";
        return sendError(res, response.status === 403 ? 403 : 502, message);
      }

      const rawUrl = `https://raw.githubusercontent.com/${OWNER}/${REPO}/${BRANCH}/${path}`;
      return res.status(200).json({
        ok: true,
        path,
        url: rawUrl,
        commitSha: data.commit && data.commit.sha ? data.commit.sha : null,
        folder: typeof folder === "string" ? folder : null,
      });
    } catch (error) {
      console.error("uploadImageToGitHub failed", error);
      return sendError(
        res,
        500,
        error && error.message ? error.message : "GitHub upload failed.",
      );
    }
  },
);
