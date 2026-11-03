#!/bin/zsh
# Compila PoxiOFFX.app (Apple Silicon, firma ad-hoc) en build/.
set -euo pipefail
cd "${0:A:h}"

VERSION=1.0.0
APP=build/PoxiOFFX.app
rm -rf build
mkdir -p $APP/Contents/MacOS $APP/Contents/Resources build/icono.iconset

swift build -c release --arch arm64
cp "$(swift build -c release --arch arm64 --show-bin-path)/PoxiOFFX" $APP/Contents/MacOS/PoxiOFFX

swift scripts/make-icon.swift build/icono-1024.png
mkdir -p .assets && cp build/icono-1024.png .assets/icon.png
for s in 16 32 128 256 512; do
	sips -z $s $s build/icono-1024.png --out build/icono.iconset/icon_${s}x${s}.png > /dev/null
	sips -z $((s * 2)) $((s * 2)) build/icono-1024.png --out build/icono.iconset/icon_${s}x${s}@2x.png > /dev/null
done
iconutil -c icns build/icono.iconset -o $APP/Contents/Resources/AppIcon.icns

cat > $APP/Contents/Info.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>es</string>
	<key>CFBundleExecutable</key><string>PoxiOFFX</string>
	<key>CFBundleIconFile</key><string>AppIcon</string>
	<key>CFBundleIdentifier</key><string>dev.alexiis.poxioffx</string>
	<key>CFBundleName</key><string>PoxiOFFX</string>
	<key>CFBundlePackageType</key><string>APPL</string>
	<key>CFBundleShortVersionString</key><string>$VERSION</string>
	<key>CFBundleVersion</key><string>1</string>
	<key>LSMinimumSystemVersion</key><string>14.0</string>
	<key>LSUIElement</key><true/>
	<key>NSHighResolutionCapable</key><true/>
	<key>NSAppleEventsUsageDescription</key><string>PoxiOFFX pide tu contraseña una vez para poder mantener el Mac despierto con la tapa cerrada.</string>
</dict>
</plist>
EOF

codesign -s - --force $APP
echo "Hecho: $APP ($(du -sh $APP | cut -f1))"
