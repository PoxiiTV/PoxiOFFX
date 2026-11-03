#!/bin/zsh
# Regenera las imágenes del README en .assets/: icono, capturas redondeadas y banner.
# Necesita la app compilada (./make-app.sh).
set -euo pipefail
cd "${0:A:h}/.."
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

swift scripts/make-icon.swift .assets/icon.png
build/PoxiOFFX.app/Contents/MacOS/PoxiOFFX --snapshot "$work"
for f in protegido dos-pantallas normal permiso; do
	swift scripts/make-shot.swift "$work/$f.png" ".assets/$f.png"
done
swiftc -O -parse-as-library -o "$work/make-banner" scripts/make-banner.swift
"$work/make-banner" .assets/icon.png "$work/protegido.png" "$work/normal.png" .assets/banner.png
ls -lh .assets
