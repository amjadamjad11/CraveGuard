"""Test fixtures for the CraveGuard backend."""
import asyncio
import pytest
import pytest_asyncio
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.database import engine, Base


@pytest_asyncio.fixture(autouse=True)
async def setup_db():
    """Create tables before each test and clean up after."""
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)


@pytest_asyncio.fixture
async def client():
    """Async HTTP test client."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as c:
        yield c


@pytest_asyncio.fixture
async def auth_client(client: AsyncClient):
    """Authenticated test client with a registered user."""
    resp = await client.post("/api/v1/auth/register", json={
        "email": "test@example.com",
        "password": "testpass123",
        "preferred_name": "Tester",
        "age_confirmed": True,
    })
    assert resp.status_code == 200
    token = resp.json()["access_token"]
    client.headers["Authorization"] = f"Bearer {token}"
    yield client
