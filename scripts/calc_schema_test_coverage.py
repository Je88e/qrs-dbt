import argparse
import os
from pathlib import Path

import yaml


def _iter_yaml_docs(path: Path):
    with path.open("r", encoding="utf-8") as f:
        for doc in yaml.safe_load_all(f):
            if isinstance(doc, dict):
                yield doc


def _extract_test_names(col: dict) -> list[str]:
    tests = []
    for key in ("data_tests", "tests"):
        raw = col.get(key)
        if not raw:
            continue
        if not isinstance(raw, list):
            continue
        for t in raw:
            if isinstance(t, str):
                tests.append(t)
            elif isinstance(t, dict) and t:
                tests.append(next(iter(t.keys())))
    return tests


def _categorize_tests(test_names: list[str]) -> set[str]:
    categories = set()
    for name in test_names:
        base = name.split(".")[-1]
        if base in {"unique", "not_null", "relationships", "accepted_values"}:
            categories.add(base)
    return categories


def load_model_test_coverage(model_dir: Path) -> dict[str, dict]:
    info: dict[str, dict] = {}
    for yml_path in sorted(model_dir.rglob("*.yml")) + sorted(model_dir.rglob("*.yaml")):
        for doc in _iter_yaml_docs(yml_path):
            models = doc.get("models")
            if not isinstance(models, list):
                continue
            for m in models:
                if not isinstance(m, dict):
                    continue
                name = m.get("name")
                if not name:
                    continue
                cols = m.get("columns") or []
                if not isinstance(cols, list):
                    cols = []

                total_cols = len([c for c in cols if isinstance(c, dict) and c.get("name")])
                tested_cols = 0
                test_names_all: list[str] = []
                for c in cols:
                    if not isinstance(c, dict) or not c.get("name"):
                        continue
                    test_names = _extract_test_names(c)
                    test_names_all.extend(test_names)
                    if test_names:
                        tested_cols += 1

                info[name] = {
                    "file": str(yml_path),
                    "total_cols": total_cols,
                    "tested_cols": tested_cols,
                    "categories": sorted(_categorize_tests(test_names_all)),
                }
    return info


def render_markdown(rows: list[dict], overall: dict) -> str:
    lines: list[str] = []
    lines.append("# schema tests 覆盖率报告")
    lines.append("")
    lines.append("覆盖率口径：以 schema.yml 中该模型已声明的列为基准，统计“带至少1条 data_tests/tests 的列占比”。")
    lines.append("")
    lines.append("| 模型 | 已声明列数 | 有测试列数 | 覆盖率 | 关键测试类型 |")
    lines.append("|---|---:|---:|---:|---|")
    for r in rows:
        lines.append(
            f"| {r['name']} | {r['total_cols']} | {r['tested_cols']} | {r['pct']:.1f}% | {', '.join(r['categories']) or '-'} |"
        )
    lines.append("")
    lines.append(
        f"总体：{overall['tested_cols']}/{overall['total_cols']}（{overall['pct']:.1f}%）"
    )
    return "\n".join(lines) + "\n"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--project-root", default=".", help="dbt repo root, containing qrs/")
    p.add_argument("--models", nargs="*", default=[], help="model names to report; empty means all models in YAML")
    p.add_argument("--output", default="", help="optional markdown output path")
    args = p.parse_args()

    project_root = Path(args.project_root).resolve()
    model_dir = project_root / "qrs" / "models"
    info = load_model_test_coverage(model_dir)

    names = args.models or sorted(info.keys())
    rows: list[dict] = []
    total_cols = 0
    tested_cols = 0
    for name in names:
        m = info.get(name)
        if not m:
            continue
        total_cols += m["total_cols"]
        tested_cols += m["tested_cols"]
        pct = 0.0 if m["total_cols"] == 0 else (m["tested_cols"] / m["total_cols"] * 100.0)
        rows.append(
            {
                "name": name,
                "total_cols": m["total_cols"],
                "tested_cols": m["tested_cols"],
                "pct": pct,
                "categories": m["categories"],
            }
        )

    overall = {
        "total_cols": total_cols,
        "tested_cols": tested_cols,
        "pct": 0.0 if total_cols == 0 else (tested_cols / total_cols * 100.0),
    }

    md = render_markdown(rows, overall)
    print(md)
    if args.output:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(md, encoding="utf-8")


if __name__ == "__main__":
    main()
