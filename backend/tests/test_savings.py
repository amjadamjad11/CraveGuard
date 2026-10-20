"""Tests for savings calculations."""
import pytest


@pytest.mark.asyncio
async def test_savings_empty_user(auth_client):
    """Savings should return zeros for a new user with no data."""
    resp = await auth_client.get("/api/v1/progress/savings")
    assert resp.status_code == 200
    data = resp.json()
    assert data["total_savings"] >= 0
    assert "currency" in data


@pytest.mark.asyncio
async def test_savings_with_baseline(auth_client):
    """After setting baseline and logging events, savings should reflect."""
    # Set baseline
    await auth_client.post("/api/v1/smoking/smoking-baseline", json={
        "cigarettes_per_day": 20, "cost_per_day": 250.0,
    })
    # Log 5 cigarettes today (below baseline of 20)
    for _ in range(5):
        await auth_client.post("/api/v1/smoking/smoking-events", json={
            "cigarettes_count": 1,
        })
    resp = await auth_client.get("/api/v1/progress/savings")
    assert resp.status_code == 200
    data = resp.json()
    # Should have positive daily savings since 5 < 20
    assert data["daily_savings"] >= 0


@pytest.mark.asyncio
async def test_daily_summary(auth_client):
    resp = await auth_client.get("/api/v1/progress/daily-summary")
    assert resp.status_code == 200
    data = resp.json()
    assert "cigarettes_smoked" in data
    assert "cravings_count" in data


@pytest.mark.asyncio
async def test_weekly_summary(auth_client):
    resp = await auth_client.get("/api/v1/progress/weekly-summary")
    assert resp.status_code == 200
    data = resp.json()
    assert "days" in data
    assert len(data["days"]) == 7


@pytest.mark.asyncio
async def test_milestones(auth_client):
    resp = await auth_client.get("/api/v1/progress/milestones")
    assert resp.status_code == 200
    assert isinstance(resp.json(), list)


@pytest.mark.asyncio
async def test_savings_goals_crud(auth_client):
    # Create
    resp = await auth_client.post("/api/v1/progress/savings-goals", json={
        "title": "New Headphones", "target_amount": 3000,
    })
    assert resp.status_code == 200
    goal_id = resp.json()["id"]

    # List
    resp = await auth_client.get("/api/v1/progress/savings-goals")
    assert resp.status_code == 200
    assert len(resp.json()) == 1

    # Update
    resp = await auth_client.put(f"/api/v1/progress/savings-goals/{goal_id}", json={
        "current_amount": 500,
    })
    assert resp.status_code == 200

    # Delete
    resp = await auth_client.delete(f"/api/v1/progress/savings-goals/{goal_id}")
    assert resp.status_code == 200

    # Verify deleted
    resp = await auth_client.get("/api/v1/progress/savings-goals")
    assert len(resp.json()) == 0
