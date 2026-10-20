from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class SmokingBaseline(Base):
    __tablename__ = "smoking_baselines"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    cigarettes_per_day = Column(Integer, nullable=False)
    cost_per_day = Column(Float, nullable=False)
    recorded_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SmokingEvent(Base):
    __tablename__ = "smoking_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    cigarettes_count = Column(Integer, default=1)
    event_time = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    mood = Column(String(50), nullable=True)
    trigger_category = Column(String(100), nullable=True)
    craving_intensity = Column(Integer, nullable=True)
    social_context = Column(String(200), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="smoking_events")


class CravingEvent(Base):
    __tablename__ = "craving_events"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    intensity_before = Column(Integer, nullable=False)
    intensity_after = Column(Integer, nullable=True)
    trigger_category = Column(String(100), nullable=True)
    feeling = Column(String(100), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    intervention_used = Column(String(100), nullable=True)
    intervention_helped = Column(Boolean, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="craving_events")


class TriggerCategory(Base):
    __tablename__ = "trigger_categories"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(String(500), nullable=True)
    is_default = Column(Boolean, default=True)


class UserTrigger(Base):
    __tablename__ = "user_triggers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    trigger_category_id = Column(Integer, ForeignKey("trigger_categories.id"), nullable=False)
    severity = Column(Integer, default=5)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    trigger_category = relationship("TriggerCategory")
