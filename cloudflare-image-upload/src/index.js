import { importX509, jwtVerify, decodeProtectedHeader } from "jose";

const CERT_URL =
  "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

const ALLOWED_FOLDERS = new Set([
  "products",
  "categories",
  "bundles",
  "hero",
]);

const MAX_BYTES = 4 * 1024 * 1024;

function corsHeaders(origin) {
  return {
    "Access-Control-Allow-Origin": origin || "*",
    "Access-Control-Allow-Headers": "Content-Type, Authorization",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Content-Type": "application/json; charset=utf-8",
  };
}

function json(data, status, origin) {
  return new Response(JSON.stringify(data), {
    status,
    headers: corsHeaders(origin),
  });
}

async function verifyFirebaseToken(idToken, projectId) {
  const header = decodeProtectedHeader(idToken);
  if (header.alg !== "RS256" || !header.kid) {
    throw new Error("Invalid Firebase token header.");
  }

  const certResponse = await fetch(CERT_URL, {
    cf: { cacheTtl: 3600, cacheEverything: true },
  });

  if (!certResponse.ok) {
    throw new Error("Could not load Firebase public signing keys.");
  }

  const certs = await certResponse.json();
  const certificate = certs[header.kid];

  if (!certificate) {
    throw new Error("Firebase signing key is not available.");
  }

  const publicKey = await importX509(certificate, "RS256");

  const result = await jwtVerify(idToken, publicKey, {
    issuer: "https://securetoken.google.com/" + projectId,
    audience: projectId,
    algorithms: ["RS256"],
  });

  if (!result.payload.sub || typeof result.payload.sub !== "string") {
    throw new Error("Firebase token has no user id.");
  }

  return result.payload;
}

function estimatedBytes(base64) {
  const padding = base64.endsWith("==") ? 2 : base64.endsWith("=") ? 1 : 0;
  return Math.floor(base64.length * 3 / 4) - padding;
}

async function getExistingSha(apiUrl, token) {
  const response = await fetch(apiUrl, {
    headers: {
      Authorization: "Bearer " + token,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });

  if (response.status === 404) return null;

  if (!response.ok) {
    const details = await response.text();
    throw new Error("GitHub lookup failed (" + response.status + "): " + details);
  }

  const data = await response.json();
  return data.sha || null;
}

export default {
  async fetch(request, env) {
    const origin = request.headers.get("Origin") || "*";

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: corsHeaders(origin),
      });
    }

    if (request.method !== "POST") {
      return json({ error: "Method not allowed." }, 405, origin);
    }

    try {
      const auth = request.headers.get("Authorization") || "";
      if (!auth.startsWith("Bearer ")) {
        return json({ error: "Missing Firebase authentication token." }, 401, origin);
      }

      const idToken = auth.substring(7);
      const claims = await verifyFirebaseToken(idToken, env.FIREBASE_PROJECT_ID);

      const adminUids = String(env.ADMIN_UIDS || "")
        .split(",")
        .map((value) => value.trim())
        .filter(Boolean);

      if (!adminUids.includes(String(claims.sub))) {
        return json({ error: "Admin access required." }, 403, origin);
      }

      const data = await request.json();
      const folder = String(data.folder || "");
      const fileName = String(data.fileName || "");
      const contentType = String(data.contentType || "");
      const base64 = String(data.base64 || "");

      if (!ALLOWED_FOLDERS.has(folder)) {
        return json({ error: "Invalid image folder." }, 400, origin);
      }

      if (!/^[a-zA-Z0-9._-]+$/.test(fileName)) {
        return json({ error: "Invalid image filename." }, 400, origin);
      }

      if (!contentType.startsWith("image/")) {
        return json({ error: "Only image files are allowed." }, 400, origin);
      }

      if (!base64 || !/^[A-Za-z0-9+/]*={0,2}$/.test(base64)) {
        return json({ error: "Invalid image data." }, 400, origin);
      }

      if (estimatedBytes(base64) > MAX_BYTES) {
        return json({ error: "Image must be smaller than 4 MB." }, 400, origin);
      }

      const owner = env.GITHUB_OWNER || "Jatinkanara21";
      const repo = env.GITHUB_REPO || "Campus_supply";
      const branch = env.GITHUB_BRANCH || "main";
      const githubPath = "assets/image/" + folder + "/" + fileName;

      const apiUrl =
        "https://api.github.com/repos/" +
        owner +
        "/" +
        repo +
        "/contents/" +
        githubPath +
        "?ref=" +
        encodeURIComponent(branch);

      const existingSha = await getExistingSha(apiUrl, env.GITHUB_TOKEN);

      const body = {
        message: (existingSha ? "Update " : "Add ") + folder + " image: " + fileName,
        content: base64,
        branch,
      };

      if (existingSha) body.sha = existingSha;

      const uploadUrl =
        "https://api.github.com/repos/" +
        owner +
        "/" +
        repo +
        "/contents/" +
        githubPath;

      const uploadResponse = await fetch(uploadUrl, {
        method: "PUT",
        headers: {
          Authorization: "Bearer " + env.GITHUB_TOKEN,
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2022-11-28",
          "Content-Type": "application/json",
        },
        body: JSON.stringify(body),
      });

      if (!uploadResponse.ok) {
        const details = await uploadResponse.text();
        console.error("GitHub upload failed:", details);
        return json({ error: "GitHub upload failed." }, 502, origin);
      }

      return json(
        {
          success: true,
          imagePath: githubPath,
        },
        200,
        origin
      );
    } catch (error) {
      console.error("Image upload error:", error);
      return json(
        {
          error: error instanceof Error ? error.message : "Image upload failed.",
        },
        500,
        origin
      );
    }
  },
};
