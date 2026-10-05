#!/usr/bin/env python3
"""Tests for aggregate_targets.py.

Run: python3 -m pytest tools/apple/aggregate_targets_test.py -q
"""
from __future__ import annotations

import yaml

import aggregate_targets as at


def test_the_real_spec_has_complete_aggregates():
    spec = yaml.safe_load(at.DEFAULT_SPEC.read_text())
    assert at.missing(spec) == []


def test_activity_is_in_every_aggregate_that_claims_it():
    spec = yaml.safe_load(at.DEFAULT_SPEC.read_text())
    aggregates = {name: body["targets"] for name, body in spec["aggregateTargets"].items()}
    assert "AgenticToolkitActivity-macOS" in aggregates[at.MACOS_ALL]
    assert "AgenticToolkitActivity-macOS" in aggregates[at.MACOS_TESTS_ALL]
    assert "AgenticToolkitActivityTests" in aggregates[at.MACOS_TESTS_ALL]
    assert "AgenticToolkitActivity-iOS" in aggregates[at.IOS_ALL]


def test_a_target_left_out_is_named():
    spec = {
        "targets": {
            "Lib-macOS": {"type": "framework", "platform": "macOS"},
            "Lib-iOS": {"type": "framework", "platform": "iOS"},
            "Both": {"type": "framework"},
            "LibTests": {"type": "bundle.unit-test", "platform": "macOS"},
        },
        "aggregateTargets": {
            at.MACOS_ALL: {"targets": ["Both"]},
            at.MACOS_TESTS_ALL: {"targets": ["Both", "Lib-macOS"]},
            at.IOS_ALL: {"targets": []},
        },
    }
    assert sorted(at.missing(spec)) == sorted([
        f"{at.MACOS_ALL} is missing Lib-macOS",
        f"{at.IOS_ALL} is missing Lib-iOS",
        f"{at.IOS_ALL} is missing Both",
        f"{at.MACOS_TESTS_ALL} is missing LibTests",
    ])
