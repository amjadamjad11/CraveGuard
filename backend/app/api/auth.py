from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User, UserProfile
from app.schemas.auth import UserCreate, Token, UserResponse, RegistrationResponse
from app.services import auth_service

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/register", response_model=RegistrationResponse)
async def register(
    user_data: UserCreate, db: AsyncSession = Depends(get_db)
) -> RegistrationResponse:
    """Register a new user.

    Returns a *temporary* registration token and ``needs_onboarding=True``.
    The client should use this token ONLY while completing the onboarding
    survey (POST /profile/complete-onboarding), then discard it and direct
    the user to the login screen.
    """
    try:
        result = await auth_service.create_user(db, user_data)
        return result
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db),
) -> Token:
    """Authenticate a user and return an access token."""
    result = await auth_service.authenticate_user(
        db, form_data.username, form_data.password
    )
    if not result:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return result


@router.get("/me", response_model=UserResponse)
async def get_me(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> UserResponse:
    """Return the currently authenticated user's info including onboarding status."""
    result = await db.execute(
        select(UserProfile).where(UserProfile.user_id == current_user.id)
    )
    profile = result.scalar_one_or_none()
    onboarding_complete = profile.onboarding_complete if profile else False
    return UserResponse(
        id=current_user.id,
        email=current_user.email,
        preferred_name=current_user.preferred_name,
        age_confirmed=current_user.age_confirmed,
        language=current_user.language,
        timezone=current_user.timezone,
        is_active=current_user.is_active,
        onboarding_complete=onboarding_complete,
        created_at=current_user.created_at,
        updated_at=current_user.updated_at,
    )


@router.delete("/account")
async def delete_account(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
) -> dict:
    """Delete the currently authenticated user's account."""
    await auth_service.delete_user(db, current_user.id)
    return {"message": "Account deleted successfully"}
