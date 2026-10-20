from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class InterventionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    name: str
    description: Optional[str] = None
    category: Optional[str] = None
    instructions: Optional[str] = None
    duration_minutes: Optional[int] = None
    is_default: bool


class InterventionRecommendation(BaseModel):
    intervention: InterventionResponse
    score: float
    reason: str


class InterventionFeedbackCreate(BaseModel):
    intervention_history_id: int
    was_helpful: bool
    craving_before: Optional[int] = None
    craving_after: Optional[int] = None
    notes: Optional[str] = None


class InterventionHistoryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    intervention_id: int
    craving_event_id: Optional[int] = None
    trigger_category: Optional[str] = None
    context: Optional[str] = None
    created_at: datetime
