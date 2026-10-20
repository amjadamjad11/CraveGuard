from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, ForeignKey, Text
from sqlalchemy.orm import relationship
from app.core.database import Base


class Intervention(Base):
    __tablename__ = "interventions"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, nullable=False)
    description = Column(Text, nullable=True)
    category = Column(String(50), nullable=True)
    instructions = Column(Text, nullable=True)
    duration_minutes = Column(Integer, default=5)
    is_default = Column(Boolean, default=True)


class InterventionHistory(Base):
    __tablename__ = "intervention_histories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    intervention_id = Column(Integer, ForeignKey("interventions.id"), nullable=False)
    craving_event_id = Column(Integer, ForeignKey("craving_events.id"), nullable=True)
    trigger_category = Column(String(100), nullable=True)
    context = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

    intervention = relationship("Intervention")


class InterventionFeedback(Base):
    __tablename__ = "intervention_feedbacks"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    intervention_history_id = Column(Integer, ForeignKey("intervention_histories.id"), nullable=False)
    was_helpful = Column(Boolean, nullable=False)
    craving_before = Column(Integer, nullable=True)
    craving_after = Column(Integer, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
