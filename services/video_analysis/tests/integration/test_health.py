def test_health_ok(client):
    response = client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["engine_version"]
    assert data["ffmpeg_available"] is True
    assert data["ffprobe_available"] is True
    assert data["status"] in {"ok", "degraded"}
