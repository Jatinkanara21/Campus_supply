const { onObjectFinalized } = require('firebase-functions/v2/storage');
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
