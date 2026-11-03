#!/bin/zsh
# Deja en deploy-hosting/ lo listo para publicar: la app y el .dmg.
set -euo pipefail
cd "${0:A:h}"
./make-dmg.sh
rm -rf deploy-hosting
mkdir -p deploy-hosting
cp -R build/PoxiOFFX.app build/PoxiOFFX-*.dmg deploy-hosting/
ls -lh deploy-hosting
