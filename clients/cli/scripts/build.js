const fs = require('fs');
const fsp = require('fs').promises;
const path = require('path');

async function main() {
  const srcDir = path.join(__dirname, '..', 'src');
  const distDir = path.join(__dirname, '..', 'dist');
  await fsp.mkdir(distDir, { recursive: true });
  const files = await fsp.readdir(srcDir);
  for (const file of files) {
    const from = path.join(srcDir, file);
    const to = path.join(distDir, file);
    await fsp.copyFile(from, to);
  }
  // add shebang
  const indexPath = path.join(distDir, 'index.js');
  const content = await fsp.readFile(indexPath, 'utf-8');
  await fsp.writeFile(indexPath, `#!/usr/bin/env node\n${content}`);
  fs.chmodSync(indexPath, 0o755);
}

main().catch(err => { console.error(err); process.exit(1); });



