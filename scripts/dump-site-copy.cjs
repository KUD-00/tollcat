#!/usr/bin/env node
// 把站点 i18n 模块求值成 {zh, en, ja} 三棵 JSON，给 check-copy-freshness.py 用。
// 用 site 自带的 esbuild 打包（处理 TS 与无后缀 import），不装新依赖。
const path = require('path');
const { createRequire } = require('module');

// pnpm 布局下 esbuild 是 astro 的传递依赖，不在顶层：沿依赖链解析。
function resolveEsbuild() {
  const siteReq = createRequire(path.join(__dirname, '../site/package.json'));
  try { return siteReq.resolve('esbuild'); } catch {}
  const astroReq = createRequire(siteReq.resolve('astro/package.json'));
  try { return astroReq.resolve('esbuild'); } catch {}
  return createRequire(astroReq.resolve('vite/package.json')).resolve('esbuild');
}

const { buildSync } = require(resolveEsbuild());

const entry = process.argv[2];
if (!entry) {
  console.error('usage: dump-site-copy.cjs <i18n-module.ts>');
  process.exit(2);
}

const result = buildSync({
  entryPoints: [entry],
  bundle: true,
  format: 'cjs',
  platform: 'node',
  write: false,
  logLevel: 'silent',
});
const code = result.outputFiles[0].text;
const mod = { exports: {} };
new Function('module', 'exports', 'require', code)(mod, mod.exports, require);
const t = mod.exports.t;
if (typeof t !== 'function') {
  console.error('i18n 模块没有导出 t()');
  process.exit(2);
}
process.stdout.write(
  JSON.stringify({ zh: t('zh'), en: t('en'), ja: t('ja') })
);
