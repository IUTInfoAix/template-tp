# template-tp — méta-template TP IUT Aix-Marseille

Méta-template **Copier + Jinja2** pour scaffolder des TP Java (avec ou sans
JavaFX) modulaires. Une seule source de vérité pour les modules R2.02
(JavaFX), R2.03 (Java pur), R5.10 et autres modules futurs.

## Usage rapide

```bash
copier copy --trust gh:IUTInfoAix/template-tp ../tp-mon-tp
```

Copier pose 3 questions (`module`, `tp`, `stack`), valide la composition via
`scripts/validate_deps.py`, et génère le TP. Les versions ultérieures du
méta-template peuvent être propagées dans le TP existant via :

```bash
cd ../tp-mon-tp
copier update
```

## Architecture

```
.copier-template/   templates Jinja2 (pom.xml.jinja, App.java.jinja, ...)
copier.yml          questions interactives + _exclude conditionnels + _tasks
features/<nom>/     feature.yml (metadata) + test/ (answers + Bats)
packs/<nom>/        pack.yml (metadata) + test/ (answers + Bats)
scripts/            validate_deps.py + outils méta
.github/workflows/  template-ci.yml (matrice feature isolée + composition)
```

Une **feature** est un comportement transversal (linter, devcontainer,
tuteur IA, autograding...). Un **pack** est une stack technique cohérente
(JavaFX). Chaque feature/pack a un `feature.yml`/`pack.yml` qui déclare
ses `requires` et `conflicts`, et un dossier `test/` avec :

- `answers.yml` : composition activant la feature pour la tester en
  isolation.
- `validate.bats` : tests **idiomatiques** (`./mvnw verify`, `pmd:check`,
  `xvfb-run mvnw verify` pour javafx, etc.) qui s'exécutent sur le TP
  fraîchement généré.
- `answers-disabled.yml` + `validate-disabled.bats` *(optionnels)* : tests
  de négation pour vérifier que la feature désactivée ne fuit aucun
  artefact dans le TP.

## Status (Étape A — bootstrap)

| Feature | metadata | test/answers | test/validate.bats | CI |
|---|---|---|---|---|
| lint-quality | ✅ | ✅ + disabled | ✅ + disabled (7+6 tests) | ✅ |
| devcontainer | 🔲 | 🔲 | 🔲 | 🔲 |
| vscode-config | 🔲 | 🔲 | 🔲 | 🔲 |
| ai-tutor | 🔲 | 🔲 | 🔲 | 🔲 |
| autograding-classroom | 🔲 | 🔲 | 🔲 | 🔲 |
| generate-student | 🔲 | 🔲 | 🔲 | 🔲 |
| pre-commit-spotless | 🔲 *(pom déjà conditionnel)* | 🔲 | 🔲 | 🔲 |
| maven-ci | 🔲 | 🔲 | 🔲 | 🔲 |
| dependabot | 🔲 | 🔲 | 🔲 | 🔲 |
| issue-templates | 🔲 | 🔲 | 🔲 | 🔲 |
| codeowners | 🔲 | 🔲 | 🔲 | 🔲 |

| Pack | metadata | test/answers | test/validate.bats | CI |
|---|---|---|---|---|
| javafx | 🔲 *(pom déjà conditionnel)* | 🔲 | 🔲 | 🔲 |

Plan complet : [`actuellement-le-template-tp-javafx-est-jazzy-naur.md`](https://github.com/IUTInfoAix/R203/blob/main/.claude-plans/) (privé).

## Développement local

```bash
# Tests d'une feature
rm -rf /tmp/tp-lint
copier copy --trust --defaults \
  --data-file features/lint-quality/test/answers.yml \
  . /tmp/tp-lint
TP_DIR=/tmp/tp-lint bats features/lint-quality/test/validate.bats

# Test négatif (feature désactivée)
rm -rf /tmp/tp-no-lint
copier copy --trust --defaults \
  --data-file features/lint-quality/test/answers-disabled.yml \
  . /tmp/tp-no-lint
TP_DIR=/tmp/tp-no-lint bats features/lint-quality/test/validate-disabled.bats
```

Prérequis : `pipx install copier`, `apt install bats`, JDK 25 (Zulu fx
recommandé pour rester compatible avec le pack javafx à venir).
