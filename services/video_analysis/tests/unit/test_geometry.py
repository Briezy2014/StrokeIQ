from app.utils.geometry import angle_degrees


def test_right_angle():
    assert angle_degrees((0, 0), (0, 0), (1, 0)) != angle_degrees((1, 0), (0, 0), (0, 1))
    angle = angle_degrees((1, 0), (0, 0), (0, 1))
    assert 89.0 < angle < 91.0
