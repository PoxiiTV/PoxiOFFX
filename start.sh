#!/bin/zsh
# Compila y abre PoxiOFFX (aparece en la barra de menús).
set -euo pipefail
cd "${0:A:h}"
./make-app.sh
open build/PoxiOFFX.app
