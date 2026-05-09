#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "codeowners : .github/CODEOWNERS présent" {
    [ -f .github/CODEOWNERS ]
}

@test "codeowners : règle * @<codeowner> avec interpolation correcte" {
    grep -qE '^\* @bobtest$' .github/CODEOWNERS
}

@test "codeowners : pas de placeholder Jinja résiduel" {
    ! grep -q "{{" .github/CODEOWNERS
    ! grep -q "}}" .github/CODEOWNERS
}
