#!/usr/bin/env python3
"""Hook Copier `_tasks` : valide les `requires`/`conflicts` des features et packs activés.

Reçoit les listes actives en arguments (passés par Copier via interpolation Jinja2 dans
`_tasks`), charge les `feature.yml`/`pack.yml` du méta-template, et fail explicitement si :

- une feature/pack active référence une dépendance (`requires`) inactive ;
- deux items mutuellement exclusifs (`conflicts`) sont simultanément actifs.

Usage : validate_deps.py --features 'a,b,c' --packs 'x,y'
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path

import yaml

META_ROOT = Path(__file__).resolve().parent.parent


def load_yaml(path: Path) -> dict:
    if not path.exists():
        return {}
    return yaml.safe_load(path.read_text()) or {}


def collect_metadata() -> dict[str, dict]:
    """Index des feature.yml et pack.yml par nom."""
    items: dict[str, dict] = {}
    for kind, glob in (("features", "*/feature.yml"), ("packs", "*/pack.yml")):
        root = META_ROOT / kind
        if not root.exists():
            continue
        for meta_file in root.glob(glob):
            data = load_yaml(meta_file)
            if name := data.get("name"):
                items[name] = data
    return items


def parse_csv(value: str) -> list[str]:
    return [item.strip() for item in value.split(",") if item.strip()]


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--features", default="")
    parser.add_argument("--packs", default="")
    args = parser.parse_args()

    active = set(parse_csv(args.features)) | set(parse_csv(args.packs))

    metadata = collect_metadata()
    errors: list[str] = []

    for name in sorted(active):
        meta = metadata.get(name)
        if meta is None:
            errors.append(
                f"  - '{name}' actif mais sans metadata "
                f"(manque features/{name}/feature.yml ou packs/{name}/pack.yml)"
            )
            continue
        for dep in meta.get("requires") or []:
            if dep not in active:
                errors.append(f"  - '{name}' requires '{dep}' (non activé)")
        for foe in meta.get("conflicts") or []:
            if foe in active:
                errors.append(f"  - '{name}' conflicts with '{foe}' (les deux sont actifs)")

    if errors:
        sys.stderr.write("validate_deps : composition invalide\n")
        sys.stderr.write("\n".join(errors) + "\n")
        return 1

    print(f"validate_deps OK ({len(active)} items actifs : {', '.join(sorted(active)) or 'none'})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
