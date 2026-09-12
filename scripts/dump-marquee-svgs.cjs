#!/usr/bin/env node
// 把落地页的图标墙（marqueeSvg.ts）求值成 6 份 SVG（3 行 × light/dark），
// 给 render-appstore-marketing.mjs 用。esbuild 解析方式同 dump-site-copy.cjs。
const path = require('path');
const fs = require('fs');
const { createRequire } = require('module');

function resolveEsbuild() {
  const siteReq = createRequire(path.join(__dirname, '../site/package.json'));
  try { return siteReq.resolve('esbuild'); } catch {}
  const astroReq = createRequire(siteReq.resolve('astro/package.json'));
  try { return astroReq.resolve('esbuild'); } catch {}
  return createRequire(astroReq.resolve('vite/package.json')).resolve('esbuild');
}

const { buildSync } = require(resolveEsbuild());

const outDir = process.argv[2];
if (!outDir) {
  console.error('usage: dump-marquee-svgs.cjs <out-dir>');
  process.exit(2);
}

const result = buildSync({
  entryPoints: [path.join(__dirname, '../site/src/marqueeSvg.ts')],
  bundle: true,
  format: 'cjs',
  platform: 'node',
  write: false,
  logLevel: 'silent',
});
const mod = { exports: {} };
new Function('module', 'exports', 'require', result.outputFiles[0].text)(mod, mod.exports, require);
const { marqueeRowSvg, marqueeRowCount, marqueeThemes } = mod.exports;

fs.mkdirSync(outDir, { recursive: true });
for (const theme of marqueeThemes) {
  for (let row = 0; row < marqueeRowCount; row += 1) {
    const file = path.join(outDir, `marquee-${theme}-${row}.svg`);
    fs.writeFileSync(file, marqueeRowSvg(theme, row));
    console.log(`wrote ${file}`);
  }
}
