from app.services.best_times_extract import (
    BestTimesExtractResult,
    ExtractedBestTime,
    _normalize_result,
    decode_data_url_or_base64,
)


def test_normalize_result_maps_y_suffix_to_scy():
    raw = BestTimesExtractResult(
        times=[
            ExtractedBestTime(
                event="50 Fly",
                time="31.60 Y",
                course=None,
                date="03/01/2026",
                meet_name="2026 RSC SC Regional Champs",
            ),
            ExtractedBestTime(
                event="100 Fly",
                time="1:12.05Y",
                course="Y",
                date="03/01/2026",
                meet_name="2026 RSC SC Regional Champs",
            ),
        ]
    )
    cleaned = _normalize_result(raw, course_hint="SCY")
    assert len(cleaned.times) == 2
    assert cleaned.times[0].time == "31.60"
    assert cleaned.times[0].course == "SCY"
    assert cleaned.times[1].time == "1:12.05"
    assert cleaned.detected_course == "SCY"


def test_normalize_result_maps_l_suffix_to_lcm():
    raw = BestTimesExtractResult(
        times=[
            ExtractedBestTime(
                event="50 Free",
                time="33.03 L",
                course="L",
            )
        ]
    )
    cleaned = _normalize_result(raw, course_hint=None)
    assert cleaned.times[0].course == "LCM"
    assert cleaned.detected_course == "LCM"


def test_decode_data_url():
    # "hi" base64
    payload = "data:image/png;base64,aGk="
    blob, mime = decode_data_url_or_base64(payload)
    assert mime == "image/png"
    assert blob == b"hi"
