from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class UserCreate(BaseModel):
    email: str
    password: str
    preferred_name: Optional[str] = None
    age_confirmed: bool = False
    language: str = "en"
    timezone: str = "UTC"


class UserLogin(BaseModel):
    email: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"


class RegistrationResponse(BaseModel):
    """Returned after successful registration.

    The token is a *temporary* registration token to be used ONLY during the
    onboarding survey.  The client must NOT store it as the long-term session
    token.  After the onboarding survey is saved the client discards this token
    and directs the user to the login screen.
    """
    access_token: str
    token_type: str = "bearer"
    needs_onboarding: bool = True
    user_id: int
    preferred_name: Optional[str] = None


class TokenData(BaseModel):
    user_id: Optional[int] = None


class UserResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    email: str
    preferred_name: Optional[str] = None
    age_confirmed: bool
    language: str
    timezone: str
    is_active: bool
    onboarding_complete: bool = False
    created_at: datetime
    updated_at: datetime
