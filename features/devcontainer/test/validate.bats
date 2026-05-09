#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

parse_jsonc() {
    python3 -c "
import re, json, sys
src = open('$1').read()
src = re.sub(r'//.*?\n', '\n', src)
src = re.sub(r'/\*.*?\*/', '', src, flags=re.DOTALL)
json.loads(src)
"
}

@test "devcontainer : .devcontainer/devcontainer.json présent" {
    [ -f .devcontainer/devcontainer.json ]
}

@test "devcontainer : JSONC valide (parsing strict après strip commentaires)" {
    parse_jsonc .devcontainer/devcontainer.json
}

@test "devcontainer : 'name' interpolé avec module.code" {
    grep -q '"name": "R2.99 Development Environment"' .devcontainer/devcontainer.json
}

@test "devcontainer : feature java avec la bonne version (zulu non-fx en l'absence du pack javafx)" {
    grep -q '"version": "25-zulu"' .devcontainer/devcontainer.json
    ! grep -q '25-zulu-fx' .devcontainer/devcontainer.json
}

@test "devcontainer : pas de Dockerfile ni de desktop-lite (pack javafx absent)" {
    ! grep -q '"build"' .devcontainer/devcontainer.json
    ! grep -q 'desktop-lite' .devcontainer/devcontainer.json
}

@test "devcontainer : pas de placeholder Jinja résiduel" {
    ! grep -q "{{" .devcontainer/devcontainer.json
}
