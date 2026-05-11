# TEMPLATE.md — manuel d'usage du méta-template

Ce manuel cible **les enseignant·es** qui génèrent ou maintiennent des TP avec ce méta-template. Pour ajouter une feature ou un pack au méta-template, voir [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Sommaire

- [Installation](#installation)
- [Générer un nouveau TP](#générer-un-nouveau-tp)
- [Recettes de composition par module](#recettes-de-composition-par-module)
- [Mettre à jour un TP existant (`copier update`)](#mettre-à-jour-un-tp-existant-copier-update)
- [Ajouter une feature ou un pack à un TP existant](#ajouter-une-feature-ou-un-pack-à-un-tp-existant)
- [Format `.copier-answers.yml`](#format-copier-answersyml)
- [Tests en local](#tests-en-local)
- [FAQ migration depuis `template-tp-java` / `template-tp-javafx`](#faq-migration)
- [Pièges connus](#pièges-connus)

---

## Installation

```bash
pipx install copier            # scaffolding
sudo apt install bats          # tests en local (optionnel)
sudo apt install xvfb          # uniquement si pack javafx
```

Vérifications :

```bash
copier --version    # ≥ 9.0.0
bats --version      # ≥ 1.10
java -version       # 25 (Zulu fx si javafx envisagé)
```

---

## Générer un nouveau TP

### Mode interactif

```bash
copier copy --trust gh:IUTInfoAix/template-tp ../tpN
```

Copier pose 3 questions :

1. `module` (YAML inline) — identifiant du module pédagogique :
   ```yaml
   {code: "R2.03", titre: "Qualité de développement",
    org_github: "IUTInfoAix-R203",
    classroom_org: "IUTInfoAix-R203-2026",
    codeowner: "@nedseb",
    contact_email: "sebastien.nedjar@univ-amu.fr"}
   ```

2. `tp` (YAML inline) — métadonnées du TP :
   ```yaml
   {numero: 2, titre_court: "tp2",
    titre_complet: "TP2 TDD",
    description: "Test-Driven Development : 6 exercices baby steps",
    classroom_link: "https://classroom.github.com/a/abcDEF12"}
   ```

3. `stack` (YAML inline) — composition technique :
   ```yaml
   {java_version: 25,
    features: [devcontainer, vscode-config, ai-tutor, autograding-classroom,
               generate-student, lint-quality, pre-commit-spotless, maven-ci,
               dependabot, issue-templates],
    packs: [],
    autograding_mode: tdd}
   ```

`--trust` est requis car le méta-template exécute `_tasks` (script Python `validate_deps.py`).

### Mode non interactif (CI / batch)

```bash
copier copy --trust --defaults --data-file mes-answers.yml gh:IUTInfoAix/template-tp ../tpN
```

Le fichier `mes-answers.yml` reproduit le format des 3 questions (`module:`, `tp:`, `stack:`). Voir les fixtures dans `features/<nom>/test/answers.yml` pour des exemples.

---

## Recettes de composition par module

### TP Java console autogradé (R2.03 standard)

C'est la composition par défaut : aucun pack, toutes les features ON sauf `codeowners`.

```yaml
stack:
  java_version: 25
  features: [devcontainer, vscode-config, ai-tutor, autograding-classroom,
             generate-student, lint-quality, pre-commit-spotless, maven-ci,
             dependabot, issue-templates]
  packs: []
  autograding_mode: tdd
```

### TP Java + JavaFX (R2.02 standard)

Comme le standard, mais avec `packs: [javafx]`. Le pack injecte 4 deps JavaFX + 2 deps TestFX, le `javafx-maven-plugin`, le `Dockerfile` xvfb du devcontainer, la feature `desktop-lite`, le suffixe `-fx` au JDK Zulu, et bascule `App.java`/`AppTest.java` sur la version JavaFX (Stage + Scene + TestFX).

```yaml
stack:
  java_version: 25
  features: [devcontainer, vscode-config, ai-tutor, autograding-classroom,
             generate-student, lint-quality, pre-commit-spotless, maven-ci,
             dependabot, issue-templates]
  packs: [javafx]
  autograding_mode: tdd
```

`pack javafx` requiert `devcontainer` (sinon xvfb manquant en Codespaces). `validate_deps.py` rejette la composition si vous l'oubliez.

### TP refactoring (TP4 R203 style)

Comme le standard, mais en mode `refactoring` pour `update-autograding.sh` (répartition 10/10/80 entre compilation, caractérisation tests, et tests étudiants — au lieu du 10/90 du mode `tdd`).

```yaml
stack:
  features: [...défaut...]
  packs: []
  autograding_mode: refactoring
```

### TP non autogradé (TP1 R203 Git tutoré)

Pas d'autograding ni de pipeline solution → main, mais on garde le tuteur IA (`ai-tutor`) et l'infra (`devcontainer`, `vscode-config`, `maven-ci`, `pre-commit-spotless`, `dependabot`, `issue-templates`).

```yaml
stack:
  features: [devcontainer, vscode-config, ai-tutor, lint-quality,
             pre-commit-spotless, maven-ci, dependabot, issue-templates]
  packs: []
  autograding_mode: tdd
```

### TP barebone (Maven + JUnit, rien d'autre)

```yaml
stack:
  features: [devcontainer, vscode-config, maven-ci]
  packs: []
  autograding_mode: tdd
```

Garde un environnement Codespace + tasks VS Code + CI minimale. Aucun autograding, aucun linter, aucun tuteur IA.

---

## Mettre à jour un TP existant (`copier update`)

Quand le méta-template évolue (nouvelle feature, fix d'infra, mise à jour de version Java...), propager dans un TP existant :

```bash
cd ../tpN
copier update                        # interactif, 3-way merge sur conflits
copier update --skip-answered        # sans re-poser les 3 questions
copier update --conflict skip        # garde la version locale en cas de conflit
copier update --conflict inline      # marque les conflits dans le fichier (style git)
```

Copier conserve trois versions pour le merge :
1. la version d'origine du TP (commit baked dans `.copier-answers.yml`),
2. la version actuelle du TP (vos modifs locales),
3. la version actuelle du méta-template.

Le merge produit la version finale et signale les conflits dans les fichiers (style `<<<<<<< HEAD` / `>>>>>>> upstream`).

> **Toujours commiter le TP avant `copier update`**. Le merge peut écrire des fichiers sans demander, et `git diff` est votre seule sécurité.

### Stratégie infra vs contenu pédagogique

`copier.yml` déclare une liste `_skip_if_exists` qui distingue **fichiers d'infra** (toujours mis à jour) et **fichiers de contenu pédagogique** (générés à la création initiale, jamais écrasés ensuite). Conséquence : les `copier update` ne génèrent presque jamais de conflits 3-way merge sur le contenu — l'enseignant·e garde la maîtrise totale de ses énoncés.

🛡️ **Préservés** (`_skip_if_exists`) :
- `README.md` (objectifs Bloom, prérequis, sections exercices)
- `src/main/java/.../exerciceN/**`, `src/test/java/.../exerciceN/**`, `src/main/java/.../bonusN/**`, `src/test/java/.../bonusN/**`
- `src/main/resources/exerciceN/**`, `src/test/resources/exerciceN/**` (incluant les `*.approved.txt` ApprovalTests)
- `src/main/java/.../App.java` et `src/test/java/.../AppTest.java` (l'enseignant·e ajoute des entrées au menu console au fil des exercices)

🔄 **Mis à jour à chaque `copier update`** (et donc à utiliser dans une PR à part si l'on veut éviter de perdre des customisations) :
- Maven Wrapper, `.gitignore`, `.gitattributes`, `LICENSE`
- Tous les workflows `.github/workflows/*` (et `update-autograding.sh` est ré-exécuté automatiquement à la fin pour régénérer le bloc `#@@@AUTOGRADING@@@` selon les exercices détectés)
- `.devcontainer/`, `.vscode/`, `.githooks/`, `AGENTS.md`, `.github/copilot-instructions.md`
- Scripts d'infra : `scripts/{grade-test,update-autograding,lint-doc-coherence,generate-student}.sh`
- `pom.xml` (volontairement hors `_skip_if_exists` : on veut que les bumps de plugins se propagent ; les rares deps spécifiques d'un TP sont à ré-appliquer manuellement après update)

### Adopter un TP créé avant Copier

Pour propager le méta-template dans un TP qui a été créé via l'ancien `create-tp.sh` (et n'a pas de `.copier-answers.yml`), créer le fichier d'answers à la main puis lancer `copier update` :

```bash
cd ../tpN

# Reproduire à la main la composition d'origine du TP
cat > .copier-answers.yml <<EOF
_src_path: gh:IUTInfoAix/template-tp
module:
  code: "R2.03"
  titre: "Qualité de développement"
  org_github: "IUTInfoAix-R203"
  classroom_org: "IUTInfoAix-R203-2026"
  codeowner: "@nedseb"
  contact_email: "sebastien.nedjar@univ-amu.fr"
tp:
  numero: 2
  titre_court: "tp2"
  titre_complet: "TP2 - TDD"
  description: "..."
  classroom_link: "https://classroom.github.com/a/..."
stack:
  java_version: 25
  features: [devcontainer, vscode-config, ai-tutor, autograding-classroom,
             generate-student, lint-quality, pre-commit-spotless, maven-ci,
             dependabot, issue-templates, codeowners]
  packs: []
  autograding_mode: tdd
EOF

# Commit le fichier d'answers
git add .copier-answers.yml && git commit -m "chore: adopter copier"

# Lancer le 1er copier update
copier update --trust --skip-answered

# Vérifier git diff, commit le résultat
git status -sb
git add -A && git commit -m "chore: 1ère mise à jour depuis IUTInfoAix/template-tp"
```

Grâce à `_skip_if_exists`, `src/exerciceN/` et le `README.md` ne sont pas touchés. Seule l'infra est rebrandée.

---

## Ajouter une feature ou un pack à un TP existant

Modifier `.copier-answers.yml` pour ajouter le nom dans `stack.features` ou `stack.packs`, puis relancer `copier update`.

**Exemple : ajouter le pack javafx à un TP existant**

```bash
cd ../tpN
yq -i '.stack.packs += ["javafx"]' .copier-answers.yml
copier update --skip-answered
xvfb-run --auto-servernum ./mvnw verify   # vérification idiomatique
```

`copier update` injecte automatiquement les 4 deps JavaFX dans le `pom.xml`, ajoute le `Dockerfile`, bascule `App.java` sur la version Application... et signale en conflit toute personnalisation locale qui collisionnerait.

**Exemple : retirer une feature**

```bash
yq -i '.stack.features -= ["dependabot"]' .copier-answers.yml
copier update --skip-answered
# Copier ne supprime PAS automatiquement les fichiers d'une feature désactivée.
# Supprimer manuellement : rm .github/dependabot.yml
```

Le cleanup interactif des orphelins est un point ouvert (cf. plan, "hors scope V1").

---

## Format `.copier-answers.yml`

Copier crée et maintient `.copier-answers.yml` à la racine du TP généré. Format :

```yaml
# Changes here will be overwritten by Copier; NEVER EDIT MANUALLY
_commit: 0.0.0.post42.dev0+abc1234
_src_path: gh:IUTInfoAix/template-tp
module:
  classroom_org: IUTInfoAix-R203-2026
  code: R2.03
  codeowner: '@nedseb'
  contact_email: sebastien.nedjar@univ-amu.fr
  org_github: IUTInfoAix-R203
  titre: Qualité de développement
stack:
  autograding_mode: tdd
  features:
  - devcontainer
  - vscode-config
  - ai-tutor
  - autograding-classroom
  - generate-student
  - lint-quality
  - pre-commit-spotless
  - maven-ci
  - dependabot
  - issue-templates
  java_version: 25
  packs: []
tp:
  classroom_link: https://classroom.github.com/a/abcDEF12
  description: 'Test-Driven Development : 6 exercices baby steps'
  numero: 2
  titre_complet: TP2 TDD
  titre_court: tp2
```

`_commit` épingle le SHA du méta-template. `copier update` lit `_src_path` pour savoir où re-fetcher.

> **Le commentaire `NEVER EDIT MANUALLY` n'est pas une règle stricte.** Vous pouvez modifier `stack.features`/`stack.packs` à la main pour activer ou désactiver une feature, à condition de relancer `copier update --skip-answered` derrière. C'est même la méthode recommandée pour ajouter un pack a posteriori.

---

## Tests en local

```bash
# Cloner le méta-template
git clone https://github.com/IUTInfoAix/template-tp.git
cd template-tp

# Tester une feature (enabled + disabled)
rm -rf /tmp/tp-test
copier copy --trust --defaults \
  --data-file features/lint-quality/test/answers.yml \
  . /tmp/tp-test
TP_DIR=/tmp/tp-test bats features/lint-quality/test/validate.bats

rm -rf /tmp/tp-no-test
copier copy --trust --defaults \
  --data-file features/lint-quality/test/answers-disabled.yml \
  . /tmp/tp-no-test
TP_DIR=/tmp/tp-no-test bats features/lint-quality/test/validate-disabled.bats

# Tester le pack javafx (nécessite xvfb)
rm -rf /tmp/tp-fx
copier copy --trust --defaults \
  --data-file packs/javafx/test/answers.yml \
  . /tmp/tp-fx
TP_DIR=/tmp/tp-fx bats packs/javafx/test/validate.bats
```

Tout est vert ? Pousser ; la CI ré-exécute la matrice complète.

---

## FAQ migration

### Mon TP a été généré avec l'ancien `template-tp-java` (R203). Est-ce que je dois migrer ?

**Non, pas obligatoirement.** Les TPs déjà générés embarquent leur propre infrastructure : `pom.xml`, `.github/`, `.devcontainer/`, scripts. Ils ne fetchent rien du méta-template à l'exécution. Ils continuent de fonctionner indéfiniment.

La migration vers le nouveau méta-template est utile uniquement si vous voulez :
- bénéficier des futures mises à jour du méta-template via `copier update`,
- aligner R202 et R203 sur la même version d'infrastructure.

### Comment migrer un TP existant ?

```bash
cd ../tpN
copier copy --trust --data-file - gh:IUTInfoAix/template-tp . <<EOF
module: {code: "R2.03", titre: "...", org_github: "IUTInfoAix-R203", ...}
tp: {numero: N, titre_court: "tpN", titre_complet: "TPN ...", ...}
stack: {features: [...], packs: [...], ...}
EOF
```

Conflits attendus sur les fichiers où vous avez personnalisé (README, exercices). Résolvez à la main puis commit.

### Les anciens repos `template-tp-java` / `template-tp-javafx` sont archivés. Je peux encore les cloner ?

Oui, **en lecture seule**. Aucune PR/issue ne peut être ouverte. Le contenu reste accessible à <https://github.com/IUTInfoAix-R203/template-tp-java> et <https://github.com/IUTInfoAix-R202/template-tp-javafx>.

### Mon TP utilisait `./create-tp.sh` (de l'ancien template). Comment je le remplace ?

`copier copy --trust gh:IUTInfoAix/template-tp ../tpN` est l'équivalent. La grosse différence : Copier crée un `.copier-answers.yml` que vous pouvez versionner et utiliser pour `copier update` plus tard, alors que `create-tp.sh` ne laissait aucune trace de la composition initiale.

---

## Pièges connus

### `${{ github.x }}` dans un fichier `.jinja`

GitHub Actions utilise `${{ ... }}` qui collisionne avec la syntaxe Jinja2 `{{ ... }}`. Deux workflows (`classroom.yml`, `generate-student.yml`) sont **non-templated** (pas de suffixe `.jinja`) pour cette raison ; la version Java y est hardcodée à 25 (commune R202/R203). Voir [CONTRIBUTING.md](CONTRIBUTING.md) pour la stratégie quand on touche à un workflow templated.

### Cache Spotless trompeur

`./mvnw spotless:check` peut passer en local grâce au cache Spotless mais échouer en CI sur le premier run. Le cache Spotless est invalidé par tout changement de contenu — donc si vous modifiez un `.java.jinja` qui se réinjecte ensuite, vous ne verrez le défaut qu'en CI. **Toujours pousser et regarder la CI** avant de merger une modif des `.java.jinja`.

### Dossier exclu via `_exclude`

Pour exclure un **dossier entier** conditionnellement, il faut deux entrées dans `_exclude` (le dossier + le glob `/**`) :

```yaml
_exclude:
  - "{% if 'X' not in stack.features %}.dossier{% endif %}"
  - "{% if 'X' not in stack.features %}.dossier/**{% endif %}"
```

### `{% if %}` en début de fichier `.java`

Sans `-` strip whitespace, le `\n` initial de l'else laisse une ligne vide en tête du fichier généré, que Spotless rejette (`@@ -1,4 +1,3 @@`). Toujours utiliser `{%- if X -%}...{%- else -%}...{%- endif -%}`.

### Push direct sur `main`

L'auto-mode classifier de Claude Code bloque le push direct sur main. Toutes les modifs passent par PR + squash merge. C'est intentionnel — ça force la CI à passer avant le merge.
