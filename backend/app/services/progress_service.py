from datetime import datetime, date, timezone, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.models.smoking import SmokingEvent, CravingEvent
from app.models.user import UserProfile
from app.models.smoking import SmokingBaseline
from app.models.progress import DailyProgressSummary, SavingsGoal


async def get_savings_data(db: AsyncSession, user_id: int) -> dict:
    """Calculate savings based on baseline vs actual smoking."""
    profile = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = profile.scalar_one_or_none()
    if not profile:
        return {"daily_savings": 0, "weekly_savings": 0, "monthly_savings": 0, "total_savings": 0,
                "yearly_projection": 0, "cigarettes_avoided": 0, "currency": "INR"}

    baseline = await db.execute(
        select(SmokingBaseline).where(SmokingBaseline.user_id == user_id)
        .order_by(SmokingBaseline.recorded_at.desc())
    )
    baseline = baseline.scalar_one_or_none()

    cigs_per_pack = profile.cigarettes_per_pack or 20
    price_per_pack = profile.price_per_pack or 250.0
    price_per_cig = price_per_pack / cigs_per_pack
    baseline_cigs = baseline.cigarettes_per_day if baseline else profile.cigarettes_per_day or 10
    baseline_daily_cost = baseline_cigs * price_per_cig

    # Get today's actual count
    today_start = datetime.combine(date.today(), datetime.min.time())
    result = await db.execute(
        select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
        .where(and_(SmokingEvent.user_id == user_id, SmokingEvent.event_time >= today_start))
    )
    today_cigs = result.scalar() or 0
    today_cost = today_cigs * price_per_cig
    daily_savings = max(0, baseline_daily_cost - today_cost)

    # Weekly
    week_start = datetime.combine(date.today() - timedelta(days=6), datetime.min.time())
    result = await db.execute(
        select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
        .where(and_(SmokingEvent.user_id == user_id, SmokingEvent.event_time >= week_start))
    )
    week_cigs = result.scalar() or 0
    week_baseline = baseline_cigs * 7
    weekly_savings = max(0, (week_baseline - week_cigs) * price_per_cig)

    # Monthly (30 days)
    month_start = datetime.combine(date.today() - timedelta(days=29), datetime.min.time())
    result = await db.execute(
        select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
        .where(and_(SmokingEvent.user_id == user_id, SmokingEvent.event_time >= month_start))
    )
    month_cigs = result.scalar() or 0
    month_baseline = baseline_cigs * 30
    monthly_savings = max(0, (month_baseline - month_cigs) * price_per_cig)

    # Total (all time since first event)
    first_event = await db.execute(
        select(SmokingEvent.event_time).where(SmokingEvent.user_id == user_id)
        .order_by(SmokingEvent.event_time.asc()).limit(1)
    )
    first_event_time = first_event.scalar_one_or_none()
    if not first_event_time:
        return {
            'daily_savings': 0.0,
            'weekly_savings': 0.0,
            'monthly_savings': 0.0,
            'total_savings': 0.0,
            'yearly_projection': 0.0,
            'cigarettes_avoided': 0,
            'baseline_daily_cost': round(baseline_daily_cost, 2),
            'current_daily_cost': 0.0,
            'currency': profile.currency or 'INR',
        }
    total_days = max(1, (date.today() - (first_event_time.date() if first_event_time else date.today())).days)

    result = await db.execute(
        select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
        .where(SmokingEvent.user_id == user_id)
    )
    total_cigs = result.scalar() or 0
    total_baseline_cigs = baseline_cigs * total_days
    total_savings = max(0, (total_baseline_cigs - total_cigs) * price_per_cig)
    cigarettes_avoided = max(0, total_baseline_cigs - total_cigs)

    # If no cigarettes were avoided, savings must be 0
    if cigarettes_avoided == 0:
        return {
            "daily_savings": 0.0,
            "weekly_savings": 0.0,
            "monthly_savings": 0.0,
            "total_savings": 0.0,
            "yearly_projection": 0.0,
            "cigarettes_avoided": 0,
            "baseline_daily_cost": round(baseline_daily_cost, 2),
            "current_daily_cost": round(today_cost, 2),
            "currency": profile.currency or "INR",
        }

    # Yearly projection based on current daily average
    daily_avg = total_cigs / total_days if total_days > 0 else baseline_cigs
    yearly_savings = max(0, (baseline_cigs - daily_avg) * price_per_cig * 365)

    return {
        "daily_savings": round(daily_savings, 2),
        "weekly_savings": round(weekly_savings, 2),
        "monthly_savings": round(monthly_savings, 2),
        "total_savings": round(total_savings, 2),
        "yearly_projection": round(yearly_savings, 2),
        "cigarettes_avoided": cigarettes_avoided,
        "baseline_daily_cost": round(baseline_daily_cost, 2),
        "current_daily_cost": round(today_cost, 2),
        "currency": profile.currency or "INR",
    }


