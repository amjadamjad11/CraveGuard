"""Tests for smoking and craving endpoints."""
import pytest


@pytest.mark.asyncio
async def test_create_smoking_event(auth_client):
    resp = await auth_client.post("/api/v1/smoking/smoking-events", json={
        "cigarettes_count": 1,
        "mood": "stressed",
        "trigger_category": "Stress / Anxiety",
        "craving_intensity": 7,
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["cigarettes_count"] == 1
    assert data["trigger_category"] == "Stress / Anxiety"


@pytest.mark.asyncio
async def test_get_smoking_events(auth_client):
    # Create a few events
    for _ in range(3):
        await auth_client.post("/api/v1/smoking/smoking-events", json={
            "cigarettes_count": 1, "mood": "neutral",
        })
    resp = await auth_client.get("/api/v1/smoking/smoking-events")
    assert resp.status_code == 200
    assert len(resp.json()) == 3


@pytest.mark.asyncio
async def test_today_count(auth_client):
    await auth_client.post("/api/v1/smoking/smoking-events", json={"cigarettes_count": 2})
    await auth_client.post("/api/v1/smoking/smoking-events", json={"cigarettes_count": 3})
    resp = await auth_client.get("/api/v1/smoking/today-count")
    assert resp.status_code == 200
    assert resp.json()["count"] == 5


@pytest.mark.asyncio
async def test_create_craving_event(auth_client):
    resp = await auth_client.post("/api/v1/smoking/craving-events", json={
        "intensity_before": 8,
        "trigger_category": "Boredom",
        "feeling": "bored",
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["intensity_before"] == 8
    assert data["intensity_after"] is None


@pytest.mark.asyncio
async def test_create_baseline(auth_client):
    resp = await auth_client.post("/api/v1/smoking/smoking-baseline", json={
        "cigarettes_per_day": 15,
        "cost_per_day": 187.5,
    })
    assert resp.status_code == 200
    data = resp.json()
    assert data["cigarettes_per_day"] == 15
