const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const githubToken = defineSecret('GITHUB_CONTENTS_TOKEN');

const OWNER = 'Jatinkanara21';
const REPO = 'Campus_supply';
const BRANCH = 'main';

async function syncFileToGitHub({ buffer, githubPath, message }) {
  const apiUrl =
    'https://api.github.com/repos/' + OWNER + '/' + REPO + '/contents/' + githubPath;

  const headers = {
    Authorization: 'Bearer ' + githubToken.value(),
    Accept: 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
    'Content-Type': 'application/json',
  };

  // GitHub requires the existing blob SHA when replacing an existing file.
  const existing = await fetch(apiUrl + '?ref=' + encodeURIComponent(BRANCH), {
    headers,
  });

  let existingSha;
  if (existing.ok) {
    const data = await existing.json();
    existingSha = data.sha;
  } else if (existing.status !== 404) {
    const details = await existing.text();
    throw new Error('GitHub lookup failed (' + existing.status + '): ' + details);
  }

  const body = {
    message,
    content: buffer.toString('base64'),
    branch: BRANCH,
  };

  if (existingSha) {
    body.sha = existingSha;
  }

  const response = await fetch(apiUrl, {
    method: 'PUT',
    headers,
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error('GitHub upload failed (' + response.status + '): ' + details);
  }

  return response.json();
}

exports.uploadImageToGitHub = onCall(
  {
    region: 'us-central1',
    secrets: [githubToken],
    timeoutSeconds: 120,
    memory: '512MiB',
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError('unauthenticated', 'You must be signed in as an admin.');
    }

    const userSnap = await admin.firestore()
      .collection('users')
      .doc(request.auth.uid)
      .get();
    if (userSnap.data()?.role !== 'admin') {
      throw new HttpsError('permission-denied', 'Admin access is required.');
    }

    const data = request.data || {};
    const folder = String(data.folder || '');
    const fileName = String(data.fileName || '');
    const contentType = String(data.contentType || '');
    const base64 = String(data.base64 || '');

    if (!['products', 'categories', 'bundles', 'hero'].includes(folder)) {
      throw new HttpsError('invalid-argument', 'Invalid image folder.');
    }
    if (!/^[a-zA-Z0-9._-]+$/.test(fileName)) {
      throw new HttpsError('invalid-argument', 'Invalid image filename.');
    }
    if (!contentType.startsWith('image/')) {
      throw new HttpsError('invalid-argument', 'Only image files are allowed.');
    }
    if (!base64) {
      throw new HttpsError('invalid-argument', 'Image data is missing.');
    }

    const buffer = Buffer.from(base64, 'base64');
    if (buffer.length > 6 * 1024 * 1024) {
      throw new HttpsError('invalid-argument', 'Image must be smaller than 6 MB.');
    }

    const githubPath = 'assets/image/' + folder + '/' + fileName;
    try {
      await syncFileToGitHub({
        buffer,
        githubPath,
        message: 'Add ' + folder + ' image: ' + fileName,
      });
    } catch (error) {
      console.error('GitHub image upload failed:', error);
      throw new HttpsError('internal', 'GitHub image upload failed. Check the GitHub token and repository permissions.');
    }

    return { imagePath: githubPath };
  },
);

exports.syncImageToGitHub = onObjectFinalized(
  {
    region: 'us-central1',
    secrets: [githubToken],
    timeoutSeconds: 120,
    memory: '512MiB',
  },
  async (event) => {
    const object = event.data;
    const name = object.name || '';

    // Admin uploads go to public/{products|categories|bundles|hero}/filename.
    const match = name.match(/^public\/(products|bundles|categories|hero)\/([^/]+)$/);
    if (!match) return;

    const contentType = object.contentType || '';
    if (!contentType.startsWith('image/')) return;

    const bucket = admin.storage().bucket(object.bucket);
    const file = bucket.file(name);
    const [buffer] = await file.download();

    const collection = match[1];
    const fileName = match[2];
    const githubPath = 'assets/image/' + collection + '/' + fileName;

    await syncFileToGitHub({
      buffer,
      githubPath,
      message: 'Add ' + collection + ' image: ' + fileName,
    });

    console.log('Synced ' + name + ' to GitHub at ' + githubPath);
  },
);
