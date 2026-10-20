from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import User, UserProfile
from app.schemas.auth import UserCreate, Token
from app.core.security import get_password_hash, verify_password, create_access_token


async def create_user(db: AsyncSession, user_data: UserCreate) -> Token:
    """Register a new user, create profile, and return JWT token."""
    result = await db.execute(select(User).where(User.email == user_data.email))
    if result.scalar_one_or_none():
        raise ValueError("Email already registered")

    user = User(
        email=user_data.email,
        hashed_password=get_password_hash(user_data.password),
        preferred_name=user_data.preferred_name or "Friend",
        age_confirmed=user_data.age_confirmed,
        language=user_data.language,
        timezone=user_data.timezone,
    )
    db.add(user)
    await db.flush()

    profile = UserProfile(user_id=user.id)
    db.add(profile)
    await db.commit()
    await db.refresh(user)

    token = create_access_token(data={"sub": str(user.id)})
    return Token(access_token=token)


async def authenticate_user(db: AsyncSession, email: str, password: str):
    """Authenticate user and return JWT token or None."""
    result = await db.execute(select(User).where(User.email == email))
    user = result.scalar_one_or_none()
    if not user or not verify_password(password, user.hashed_password):
        return None
    token = create_access_token(data={"sub": str(user.id)})
    return Token(access_token=token)


async def delete_user(db: AsyncSession, user_id: int):
    """Delete user and all associated data (cascade)."""
    result = await db.execute(select(User).where(User.id == user_id))
    user = result.scalar_one_or_none()
    if user:
        await db.delete(user)
        await db.commit()
