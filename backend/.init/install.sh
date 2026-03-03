#!/usr/bin/env bash
set -euo pipefail
# dependencies - deterministic install and bundler determination
WORKSPACE="/home/saqiba/Desktop/test_rle/workspace/code-generation/react-todo-list-237620-237634/backend"
cd "$WORKSPACE"
[ -f package.json ] || { echo "package.json missing" >&2; exit 20; }
BUNDLER=${BUNDLER:-}
if [ -z "$BUNDLER" ]; then
  if node -e "const p=require('./package.json'); process.exit((p.devDependencies&&p.devDependencies.vite)||(p.dependencies&&p.dependencies.vite)?0:1)" 2>/dev/null; then BUNDLER=vite; elif node -e "const p=require('./package.json'); process.exit((p.devDependencies&&p.devDependencies['react-scripts'])||(p.dependencies&&p.dependencies['react-scripts'])?0:1)" 2>/dev/null; then BUNDLER=cra; else BUNDLER=cra; fi
REQ_DEPS=(react react-dom)
REQ_DEVS=(jest serve)
if [ "$BUNDLER" = "vite" ]; then REQ_DEVS+=(vite); else REQ_DEVS+=(react-scripts); fi
missing_deps=()
missing_devs=()
for p in "${REQ_DEPS[@]}"; do
  if ! node -e "const pj=require('./package.json'); if((pj.dependencies&&pj.dependencies['$p'])||(pj.devDependencies&&pj.devDependencies['$p'])) process.exit(0); else process.exit(1)" 2>/dev/null; then missing_deps+=("$p"); fi
done
for p in "${REQ_DEVS[@]}"; do
  if ! node -e "const pj=require('./package.json'); if((pj.dependencies&&pj.dependencies['$p'])||(pj.devDependencies&&pj.devDependencies['$p'])) process.exit(0); else process.exit(1)" 2>/dev/null; then missing_devs+=("$p"); fi
done
if [ ${#missing_deps[@]} -gt 0 ] || [ ${#missing_devs[@]} -gt 0 ]; then
  # prepare environment variables for node editor
  export ADD_DEPS="$(node -e 'console.log(JSON.stringify(process.argv.slice(1)))' ${missing_deps[@]:-} )" || export ADD_DEPS='[]'
  export ADD_DEVS="$(node -e 'console.log(JSON.stringify(process.argv.slice(1)))' ${missing_devs[@]:-} )" || export ADD_DEVS='[]'
  # single edit to package.json to add missing deps/devDeps using latest semver placeholder
  node - <<'NODE'
const fs=require('fs'); const p=JSON.parse(fs.readFileSync('package.json'));
p.dependencies=p.dependencies||{}; p.devDependencies=p.devDependencies||{};
const addDeps=JSON.parse(process.env.ADD_DEPS||'[]'); const addDev=JSON.parse(process.env.ADD_DEVS||'[]');
addDeps.forEach(d=>{ if(d && !p.dependencies[d] && !(p.devDependencies&&p.devDependencies[d])) p.dependencies[d]='latest' });
addDev.forEach(d=>{ if(d && !p.devDependencies[d] && !(p.dependencies&&p.dependencies[d])) p.devDependencies[d]='latest' });
fs.writeFileSync('package.json', JSON.stringify(p,null,2));
NODE
fi
# choose install method: prefer npm ci when lockfile exists and package.json not modified in last 5 minutes
if [ -f package-lock.json ] && [ "$(stat -c %Y package.json)" -lt "$(($(date +%s)-300))" ]; then
  npm ci --no-audit --no-fund --silent || { echo "npm ci failed" >&2; exit 21; }
else
  npm install --no-audit --no-fund --silent || { echo "npm install failed" >&2; exit 22; }
fi
[ -d node_modules ] || { echo "node_modules missing after install" >&2; exit 23; }
# persist chosen bundler
printf "%s" "$BUNDLER" > .bundle-type
# normalize scripts if placeholders present
node -e "const fs=require('fs');const p=JSON.parse(fs.readFileSync('package.json'));p.scripts=p.scripts||{}; if(p.scripts.start&&p.scripts.start.includes('dev-start.js')) p.scripts.start=(fs.existsSync('node_modules/.bin/vite')||fs.existsSync('node_modules/vite'))? 'vite' : 'react-scripts start'; if(p.scripts.build&&p.scripts.build.includes('build-placeholder.js')) p.scripts.build=(fs.existsSync('node_modules/.bin/vite')||fs.existsSync('node_modules/vite'))? 'vite build' : 'react-scripts build'; if(!p.scripts.test) p.scripts.test='jest --colors'; fs.writeFileSync('package.json',JSON.stringify(p,null,2));"
