from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Float, DateTime, Date, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base


class DailyProgressSummary(Base):
    __tablename__ = "daily_progress_summaries"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    date = Column(Date, nullable=False)
    cigarettes_smoked = Column(Integer, default=0)
    cravings_count = Column(Integer, default=0)
    cravings_resisted = Column(Integer, default=0)
    avg_craving_intensity = Column(Float, default=0.0)
    money_saved_estimate = Column(Float, default=0.0)
    top_trigger = Column(String(100), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SavingsGoal(Base):
    __tablename__ = "savings_goals"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    title = Column(String(200), nullable=False)
    target_amount = Column(Float, nullable=False)
    current_amount = Column(Float, default=0.0)
    icon = Column(String(50), default="savings")
    is_completed = Column(Boolean, default=False)
    target_date = Column(Date, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="savings_goals")
