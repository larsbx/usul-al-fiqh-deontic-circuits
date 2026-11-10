#!/usr/bin/env python3
"""Check rejection of mismatched component evidence."""

from importlib.util import module_from_spec, spec_from_file_location
import json
from pathlib import Path
import unittest

spec = spec_from_file_location("ida_pilot", Path(__file__).with_name("check-ida-pilot.py"))
pilot = module_from_spec(spec)
spec.loader.exec_module(pilot)


class PilotReceiptTests(unittest.TestCase):
    def setUp(self):
        self.receipt = {
            "schema": "usul.ida.context.verification.v1", "status": "passed",
            "revision": "current", "inputs_match_head": True,
            "source_sha256": {"formal/model.lean": "expected"},
        }

    def validate(self, **changes):
        raw = json.dumps({**self.receipt, **changes}).encode()
        return pilot.validate_report(raw, "context", "current", lambda _: "expected")

    def test_component_digest_binds_original_bytes(self):
        result = self.validate()
        self.assertEqual(result["sha256"], pilot.digest(json.dumps(self.receipt).encode()))

    def test_rejects_wrong_gate_stale_revision_and_failed_or_dirty_receipts(self):
        for changes in ({"schema": "usul.ida.admission.verification.v1"},
                        {"revision": "previous"}, {"status": "failed"},
                        {"inputs_match_head": False}):
            with self.subTest(changes=changes), self.assertRaises(ValueError):
                self.validate(**changes)

    def test_rejects_empty_changed_or_external_inputs(self):
        for inputs in ({}, {"formal/model.lean": "changed"}, {"../model.lean": "expected"}):
            with self.subTest(inputs=inputs), self.assertRaises(ValueError):
                self.validate(source_sha256=inputs)


if __name__ == "__main__":
    unittest.main()
