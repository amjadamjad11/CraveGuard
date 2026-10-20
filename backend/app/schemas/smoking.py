from pydantic import BaseModel, ConfigDict, Field
from typing import Optional
from datetime import datetime


class SmokingEventCreate(BaseModel):
    cigarettes_count: int = 1
    event_time: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    mood: Optional[str] = None
    trigger_category: Optional[str] = None
    craving_intensity: Optional[int] = Field(default=None, ge=1, le=10)
    social_context: Optional[str] = None
    notes: Optional[str] = None


class SmokingEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    cigarettes_count: int
    event_time: Optional[datetime] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    mood: Optional[str] = None
    trigger_category: Optional[str] = None
    craving_intensity: Optional[int] = None
    social_context: Optional[str] = None
    notes: Optional[str] = None
    created_at: datetime


class CravingEventCreate(BaseModel):
    intensity_before: int = Field(ge=1, le=10)
    trigger_category: Optional[str] = None
    feeling: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    intervention_used: Optional[str] = None
    intervention_helped: Optional[bool] = None


class CravingEventUpdate(BaseModel):
    intensity_after: Optional[int] = Field(default=None, ge=1, le=10)
    intervention_used: Optional[str] = None
    intervention_helped: Optional[bool] = None


class CravingEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    intensity_before: int
    intensity_after: Optional[int] = None
    trigger_category: Optional[str] = None
    feeling: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    intervention_used: Optional[str] = None
    intervention_helped: Optional[bool] = None
    created_at: datetime


class SmokingBaselineCreate(BaseModel):
    cigarettes_per_day: int
    cost_per_day: float


class SmokingBaselineResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    cigarettes_per_day: int
    cost_per_day: float
    recorded_at: datetime


class TriggerCategoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: Optional[str] = None
    is_default: bool


class UserTriggerCreate(BaseModel):
    trigger_category_id: int
    severity: Optional[int] = None
    notes: Optional[str] = None


class UserTriggerResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    trigger_category_id: int
    severity: Optional[int] = None
    notes: Optional[str] = None
    created_at: datetime
