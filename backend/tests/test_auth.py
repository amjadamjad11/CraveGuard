"""Tests for authentication endpoints."""
import pytest


@pytest.mark.asyncio
async def test_register(client):
    resp = await client.post("/api/v1/auth/register", json={
        "email": "new@test.com", "password": "pass123",
        "preferred_name": "Newbie", "age_confirmed": True,
    })
    assert resp.status_code == 200
    data = resp.json()
    assert "access_token" in data
    assert data["access_token"]


@pytest.mark.asyncio
async def test_register_duplicate(client):
    await client.post("/api/v1/auth/register", json={
        "email": "dup@test.com", "password": "pass123",
    })
    resp = await client.post("/api/v1/auth/register", json={
        "email": "dup@test.com", "password": "pass123",
    })
    assert resp.status_code == 400


@pytest.mark.asyncio
async def test_login(client):
    await client.post("/api/v1/auth/register", json={
        "email": "login@test.com", "password": "mypass",
    })
    resp = await client.post("/api/v1/auth/login",
        data={"username": "login@test.com", "password": "mypass"})
    assert resp.status_code == 200
    assert "access_token" in resp.json()


@pytest.mark.asyncio
async def test_login_wrong_password(client):
    await client.post("/api/v1/auth/register", json={
        "email": "wrong@test.com", "password": "mypass",
    })
    resp = await client.post("/api/v1/auth/login",
        data={"username": "wrong@test.com", "password": "wrongpass"})
    assert resp.status_code == 401


@pytest.mark.asyncio
async def test_me(auth_client):
    resp = await auth_client.get("/api/v1/auth/me")
    assert resp.status_code == 200
    data = resp.json()
    assert data["email"] == "test@example.com"
    assert data["preferred_name"] == "Tester"


@pytest.mark.asyncio
async def test_unauthorized_access(client):
    resp = await client.get("/api/v1/auth/me")
    assert resp.status_code == 401
