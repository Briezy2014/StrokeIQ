import pytest

from app.utils.timestamps import frame_to_ms, ms_to_frame, seconds_to_ms


def test_ms_to_frame_and_back():
    assert ms_to_frame(1000, 30) == 30
    assert frame_to_ms(30, 30) == 1000.0


def test_seconds_to_ms():
    assert seconds_to_ms(1.5) == 1500


def test_invalid_fps():
    with pytest.raises(ValueError):
        ms_to_frame(100, 0)
    with pytest.raises(ValueError):
        frame_to_ms(-1, 30)
