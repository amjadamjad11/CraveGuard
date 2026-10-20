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
    created_at: datetime
    updated_at: datetime
