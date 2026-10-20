from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime


class UserProfileCreate(BaseModel):
    age_started_smoking: Optional[int] = None
    cigarettes_per_day: Optional[int] = None
    cigarettes_per_pack: int = 20
    price_per_pack: Optional[float] = None
    currency: str = "USD"
    first_smoke_after_waking: Optional[str] = None
    smoking_duration_years: Optional[int] = None
    previous_quit_attempts: Optional[int] = None
    previous_quit_experience: Optional[str] = None
    current_goal: Optional[str] = None  # quit/reduce/understand
    target_quit_date: Optional[date] = None
    preferred_reminder_style: Optional[str] = None


class UserProfileUpdate(BaseModel):
    age_started_smoking: Optional[int] = None
    cigarettes_per_day: Optional[int] = None
    cigarettes_per_pack: Optional[int] = None
    price_per_pack: Optional[float] = None
    currency: Optional[str] = None
    first_smoke_after_waking: Optional[str] = None
    smoking_duration_years: Optional[int] = None
    previous_quit_attempts: Optional[int] = None
    previous_quit_experience: Optional[str] = None
    current_goal: Optional[str] = None
    target_quit_date: Optional[date] = None
    preferred_reminder_style: Optional[str] = None


class UserProfileResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    age_started_smoking: Optional[int] = None
    cigarettes_per_day: Optional[int] = None
    cigarettes_per_pack: int
    price_per_pack: Optional[float] = None
    currency: str
    first_smoke_after_waking: Optional[str] = None
    smoking_duration_years: Optional[int] = None
    previous_quit_attempts: Optional[int] = None
    previous_quit_experience: Optional[str] = None
    current_goal: Optional[str] = None
    target_quit_date: Optional[date] = None
    preferred_reminder_style: Optional[str] = None
    created_at: datetime
    updated_at: datetime


class SurveyResponseCreate(BaseModel):
    question_key: str
    response_json: str  # JSON string


class SurveyResponseUpdate(BaseModel):
    response_json: str


class SurveyResponseResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    question_key: str
    response_json: str
    created_at: datetime
    updated_at: datetime
