const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const { initializeApp } = require("firebase-admin/app");
const { getAuth, getFirestore } = require("firebase-admin");
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
