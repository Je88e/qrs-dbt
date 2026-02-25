import re
import sys
import unittest
from pathlib import Path


REF_RE = re.compile(r"""ref\(\s*['"]([^'"]+)['"]\s*\)""")
SOURCE_RE = re.compile(r"""source\(\s*['"]""")


def extract_refs(sql_text: str) -> list[str]:
    return REF_RE.findall(sql_text)


class TestH3Layering(unittest.TestCase):
    def setUp(self):
        self.repo_root = Path(__file__).resolve().parents[1]

    def _read(self, rel_path: str) -> str:
        return (self.repo_root / rel_path).read_text(encoding="utf-8")

    def test_staging_only_refs_seeds(self):
        staging_files = [
            "qrs/models/staging/stg_quality_root_cause_categories.sql",
            "qrs/models/staging/stg_quality_root_cause_mapping.sql",
            "qrs/models/staging/stg_quality_risk_levels.sql",
            "qrs/models/staging/stg_quality_risk_mapping.sql",
            "qrs/models/staging/stg_quality_event_deviation_seed.sql",
            "qrs/models/staging/stg_quality_event_capa_seed.sql",
            "qrs/models/staging/stg_quality_event_change_control_seed.sql",
            "qrs/models/staging/stg_quality_event_complaint_seed.sql",
            "qrs/models/staging/stg_quality_event_product_recall_seed.sql",
        ]

        allowed_seed_refs = {
            "quality_root_cause_categories",
            "quality_root_cause_mapping",
            "quality_risk_levels",
            "quality_risk_mapping",
            "qms_deviation",
            "qms_capa",
            "qms_change_control",
            "pv_complaint",
            "pv_product_recall",
        }

        violations: list[str] = []
        for rel in staging_files:
            txt = self._read(rel)
            if SOURCE_RE.search(txt):
                violations.append(f"{rel}: contains source()")
            for r in extract_refs(txt):
                if r not in allowed_seed_refs:
                    violations.append(f"{rel}: ref('{r}') not allowed in staging (H3)")

        if violations:
            self.fail("\n".join(violations))

    def test_business_only_refs_staging(self):
        business_files = [
            "qrs/models/business/dim_root_cause_categories.sql",
            "qrs/models/business/dim_risk_levels.sql",
            "qrs/models/business/fct_quality_events.sql",
        ]

        allowed_staging_refs = {
            "stg_quality_root_cause_categories",
            "stg_quality_root_cause_mapping",
            "stg_quality_risk_levels",
            "stg_quality_risk_mapping",
            "stg_quality_event_deviation_seed",
            "stg_quality_event_capa_seed",
            "stg_quality_event_change_control_seed",
            "stg_quality_event_complaint_seed",
            "stg_quality_event_product_recall_seed",
        }

        violations: list[str] = []
        for rel in business_files:
            txt = self._read(rel)
            if SOURCE_RE.search(txt):
                violations.append(f"{rel}: contains source()")
            for r in extract_refs(txt):
                if r not in allowed_staging_refs:
                    violations.append(f"{rel}: ref('{r}') not allowed in business (H3)")

        if violations:
            self.fail("\n".join(violations))


if __name__ == "__main__":
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(TestH3Layering)
    runner = unittest.TextTestRunner(verbosity=2)
    result = runner.run(suite)
    sys.exit(0 if result.wasSuccessful() else 1)