async def get_daily_summary(db: AsyncSession, user_id: int, for_date: Optional[date] = None) -> dict:
    """Get daily progress summary."""
    target_date = for_date or date.today()
    day_start = datetime.combine(target_date, datetime.min.time())
    day_end = datetime.combine(target_date, datetime.max.time())

    # Smoking count
    result = await db.execute(
        select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
        .where(and_(SmokingEvent.user_id == user_id, SmokingEvent.event_time >= day_start, SmokingEvent.event_time <= day_end))
    )
    cigarettes = result.scalar() or 0

    # Craving count
    result = await db.execute(
        select(func.count(CravingEvent.id))
        .where(and_(CravingEvent.user_id == user_id, CravingEvent.created_at >= day_start, CravingEvent.created_at <= day_end))
    )
    cravings = result.scalar() or 0

    # Cravings resisted (where intensity_after < intensity_before)
    result = await db.execute(
        select(func.count(CravingEvent.id))
        .where(and_(
            CravingEvent.user_id == user_id,
            CravingEvent.created_at >= day_start, CravingEvent.created_at <= day_end,
            CravingEvent.intervention_helped == True,
        ))
    )
    resisted = result.scalar() or 0

    # Average craving intensity
    result = await db.execute(
        select(func.avg(CravingEvent.intensity_before))
        .where(and_(CravingEvent.user_id == user_id, CravingEvent.created_at >= day_start, CravingEvent.created_at <= day_end))
    )
    avg_intensity = result.scalar() or 0

    return {
        "date": target_date.isoformat(),
        "cigarettes_smoked": cigarettes,
        "cravings_count": cravings,
        "cravings_resisted": resisted,
        "avg_craving_intensity": round(float(avg_intensity), 1),
    }


async def get_weekly_summary(db: AsyncSession, user_id: int) -> dict:
    """Get weekly progress summary with daily breakdown."""
    days = []
    total_cigs = 0
    total_cravings = 0
    for i in range(6, -1, -1):
        d = date.today() - timedelta(days=i)
        daily = await get_daily_summary(db, user_id, d)
        days.append(daily)
        total_cigs += daily["cigarettes_smoked"]
        total_cravings += daily["cravings_count"]

    return {
        "days": days,
        "total_cigarettes": total_cigs,
        "total_cravings": total_cravings,
        "daily_average": round(total_cigs / 7, 1),
    }


async def get_milestones(db: AsyncSession, user_id: int) -> list:
    """Generate milestones based on progress."""
    milestones = []

    # Count total events
    result = await db.execute(
        select(func.count(SmokingEvent.id)).where(SmokingEvent.user_id == user_id)
    )
    total_events = result.scalar() or 0

    result = await db.execute(
        select(func.count(CravingEvent.id)).where(
            and_(CravingEvent.user_id == user_id, CravingEvent.intervention_helped == True)
        )
    )
    resisted = result.scalar() or 0

    if total_events > 0:
        milestones.append({"title": "First Step", "description": "Started tracking your smoking", "achieved": True, "icon": "star"})
    if resisted >= 1:
        milestones.append({"title": "First Victory", "description": "Resisted your first craving", "achieved": True, "icon": "trophy"})
    if resisted >= 5:
        milestones.append({"title": "Getting Stronger", "description": "Resisted 5 cravings", "achieved": True, "icon": "muscle"})
    if resisted >= 10:
        milestones.append({"title": "Double Digits", "description": "Resisted 10 cravings", "achieved": True, "icon": "fire"})
    else:
        milestones.append({"title": "Double Digits", "description": "Resist 10 cravings", "achieved": False, "icon": "fire"})
    if resisted >= 25:
        milestones.append({"title": "Quarter Century", "description": "Resisted 25 cravings", "achieved": True, "icon": "medal"})
    else:
        milestones.append({"title": "Quarter Century", "description": "Resist 25 cravings", "achieved": False, "icon": "medal"})

    return milestones


