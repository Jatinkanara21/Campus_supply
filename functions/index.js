const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { defineSecret } = require('firebase-functions/params');
const admin = require('firebase-admin');

admin.initializeApp();

const githubToken = defineSecret('GITHUB_CONTENTS_TOKEN');

const OWNER = 'Jatinkanara21';
const REPO = 'Campus_supply';
const BRANCH = 'main';

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

    // Only sync images uploaded by the Campus Supply admin uploader.
    const match = name.match(/^public\/(products|bundles|categories)\/([^/]+)$/);
    if (!match) return;

    const contentType = object.contentType || '';
    if (!contentType.startsWith('image/')) return;

    const bucket = admin.storage().bucket(object.bucket);
    const file = bucket.file(name);
    const [buffer] = await file.download();

    const collection = match[1];
    const fileName = match[2];
    const githubPath = `assets/images/${collection}/${fileName}`;

    const response = await fetch(
      `https://api.github.com/repos/${OWNER}/${REPO}/contents/${githubPath}`,
      {
        method: 'PUT',
        headers: {
          'Authorization': `Bearer ${githubToken.value()}`,
          'Accept': 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: `Add ${collection} image: ${fileName}`,
          content: buffer.toString('base64'),
          branch: BRANCH,
        }),
      },
    );

    if (!response.ok) {
      const details = await response.text();
      throw new Error(`GitHub upload failed (${response.status}): ${details}`);
    }

    console.log(`Synced ${name} to GitHub at ${githubPath}`);
  },
);
