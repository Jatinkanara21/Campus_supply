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

function sendError(res, status, message) {
  res.status(status).json({ ok: false, error: message });
}

function detectImage(buffer) {
  if (
    buffer.length >= 3 &&
    buffer[0] === 0xff &&
    buffer[1] === 0xd8 &&
    buffer[2] === 0xff
  ) {
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
    buffer.toString("ascii", 0, 6) === "GIF89a" ||
    buffer.toString("ascii", 0, 6) === "GIF87a"
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
  const withoutExtension = String(name || "image")
    .trim()
    .replace(/\\.[^.]*$/, "")
    .toLowerCase()
    .replace(/[^a-z0-9._-]/g, "_")
    .replace(/_+/g, "_")
    .replace(/^\.+|\.+$/g, "");

  return withoutExtension || "image";
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
      const match = authHeader.match(/^Bearer (.+)$/i);
      if (!match) {
        return sendError(res, 401, "Authentication required.");
      }

      const decoded = await getAuth().verifyIdToken(match[1]);
      const userDoc = await getFirestore().collection("users").doc(decoded.uid).get();

      if (!userDoc.exists || userDoc.data().role !== "admin") {
        return sendError(res, 403, "Admin access required.");
      }

      const { fileName, base64 } = req.body || {};
      if (!fileName || !base64) {
        return sendError(res, 400, "fileName and base64 are required.");
      }

      const bytes = Buffer.from(String(base64), "base64");
      if (!bytes.length) {
        return sendError(res, 400, "The selected image is empty.");
      }

      if (bytes.length > MAX_BYTES) {
        return sendError(res, 413, "Image is larger than 8 MB.");
      }

      const image = detectImage(bytes);
      if (!image) {
        return sendError(res, 400, "Unsupported image. Use JPG, PNG, GIF or WEBP.");
      }

      const safeName = safeBaseName(fileName);
      const timestamp = Date.now();
      const path = "assets/uploaded/" +
        timestamp + "-" + safeName + "." + image.extension;

      const githubUrl =
        "https://api.github.com/repos/" +
        OWNER + "/" + REPO + "/contents/" +
        encodeURIComponent(path).replace(/%2F/g, "/");

      const response = await fetch(githubUrl, {
        method: "PUT",
        headers: {
          "Accept": "application/vnd.github+json",
          "Authorization": "Bearer " + GITHUB_TOKEN.value(),
          "X-GitHub-Api-Version": "2022-11-28",
          "Content-Type": "application/json",
          "User-Agent": "Campus-Supply-Image-Uploader",
        },
        body: JSON.stringify({
          message: "Upload catalog image: " + safeName,
          content: bytes.toString("base64"),
          branch: BRANCH,
        }),
      });

      const data = await response.json();

      if (!response.ok) {
        const message =
          data && data.message
            ? data.message
            : "GitHub rejected the image upload.";
        return sendError(res, 502, message);
      }

      const rawUrl =
        "https://raw.githubusercontent.com/" +
        OWNER + "/" + REPO + "/" + BRANCH + "/" + path;

      return res.status(200).json({
        ok: true,
        path,
        url: rawUrl,
        contentType: image.contentType,
        commitSha: data.commit && data.commit.sha ? data.commit.sha : null,
      });
    } catch (error) {
      console.error("uploadImageToGitHub failed", error);
      return sendError(
        res,
        500,
        error && error.message ? error.message : "Image upload failed."
      );
    }
  }
);
