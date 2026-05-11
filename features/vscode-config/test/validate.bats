#!/usr/bin/env bats
# settings.json + tasks.json + launch.json sont du JSONC (commentaires
# autorisés). On les valide via Python en strippant d'abord les // et /* */
# pour pouvoir utiliser json.loads (idiomatique JSONC).

setup() { cd "$TP_DIR"; }

# Helper : strip JSONC comments puis json.loads. Echoue si le contenu n'est
# pas du JSON valide après strip.
parse_jsonc() {
    python3 -c "
import re, json, sys
src = open('$1').read()
# strip // line comments + /* block */ (simple, fonctionne pour ces fichiers)
src = re.sub(r'//.*?\n', '\n', src)
src = re.sub(r'/\*.*?\*/', '', src, flags=re.DOTALL)
json.loads(src)
"
}

@test "vscode-config : les 4 fichiers attendus sont présents" {
    [ -f .vscode/settings.json ]
    [ -f .vscode/launch.json ]
    [ -f .vscode/tasks.json ]
    [ -f .vscode/extensions.json ]
}

@test "vscode-config : settings.json est du JSONC valide (parsing strict)" {
    parse_jsonc .vscode/settings.json
}

@test "vscode-config : launch.json est du JSONC valide" {
    parse_jsonc .vscode/launch.json
}

@test "vscode-config : tasks.json est du JSONC valide" {
    parse_jsonc .vscode/tasks.json
}

@test "vscode-config : extensions.json est du JSON valide (pas de commentaires)" {
    run python3 -c "import json; json.load(open('.vscode/extensions.json'))"
    [ "$status" -eq 0 ]
}

@test "vscode-config sans javafx : launch.json référence la mainClass console (pas le format module)" {
    grep -Fq '"mainClass": "fr.univ_amu.iut.App"' .vscode/launch.json
    # Sans pack javafx, pas de '/' dans mainClass et pas de vmArgs.
    ! grep -Fq -- '"vmArgs"' .vscode/launch.json
    ! grep -Fq '/fr.univ_amu.iut.App' .vscode/launch.json
}

@test "vscode-config sans javafx : tasks.json contient une task 'Lancer l'application' (pas javafx:run)" {
    grep -Fq '"label": "Lancer l'"'"'application (via Maven)"' .vscode/tasks.json
    grep -Fq '"command": "./mvnw compile exec:java"' .vscode/tasks.json
    ! grep -Fq -- "javafx:run" .vscode/tasks.json
}

@test "vscode-config : tasks.json contient au moins une task de Build" {
    grep -Fq '"label": "Build complet"' .vscode/tasks.json
}
