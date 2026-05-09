#!/usr/bin/env bats
# Tests Bats : feature dependabot ACTIVÉE.

setup() { cd "$TP_DIR"; }

@test "dependabot : .github/dependabot.yml présent" {
    [ -f .github/dependabot.yml ]
}

@test "dependabot : YAML valide (idiomatique : parser strict)" {
    run python3 -c "import sys, yaml; yaml.safe_load(open('.github/dependabot.yml'))"
    [ "$status" -eq 0 ]
}

@test "dependabot : version 2 (schéma actuel)" {
    grep -q "^version: 2" .github/dependabot.yml
}

@test "dependabot : ecosystem maven présent" {
    grep -q 'package-ecosystem: "maven"' .github/dependabot.yml
}

@test "dependabot : ecosystem github-actions présent" {
    grep -q 'package-ecosystem: "github-actions"' .github/dependabot.yml
}
