#!/bin/zsh
# Crea build/PoxiOFFX-X.Y.Z.dmg con la app y un acceso a Aplicaciones.
set -euo pipefail
cd "${0:A:h}"

./make-app.sh
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" build/PoxiOFFX.app/Contents/Info.plist)
DMG=build/PoxiOFFX-$VERSION.dmg
STAGE=build/dmg
rm -rf $STAGE $DMG
mkdir -p $STAGE
cp -R build/PoxiOFFX.app $STAGE/
ln -s /Applications $STAGE/Aplicaciones
hdiutil create -volname PoxiOFFX -srcfolder $STAGE -ov -format UDZO $DMG > /dev/null
rm -rf $STAGE
echo "Hecho: $DMG ($(du -h $DMG | cut -f1))"
