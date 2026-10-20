from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.notification import NotificationPreference

router = APIRouter(prefix="/notifications", tags=["Notifications"])


@router.get("/preferences")
async def get_preferences(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == current_user.id)
    )
    pref = result.scalar_one_or_none()
    if not pref:
        pref = NotificationPreference(user_id=current_user.id)
        db.add(pref)
        await db.commit()
        await db.refresh(pref)
    return {
        "location_reminders": pref.location_reminders,
        "daily_checkins": pref.daily_checkins,
        "motivational_reminders": pref.motivational_reminders,
        "milestone_alerts": pref.milestone_alerts,
        "quiet_hours_start": pref.quiet_hours_start,
        "quiet_hours_end": pref.quiet_hours_end,
        "max_daily_notifications": pref.max_daily_notifications,
        "pause_all": pref.pause_all,
    }


@router.put("/preferences")
async def update_preferences(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(NotificationPreference).where(NotificationPreference.user_id == current_user.id)
    )
    pref = result.scalar_one_or_none()
    if not pref:
        pref = NotificationPreference(user_id=current_user.id)
        db.add(pref)
    for k, v in data.items():
        if hasattr(pref, k) and k not in ("id", "user_id"):
            setattr(pref, k, v)
    await db.commit()
    return {"message": "Notification preferences updated"}
