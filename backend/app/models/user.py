import enum
from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, Float, Enum, ForeignKey, Date
from sqlalchemy.orm import relationship
from app.core.database import Base


class SmokingGoalType(str, enum.Enum):
    QUIT = "quit"
    REDUCE = "reduce"
    UNDERSTAND = "understand"


class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    preferred_name = Column(String(100), default="Friend")
    age_confirmed = Column(Boolean, default=False)
    language = Column(String(10), default="en")
    timezone = Column(String(50), default="Asia/Kolkata")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    profile = relationship("UserProfile", back_populates="user", uselist=False, cascade="all, delete-orphan")
    smoking_events = relationship("SmokingEvent", back_populates="user", cascade="all, delete-orphan")
    craving_events = relationship("CravingEvent", back_populates="user", cascade="all, delete-orphan")
    risk_zones = relationship("LocationRiskZone", back_populates="user", cascade="all, delete-orphan")
    conversations = relationship("ChatConversation", back_populates="user", cascade="all, delete-orphan")
    savings_goals = relationship("SavingsGoal", back_populates="user", cascade="all, delete-orphan")


class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False)
    age_started_smoking = Column(Integer, nullable=True)
    cigarettes_per_day = Column(Integer, default=10)
    cigarettes_per_pack = Column(Integer, default=20)
    price_per_pack = Column(Float, default=250.0)
    currency = Column(String(10), default="INR")
    first_smoke_after_waking = Column(String(50), nullable=True)
    smoking_duration_years = Column(Integer, nullable=True)
    previous_quit_attempts = Column(Integer, default=0)
    previous_quit_experience = Column(String(500), nullable=True)
    current_goal = Column(Enum(SmokingGoalType), default=SmokingGoalType.REDUCE)
    target_quit_date = Column(Date, nullable=True)
    preferred_reminder_style = Column(String(50), default="gentle")
    onboarding_complete = Column(Boolean, default=False)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at = Column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    user = relationship("User", back_populates="profile")
