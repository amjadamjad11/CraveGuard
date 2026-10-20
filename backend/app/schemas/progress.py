from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import date, datetime


class DailyProgressResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    date: date
    cigarettes_smoked: int
    cravings_count: int
    cravings_resisted: int
    avg_craving_intensity: Optional[float] = None
    money_saved_estimate: float
    top_trigger: Optional[str] = None
    created_at: datetime


class WeeklyProgressResponse(BaseModel):
    total_cigarettes: int
    total_cravings: int
    total_resisted: int
    avg_daily_cigarettes: float
    avg_craving_intensity: Optional[float] = None
    total_money_saved: float
    top_triggers: list[str]
    daily_summaries: list[DailyProgressResponse]
    trend: str  # 'improving', 'stable', 'needs_attention'


class SavingsResponse(BaseModel):
    total_saved: float
    daily_savings_rate: float
    currency: str
    baseline_daily_cost: float
    current_daily_cost: float
    days_tracked: int


class SavingsGoalCreate(BaseModel):
    title: str
    target_amount: float
    icon: Optional[str] = None
    target_date: Optional[date] = None


class SavingsGoalUpdate(BaseModel):
    title: Optional[str] = None
    target_amount: Optional[float] = None
    current_amount: Optional[float] = None
    icon: Optional[str] = None
    is_completed: Optional[bool] = None
    target_date: Optional[date] = None


class SavingsGoalResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    title: str
    target_amount: float
    current_amount: float
    icon: Optional[str] = None
    is_completed: bool
    target_date: Optional[date] = None
    created_at: datetime
    updated_at: datetime


class MilestoneResponse(BaseModel):
    name: str
    description: str
    achieved: bool
    achieved_at: Optional[datetime] = None
    progress_percent: float
