"""Tests for the risk scoring algorithm."""
import pytest
from app.ai.risk_scoring import calculate_risk_score, cluster_events, haversine_distance


def test_high_risk_score():
    result = calculate_risk_score(
        smoking_events_nearby=8,
        craving_events_nearby=5,
        visit_count=15,
        avg_craving_intensity=8.5,
    )
    assert result["level"] == "high"
    assert result["score"] > 0.7
    assert len(result["factors"]) > 0


def test_medium_risk_score():
    result = calculate_risk_score(
        smoking_events_nearby=4,
        craving_events_nearby=2,
        visit_count=8,
        avg_craving_intensity=5.0,
    )
    assert result["level"] in ("medium", "low")


def test_insufficient_evidence():
    result = calculate_risk_score(
        smoking_events_nearby=1,
        craving_events_nearby=1,
        visit_count=3,
        avg_craving_intensity=4.0,
    )
    assert result["level"] == "insufficient"
    assert result["score"] == 0.0


def test_haversine_distance():
    # Same point → 0 meters
    assert haversine_distance(28.6, 77.2, 28.6, 77.2) == 0.0
    # Known distance: ~111 km for 1 degree latitude
    dist = haversine_distance(28.0, 77.0, 29.0, 77.0)
    assert 110000 < dist < 112000


def test_cluster_events():
    events = [
        {"latitude": 28.600, "longitude": 77.200, "type": "smoking", "intensity": 5},
        {"latitude": 28.6001, "longitude": 77.2001, "type": "smoking", "intensity": 6},
        {"latitude": 28.6002, "longitude": 77.2002, "type": "craving", "intensity": 8},
        {"latitude": 28.6003, "longitude": 77.2003, "type": "craving", "intensity": 7},
        # Far away point
        {"latitude": 29.000, "longitude": 78.000, "type": "smoking", "intensity": 3},
    ]
    clusters = cluster_events(events)
    # Near points should cluster together but far point is alone (insufficient evidence)
    # The cluster with 4 events should be returned, the single one should not
    assert len(clusters) >= 1
    main_cluster = clusters[0]
    assert main_cluster["smoking_events_nearby"] >= 2
    assert main_cluster["risk_level"] in ("high", "medium", "low")


def test_cluster_events_empty():
    assert cluster_events([]) == []


def test_cluster_events_no_location():
    events = [
        {"latitude": None, "longitude": None, "type": "smoking", "intensity": 5},
    ]
    assert cluster_events(events) == []
