#!/bin/zsh
# Tests de la lógica. Se pasa la ruta del plugin de Testing porque con solo
# Command Line Tools `swift test` a veces no lo encuentra.
set -euo pipefail
cd "${0:A:h}"
swift test -Xswiftc -plugin-path -Xswiftc "$(xcode-select -p)/usr/lib/swift/host/plugins/testing"
