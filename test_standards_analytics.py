"""Tests for shared motivational standards analytics."""

from standards_analytics import (
    best_standard_achieved,
    coach_insight,
    compare,
    next_standard,
    percent_progress,
    time_to_next_standard,
)

STANDARD = {
    "b_time": 80.0,
    "bb_time": 75.0,
    "a_time": 70.0,
    "aa_time": 65.0,
    "aaa_time": 60.0,
    "aaaa_time": 55.0,
}


def test_best_standard_achieved():
    assert best_standard_achieved(64.0, STANDARD) == "AA"


def test_next_standard():
    assert next_standard(64.0, STANDARD) == "AAA"


def test_time_to_next_standard():
    assert time_to_next_standard(64.0, STANDARD) == 4.0


def test_percent_progress_range():
    progress = percent_progress(62.5, STANDARD)
    assert progress is not None
    assert 0 <= progress <= 100


def test_compare_dataclass():
    result = compare(64.0, STANDARD)
    assert result.current_level == "AA"
    assert result.next_level == "AAA"


def test_coach_insight_mentions_levels():
    message = coach_insight("100 Freestyle", 64.0, STANDARD)
    assert "AA" in message
    assert "AAA" in message
