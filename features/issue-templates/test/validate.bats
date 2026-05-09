#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "issue-templates : les 3 fichiers attendus sont présents" {
    [ -f .github/ISSUE_TEMPLATE/bug_report.yml ]
    [ -f .github/ISSUE_TEMPLATE/question.yml ]
    [ -f .github/ISSUE_TEMPLATE/config.yml ]
}

@test "issue-templates : tous les fichiers parsent en YAML strict (idiomatique)" {
    for f in .github/ISSUE_TEMPLATE/bug_report.yml \
             .github/ISSUE_TEMPLATE/question.yml \
             .github/ISSUE_TEMPLATE/config.yml; do
        run python3 -c "import yaml; yaml.safe_load(open('$f'))"
        [ "$status" -eq 0 ] || { echo "YAML invalide : $f"; return 1; }
    done
}

@test "issue-templates : config.yml contient l'email interpolé du module" {
    grep -q "test-issue@example.org" .github/ISSUE_TEMPLATE/config.yml
}

@test "issue-templates : bug_report a une dropdown 'os' (schéma issue-form)" {
    grep -q "id: os" .github/ISSUE_TEMPLATE/bug_report.yml
}
