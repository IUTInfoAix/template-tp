# template-tp

[![template-ci](https://github.com/IUTInfoAix/template-tp/actions/workflows/template-ci.yml/badge.svg?branch=main)](https://github.com/IUTInfoAix/template-tp/actions/workflows/template-ci.yml)
[![copier](https://img.shields.io/badge/scaffolding-Copier%209-3a8.svg)](https://copier.readthedocs.io/)
[![Java](https://img.shields.io/badge/Java-25-orange.svg)](https://www.azul.com/downloads/?package=jdk#zulu)
[![JUnit](https://img.shields.io/badge/JUnit-Jupiter%206-25A162.svg)](https://junit.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](.copier-template/LICENSE)

Méta-template **Copier + Jinja2 + Bats** pour scaffolder les TP Java (avec ou sans JavaFX) du Département Informatique de l'IUT d'Aix-Marseille. Une seule source de vérité pour les modules **R2.02** (JavaFX), **R2.03** (Java pur), et tous les modules futurs.

> **Remplace les anciens** [`IUTInfoAix-R202/template-tp-javafx`](https://github.com/IUTInfoAix-R202/template-tp-javafx) et [`IUTInfoAix-R203/template-tp-java`](https://github.com/IUTInfoAix-R203/template-tp-java) (archivés depuis 2026-05-10).

## Démarrage rapide

```bash
# Installer Copier (une seule fois)
pipx install copier

# Générer un TP
copier copy --trust gh:IUTInfoAix/template-tp ../tpN
```

Copier pose 3 questions interactives (`module`, `tp`, `stack`), valide la composition (`requires`/`conflicts`), et génère un TP prêt à pousser sous l'organisation Classroom.

## Configuration en 30 secondes

| Cas d'usage | `stack.features` | `stack.packs` |
|---|---|---|
| TP Java console autogradé (R2.03 standard) | défaut (10 features ON) | `[]` |
| TP Java + JavaFX (R2.02 standard) | défaut + `desktop-lite` via le pack | `[javafx]` |
| TP refactoring (caractérisation tests, --student-- markers) | défaut | `[]` + `stack.autograding_mode: refactoring` |
| TP non autogradé (TP1 R203 style, Git tutoré) | défaut **moins** `autograding-classroom`, `generate-student` | `[]` |
| TP barebone (juste un Maven + JUnit) | `[devcontainer, vscode-config, maven-ci]` | `[]` |

Pour ajouter une feature ou un pack à un TP existant : éditez `.copier-answers.yml` puis `copier update --skip-answered`. Le 3-way merge gère les conflits.

## Status — features et packs livrés

| Feature | Défaut | Inject pom | Tests bats |
|---|---:|---:|---:|
| [`devcontainer`](features/devcontainer/) | ✅ | – | 6 + 1 |
| [`vscode-config`](features/vscode-config/) | ✅ | – | 7 + 1 |
| [`ai-tutor`](features/ai-tutor/) | ✅ | – | 9 + 2 |
| [`autograding-classroom`](features/autograding-classroom/) | ✅ | – | 12 + 3 |
| [`generate-student`](features/generate-student/) | ✅ | – | 6 + 2 |
| [`lint-quality`](features/lint-quality/) | ✅ | maven-pmd-plugin | 7 + 6 |
| [`pre-commit-spotless`](features/pre-commit-spotless/) | ✅ | spotless + git-build-hook | 7 + 3 + 4 (composition) |
| [`maven-ci`](features/maven-ci/) | ✅ | – | 8 + 1 |
| [`dependabot`](features/dependabot/) | ✅ | – | 5 + 1 |
| [`issue-templates`](features/issue-templates/) | ✅ | – | 4 + 1 |
| [`codeowners`](features/codeowners/) | ⬜ | – | 3 + 1 |

| Pack | Défaut | Inject pom | Tests bats |
|---|---:|---:|---:|
| [`javafx`](packs/javafx/) | ⬜ | 4 deps JavaFX + 2 TestFX + javafx-maven-plugin | 12 + 9 |

**Total** : 14 jobs CI verts, ≈ 100 assertions bats idiomatiques (vraies commandes Maven, pas de form check).

## Documentation

- [**TEMPLATE.md**](TEMPLATE.md) — manuel d'usage détaillé : `copier copy/update`, recettes par module, format `.copier-answers.yml`, FAQ migration depuis les anciens templates.
- [**CONTRIBUTING.md**](CONTRIBUTING.md) — guide pour ajouter une nouvelle feature ou un nouveau pack (squelette de fichiers, conventions de tests bats idiomatiques, intégration CI).
- [**copier.yml**](copier.yml) — questions interactives + `_exclude` conditionnels + hook `_tasks` de validation.

## Architecture

```
template-tp/
├── .copier-template/        templates Jinja2 (pom.xml.jinja, App.java.jinja, ...)
├── copier.yml               questions + _exclude conditionnels + _tasks
├── features/<nom>/          feature.yml (metadata) + test/ (answers + bats)
├── packs/<nom>/             pack.yml (metadata) + test/ (answers + bats)
├── scripts/
│   └── validate_deps.py     hook _tasks : valide requires/conflicts
└── .github/workflows/
    └── template-ci.yml      matrice : meta-checks + feature isolée + pack isolé + composition
```

Une **feature** = comportement transversal modulaire (linter, devcontainer, tuteur IA, autograding...).
Un **pack** = stack technique cohérente (`javafx` pour l'instant ; futurs : `jpa`, `web-spring-boot`...).

## Prérequis

- **Copier 9+** (`pipx install copier`)
- **Bats** pour lancer les tests en local (`apt install bats`)
- **JDK 25** (Zulu recommandé via SDKMAN, `25-zulu-fx` si vous touchez au pack `javafx`)
- **xvfb** côté Linux/CI pour les tests TestFX du pack `javafx` (`apt install xvfb`)

## Licence

[MIT](.copier-template/LICENSE) — IUT d'Aix-Marseille - Département Informatique.
