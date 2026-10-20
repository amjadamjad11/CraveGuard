import enum
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text, Enum
from sqlalchemy.orm import relationship
from app.core.database import Base


class RiskLevel(str, enum.Enum):
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class LocationRiskZone(Base):
    __tablename__ = "location_risk_zones"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(200), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    radius_meters = Column(Float, default=100.0)
    risk_level = Column(Enum(RiskLevel), default=RiskLevel.MEDIUM)
    trigger_reason = Column(Text, nullable=True)
    is_user_confirmed = Column(Boolean, default=False)
    is_active = Column(Boolean, default=True)
    interventions_json = Column(Text, nullable=True)
    cooldown_minutes = Column(Integer, default=60)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="risk_zones")
    geofence_events = relationship("GeofenceEvent", back_populates="risk_zone", cascade="all, delete-orphan")


class LocationVisitSummary(Base):
    __tablename__ = "location_visit_summaries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    cluster_latitude = Column(Float, nullable=False)
    cluster_longitude = Column(Float, nullable=False)
    visit_count = Column(Integer, default=0)
    smoking_events_nearby = Column(Integer, default=0)
    craving_events_nearby = Column(Integer, default=0)
    avg_craving_intensity = Column(Float, default=0.0)
    risk_score = Column(Float, default=0.0)
    last_visited = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class GeofenceEvent(Base):
    __tablename__ = "geofence_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    risk_zone_id = Column(Integer, ForeignKey("location_risk_zones.id", ondelete="CASCADE"), nullable=False)
    event_type = Column(String(20), nullable=False)  # entry or exit
    notification_sent = Column(Boolean, default=False)
    notification_opened = Column(Boolean, default=False)
    intervention_shown = Column(String(100), nullable=True)
    feedback = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    risk_zone = relationship("LocationRiskZone", back_populates="geofence_events")
