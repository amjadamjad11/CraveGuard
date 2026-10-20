from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class LocationRiskZoneCreate(BaseModel):
    name: str
    latitude: float
    longitude: float
    radius_meters: float = 100.0
    risk_level: str = "medium"  # high/medium/low
    trigger_reason: Optional[str] = None
    interventions_json: Optional[str] = None
    cooldown_minutes: int = 30


class LocationRiskZoneUpdate(BaseModel):
    name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    radius_meters: Optional[float] = None
    risk_level: Optional[str] = None
    trigger_reason: Optional[str] = None
    interventions_json: Optional[str] = None
    cooldown_minutes: Optional[int] = None
    is_active: Optional[bool] = None


class LocationRiskZoneResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    name: str
    latitude: float
    longitude: float
    radius_meters: float
    risk_level: str
    trigger_reason: Optional[str] = None
    interventions_json: Optional[str] = None
    cooldown_minutes: int
    is_user_confirmed: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime


class LocationVisitSummaryResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: Optional[int] = None
    risk_zone_id: Optional[int] = None
    visit_count: Optional[int] = None
    total_smoking_events: Optional[int] = None
    total_craving_events: Optional[int] = None
    avg_craving_intensity: Optional[float] = None
    last_visited_at: Optional[datetime] = None


class GeofenceEventCreate(BaseModel):
    risk_zone_id: int
    event_type: str  # 'entry' or 'exit'
    notification_sent: bool = False
    intervention_shown: Optional[str] = None


class GeofenceEventResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    risk_zone_id: int
    event_type: str
    notification_sent: bool
    intervention_shown: Optional[str] = None
    created_at: datetime


class RiskCandidateResponse(BaseModel):
    cluster_latitude: float
    cluster_longitude: float
    risk_score: float
    smoking_events_nearby: int
    craving_events_nearby: int
    visit_count: int
    avg_craving_intensity: Optional[float] = None
    explanation: str
