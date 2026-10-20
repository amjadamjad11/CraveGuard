from datetime import datetime, date, timezone, timedelta
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.models.smoking import SmokingEvent, CravingEvent, SmokingBaseline, TriggerCategory, UserTrigger


async def create_smoking_event(db: AsyncSession, user_id: int, data: dict) -> SmokingEvent:
    event = SmokingEvent(user_id=user_id, **data)
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return event


async def get_smoking_events(
    db: AsyncSession, user_id: int,
    start_date: Optional[date] = None, end_date: Optional[date] = None,
    limit: int = 50, offset: int = 0
) -> List[SmokingEvent]:
    query = select(SmokingEvent).where(SmokingEvent.user_id == user_id)
    if start_date:
        query = query.where(SmokingEvent.event_time >= datetime.combine(start_date, datetime.min.time()))
    if end_date:
        query = query.where(SmokingEvent.event_time <= datetime.combine(end_date, datetime.max.time()))
    query = query.order_by(SmokingEvent.event_time.desc()).limit(limit).offset(offset)
    result = await db.execute(query)
    return list(result.scalars().all())


async def get_today_smoking_count(db: AsyncSession, user_id: int) -> int:
    today_start = datetime.combine(date.today(), datetime.min.time())
    result = await db.execute(
        select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
        .where(and_(SmokingEvent.user_id == user_id, SmokingEvent.event_time >= today_start))
    )
    return result.scalar() or 0


async def get_weekly_smoking_data(db: AsyncSession, user_id: int) -> list:
    """Get smoking counts for the past 7 days."""
    data = []
    for i in range(6, -1, -1):
        d = date.today() - timedelta(days=i)
        day_start = datetime.combine(d, datetime.min.time())
        day_end = datetime.combine(d, datetime.max.time())
        result = await db.execute(
            select(func.coalesce(func.sum(SmokingEvent.cigarettes_count), 0))
            .where(and_(
                SmokingEvent.user_id == user_id,
                SmokingEvent.event_time >= day_start,
                SmokingEvent.event_time <= day_end,
            ))
        )
        count = result.scalar() or 0
        data.append({"date": d.isoformat(), "count": count})
    return data


async def create_craving_event(db: AsyncSession, user_id: int, data: dict) -> CravingEvent:
    event = CravingEvent(user_id=user_id, **data)
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return event


async def update_craving_event(db: AsyncSession, user_id: int, event_id: int, data: dict) -> Optional[CravingEvent]:
    result = await db.execute(
        select(CravingEvent).where(and_(CravingEvent.id == event_id, CravingEvent.user_id == user_id))
    )
    event = result.scalar_one_or_none()
    if not event:
        return None
    for key, value in data.items():
        if value is not None:
            setattr(event, key, value)
    await db.commit()
    await db.refresh(event)
    return event


async def get_craving_events(db: AsyncSession, user_id: int, limit: int = 50) -> List[CravingEvent]:
    result = await db.execute(
        select(CravingEvent).where(CravingEvent.user_id == user_id)
        .order_by(CravingEvent.created_at.desc()).limit(limit)
    )
    return list(result.scalars().all())


async def get_or_create_baseline(db: AsyncSession, user_id: int, cigs_per_day: int, cost_per_day: float) -> SmokingBaseline:
    result = await db.execute(
        select(SmokingBaseline).where(SmokingBaseline.user_id == user_id)
        .order_by(SmokingBaseline.recorded_at.desc())
    )
    baseline = result.scalar_one_or_none()
    if not baseline:
        baseline = SmokingBaseline(user_id=user_id, cigarettes_per_day=cigs_per_day, cost_per_day=cost_per_day)
        db.add(baseline)
        await db.commit()
        await db.refresh(baseline)
    return baseline


async def get_baseline(db: AsyncSession, user_id: int) -> Optional[SmokingBaseline]:
    result = await db.execute(
        select(SmokingBaseline).where(SmokingBaseline.user_id == user_id)
        .order_by(SmokingBaseline.recorded_at.desc())
    )
    return result.scalar_one_or_none()


async def get_trigger_categories(db: AsyncSession) -> List[TriggerCategory]:
    result = await db.execute(select(TriggerCategory).order_by(TriggerCategory.name))
    return list(result.scalars().all())


async def get_top_triggers(db: AsyncSession, user_id: int, days: int = 30) -> list:
    """Get most common triggers over recent period."""
    since = datetime.now(timezone.utc) - timedelta(days=days)
    result = await db.execute(
        select(SmokingEvent.trigger_category, func.count(SmokingEvent.id).label("count"))
        .where(and_(
            SmokingEvent.user_id == user_id,
            SmokingEvent.created_at >= since,
            SmokingEvent.trigger_category.isnot(None),
        ))
        .group_by(SmokingEvent.trigger_category)
        .order_by(func.count(SmokingEvent.id).desc())
        .limit(5)
    )
    return [{"trigger": row[0], "count": row[1]} for row in result.all()]
