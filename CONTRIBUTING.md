# CONTRIBUTING.md — ajouter une feature ou un pack

Ce guide cible **les enseignant·es / mainteneur·euses du méta-template** qui veulent étendre ses capacités. Pour générer ou maintenir un TP, voir [TEMPLATE.md](TEMPLATE.md).

---

## Sommaire

- [Anatomie d'une feature ou d'un pack](#anatomie-dune-feature-ou-dun-pack)
- [Ajouter une feature pas à pas](#ajouter-une-feature-pas-à-pas)
- [Ajouter un pack pas à pas](#ajouter-un-pack-pas-à-pas)
- [Conventions de tests bats idiomatiques](#conventions-de-tests-bats-idiomatiques)
- [Intégrer dans la CI](#intégrer-dans-la-ci)
- [Workflow de PR](#workflow-de-pr)
- [Décisions architecturales à respecter](#décisions-architecturales-à-respecter)

---

## Anatomie d'une feature ou d'un pack

```
features/<nom>/
├── feature.yml                          # metadata (description, requires, conflicts, default)
└── test/
    ├── answers.yml                      # composition pour tester la feature ACTIVÉE en isolation
    ├── answers-disabled.yml             # composition pour tester la feature DÉSACTIVÉE
    ├── answers-with-<autre>.yml         # (opt) composition pour tester l'interaction avec une autre feature
    ├── validate.bats                    # tests bats sur le TP avec feature ACTIVÉE
    ├── validate-disabled.bats           # tests bats sur le TP avec feature DÉSACTIVÉE
    └── validate-with-<autre>.bats       # (opt) tests sur le TP avec composition

packs/<nom>/                             # même structure que features/, mais pack.yml
```

Une **feature** est une couche transversale (linter, devcontainer, autograding, AI tutor...). Activable sur n'importe quel TP, indépendamment de la stack langage.

Un **pack** est une stack technique cohérente (`javafx`, futurs `jpa`, `web-spring-boot`...). Modifie le pom et l'app principale.

### `feature.yml` / `pack.yml`

```yaml
name: ma-feature
type: feature   # ou: pack
description: |
  Une à trois lignes en français qui décrivent ce que la feature fait,
  ce qu'elle injecte (fichiers + blocs pom), et son intention pédagogique
  ou opérationnelle. Lue par scripts/validate_deps.py et par les futurs
  tableaux de bord.
default: true   # true = activée par défaut dans copier.yml ; false = opt-in
requires: []    # liste de noms de features/packs requis (validé par validate_deps.py)
conflicts: []   # idem mais incompatibles
files:
  - .github/workflows/ma-feature.yml
  - scripts/ma-feature.sh
pom_inject:    # facultatif, descriptif (pour humain)
  - "plugin: ma-feature-plugin (phase verify)"
```

`requires`/`conflicts` sont validés par `scripts/validate_deps.py` lors de chaque `copier copy/update`. Voir leur exemple dans [packs/javafx/pack.yml](packs/javafx/pack.yml).

---

## Ajouter une feature pas à pas

Exemple : ajouter une feature fictive `foo-bar` qui pose un fichier `.config/foo.conf`.

### 1. Poser les fichiers raw ou Jinja dans `.copier-template/`

```bash
mkdir -p .copier-template/.config
cat > .copier-template/.config/foo.conf <<EOF
# Config statique de Foo
mode: simple
EOF
```

Si vous avez besoin d'interpoler une variable Copier (ex `{{ module.code }}`), nommez le fichier avec le suffixe `.jinja` :

```bash
cat > .copier-template/.config/foo.conf.jinja <<EOF
# Config Foo pour {{ module.code }}
codeowner: {{ module.codeowner }}
EOF
```

Les `.jinja` sont rendus à la génération ; le suffixe disparaît.

### 2. Ajouter les `_exclude` conditionnels dans `copier.yml`

```yaml
# copier.yml
_exclude:
  ...
  # foo-bar
  - "{% if 'foo-bar' not in stack.features %}.config/foo.conf{% endif %}"
```

Pour exclure un dossier **entier**, deux entrées :

```yaml
  - "{% if 'foo-bar' not in stack.features %}.config{% endif %}"
  - "{% if 'foo-bar' not in stack.features %}.config/**{% endif %}"
```

### 3. Si la feature touche `pom.xml` : éditer `pom.xml.jinja`

```jinja
{%- if "foo-bar" in stack.features %}
            <plugin>
                <groupId>com.example</groupId>
                <artifactId>foo-bar-maven-plugin</artifactId>
                <version>1.0.0</version>
            </plugin>
{%- endif %}
```

Ajouter aussi la `<property>` `<foo.bar.plugin.version>` dans le bloc `<properties>`.

### 4. Créer `feature.yml`

```bash
mkdir -p features/foo-bar
cat > features/foo-bar/feature.yml <<EOF
name: foo-bar
type: feature
description: |
  Configuration Foo pour le module. Pose .config/foo.conf et injecte
  foo-bar-maven-plugin dans le pom.
default: false
requires: []
conflicts: []
files:
  - .config/foo.conf
pom_inject:
  - "plugin: foo-bar-maven-plugin"
EOF
```

### 5. Créer `test/answers.yml` et `test/answers-disabled.yml`

Copier-coller depuis une feature existante (ex : [features/dependabot/test/answers.yml](features/dependabot/test/answers.yml)) et modifier `stack.features` pour activer **uniquement** votre feature dans `answers.yml`, et **rien** dans `answers-disabled.yml`.

### 6. Écrire `test/validate.bats` (idiomatique, pas du form check)

```bash
#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "foo-bar : .config/foo.conf présent" {
    [ -f .config/foo.conf ]
}

@test "foo-bar : config valide selon foo-cli (idiomatique)" {
    # IDIOMATIC : on lance vraiment le binaire foo-cli sur le fichier
    # généré, pas une vérif de forme regex.
    run foo-cli validate .config/foo.conf
    [ "$status" -eq 0 ]
}

@test "foo-bar : pom.xml contient le plugin foo-bar-maven-plugin" {
    grep -q "foo-bar-maven-plugin" pom.xml
}
```

Et `test/validate-disabled.bats` :

```bash
#!/usr/bin/env bats
setup() { cd "$TP_DIR"; }

@test "no-foo-bar : .config/foo.conf absent" {
    [ ! -f .config/foo.conf ]
}

@test "no-foo-bar : pom.xml ne contient PAS foo-bar-maven-plugin" {
    ! grep -q "foo-bar-maven-plugin" pom.xml
}
```

### 7. Tester en local

```bash
rm -rf /tmp/tp-foo
copier copy --trust --defaults --data-file features/foo-bar/test/answers.yml . /tmp/tp-foo
TP_DIR=/tmp/tp-foo bats features/foo-bar/test/validate.bats

rm -rf /tmp/tp-no-foo
copier copy --trust --defaults --data-file features/foo-bar/test/answers-disabled.yml . /tmp/tp-no-foo
TP_DIR=/tmp/tp-no-foo bats features/foo-bar/test/validate-disabled.bats
```

### 8. Ajouter à la matrice CI

Éditer [`.github/workflows/template-ci.yml`](.github/workflows/template-ci.yml), ajouter `foo-bar` à `matrix.feature` :

```yaml
        feature:
          ...
          - foo-bar
```

### 9. Mettre à jour `copier.yml` si default ON

Si la feature est `default: true`, l'ajouter dans `stack.features` du défaut :

```yaml
stack:
  type: yaml
  default:
    features:
      - ...
      - foo-bar     # nouvelle entrée
```

### 10. Mettre à jour le tableau Status du README

Section *Status — features et packs livrés* du [README.md](README.md).

---

## Ajouter un pack pas à pas

Pratiquement identique à une feature, mais :

- `packs/<nom>/pack.yml` au lieu de `features/<nom>/feature.yml`,
- `type: pack`,
- généralement `requires: [devcontainer]` (les packs touchent souvent à l'environnement Codespace),
- les modifs `pom.xml.jinja` sont plus lourdes (deps + plugin),
- ajout dans la matrice CI sous `test-pack-isolated` (pas `test-feature-isolated`),
- éventuellement un step `apt install xvfb` ou autre dans la CI si le test idiomatique l'exige.

Voir [packs/javafx/](packs/javafx/) comme référence complète.

---

## Conventions de tests bats idiomatiques

> **Règle d'or** : les tests doivent valider que **le TP généré fonctionne**, pas seulement qu'il a la forme attendue.

✅ **Bons tests (idiomatiques)** :
```bash
@test "lint-quality : ./mvnw -Pquality-gate verify passe (failOnViolation=true)" {
    run ./mvnw -B -q -ntp -Pquality-gate verify
    [ "$status" -eq 0 ]
}

@test "javafx : xvfb-run ./mvnw verify passe (TestFX réellement exécuté)" {
    run xvfb-run --auto-servernum ./mvnw -B -q -ntp verify
    [ "$status" -eq 0 ]
}

@test "autograding : grade-test.sh sur méthode existante (mvnw test puis grade)" {
    ./mvnw -B -q -ntp test
    run ./scripts/grade-test.sh fr.univ_amu.iut.AppTest le_menu_affiche_le_titre_du_TP_et_le_repere_IUT
    [ "$status" -eq 0 ]
}
```

❌ **Tests faibles (form check)** :
```bash
@test "lint-quality : pmd-ruleset.xml contient 'Long Method'" {
    grep -q "LongMethod" pmd-ruleset.xml   # ne dit RIEN sur le fait que PMD marche
}
```

Form check OK **en complément** d'un test idiomatique, jamais à la place.

### Tests négatifs (`validate-disabled.bats`)

Toujours fournir un `validate-disabled.bats` qui teste que **rien ne fuit** quand la feature est désactivée :

```bash
@test "no-X : artefact1 absent" { [ ! -f artefact1 ]; }
@test "no-X : artefact2 absent" { [ ! -f artefact2 ]; }
@test "no-X : pom.xml ne contient PAS le plugin X" { ! grep -q "X-plugin" pom.xml; }
@test "no-X : ./mvnw test passe sans X (régression)" { run ./mvnw -q test; [ "$status" -eq 0 ]; }
```

Sans tests négatifs, on ne sait pas si le `_exclude` ou le `{% if %}` Jinja fait son travail.

### Tests de composition (optionnel)

Si votre feature interagit avec une autre (ex `pre-commit-spotless` injecte un bloc TEACHER-LINT quand `lint-quality` est aussi actif), ajouter `test/answers-with-<autre>.yml` + `test/validate-with-<autre>.bats`, et un job dédié dans la CI (cf. `composition / pre-commit-spotless + lint-quality`).

---

## Intégrer dans la CI

[`.github/workflows/template-ci.yml`](.github/workflows/template-ci.yml) a 4 jobs :

| Job | Quand |
|---|---|
| `meta-checks` | Toujours. Vérifie la sync `TDD-PLAYBOOK` entre `AGENTS.md.jinja` et `copilot-instructions.md.jinja` (avant génération). |
| `test-feature-isolated` | Matrice sur `features` listées. Génère un TP avec la feature ACTIVÉE puis DÉSACTIVÉE, lance bats. |
| `test-pack-isolated` | Idem pour `packs`. Installe `xvfb` en plus pour les packs UI. |
| `test-composition-...` | Job dédié par interaction critique. Aujourd'hui : `pre-commit-spotless + lint-quality`. |

Pour ajouter une feature : étendre la liste `matrix.feature`. Pour ajouter une composition critique : copier le job `test-composition-spotless-with-lint` et adapter les fixtures.

---

## Workflow de PR

1. **Une PR = une feature ou un pack** (ou un fix isolé). Ne mélangez pas plusieurs features dans la même PR.
2. **Brancher sur `main`** : `git checkout -b feat/ma-feature`.
3. **Tester en local** avant push (`copier copy ... && bats ...`). Si vous touchez `App.java.jinja`, tester aussi le pack `javafx` (qui partage le même fichier en `{%- if/else -%}`).
4. **Push + PR** : `gh pr create --title "feat(ma-feature): ..."`.
5. **CI verte = mergeable**. Si la CI échoue, lire les logs (`gh run view --log-failed`). Bug souvent dans le `_exclude` (oubli du glob `/**`) ou la syntaxe Jinja (`{%- -%}`).
6. **Squash merge + delete branch** : `gh pr merge N --squash --delete-branch`. Garde l'historique de `main` lisible.
7. **Mettre à jour le tableau Status** du README dans le commit (le réflexe).

> **Push direct sur `main` est bloqué** par l'auto-mode classifier de Claude Code et par la convention. Toujours passer par PR.

---

## Décisions architecturales à respecter

### Pas de marqueurs custom dans les templates

Tout est `{% if %}` Jinja2. Pas de `// @@@FEATURE-X-BEGIN@@@`/`@@@END@@@` parsés par sed/python (sauf pour le bloc `AUTOGRADING-*` qui est régénéré dynamiquement par `update-autograding.sh`, pas par Copier).

### Conditionnels intra-fichier vs `_exclude` global

- **Intra-fichier (`{% if %}` dans `.jinja`)** : pour ajouter quelques lignes dans un fichier qui existe toujours (ex : un plugin dans `pom.xml.jinja`).
- **`_exclude` dans `copier.yml`** : pour inclure ou exclure un fichier ou un dossier entier.

Ne pas mélanger : si une feature pose 3 fichiers + injecte 2 blocs pom, mettre les 3 fichiers en `_exclude` et les 2 blocs en `{% if %}` dans `pom.xml.jinja`.

### Tests idiomatiques obligatoires

Voir section dédiée. Si l'idiomatique est **vraiment trop lourd** pour la CI (ex : `devcontainer build` qui prend 5 min), justifier dans la description du test bats et fournir au minimum un `validate-disabled.bats` solide.

### Pas de personnalisation hardcodée R203

Le méta-template a vocation à servir tous les modules. Toute mention `IUTInfoAix-R203`, `R2.03`, `nedseb` doit être interpolée via `module.*`. Une seule exception explicite : `IUTInfoAix-R203/classroom-sync` dans `generate-student.yml` (ce repo est multi-module et héberge la config R202+R203).

### Garde-fous CI à 2 niveaux

Quand un invariant doit absolument tenir (ex : sync TDD-PLAYBOOK entre AGENTS.md et copilot-instructions.md), créer un job `meta-checks` qui valide **sur la source `.jinja`** ET un test bats qui valide **sur le TP généré**. Le doublon est volontaire : le premier attrape tôt, le second garantit l'idiomatique.

### Le pom.xml généré dans le TP est PROPRE

Aucun conditionnel résiduel, aucun marqueur custom, aucun commentaire `<!-- généré par Copier -->`. C'est du XML Maven valide qu'un étudiant peut éditer à la main sans rien casser. Cette propriété justifie le coût de Jinja2 par rapport à des marqueurs custom.

---

## Pour aller plus loin

- Plan original (privé) : [`/home/nedjar/.claude/plans/actuellement-le-template-tp-javafx-est-jazzy-naur.md`](file:///home/nedjar/.claude/plans/actuellement-le-template-tp-javafx-est-jazzy-naur.md)
- Documentation Copier : <https://copier.readthedocs.io/>
- Documentation Bats : <https://bats-core.readthedocs.io/>
- Templates Jinja2 : <https://jinja.palletsprojects.com/>
