from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class NotificationPreferenceUpdate(BaseModel):
    location_reminders: Optional[bool] = None
    daily_checkins: Optional[bool] = None
    motivational_reminders: Optional[bool] = None
    milestone_alerts: Optional[bool] = None
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    max_daily_notifications: Optional[int] = None
    pause_all: Optional[bool] = None


class NotificationPreferenceResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    location_reminders: bool
    daily_checkins: bool
    motivational_reminders: bool
    milestone_alerts: bool
    quiet_hours_start: Optional[str] = None
    quiet_hours_end: Optional[str] = None
    max_daily_notifications: int
    pause_all: bool
    created_at: datetime
    updated_at: datetime
