#!/bin/bash
# run.sh — gera o projeto, builda, instala e abre o AUREA Paciente no simulador, sem abrir o Xcode.
# Debug aponta para a API local (localhost:3333), com dado sintético (Comitê de Ética, opção A).
set -euo pipefail
cd "$(dirname "$0")"
SIMULADOR="${SIMULADOR:-iPhone 17 Pro}"
xcodegen generate --quiet
mkdir -p build && touch build/.metadata_never_index
xcrun simctl list devices booted | grep -q "$SIMULADOR" || xcrun simctl boot "$SIMULADOR"
xcodebuild -project AureaPaciente.xcodeproj -scheme AureaPaciente -configuration Debug \
  -destination "platform=iOS Simulator,name=$SIMULADOR" -derivedDataPath build build -quiet
xcrun simctl install "$SIMULADOR" build/Build/Products/Debug-iphonesimulator/AureaPaciente.app
xcrun simctl launch "$SIMULADOR" com.zenixcode.aurea.paciente
