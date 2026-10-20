from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional, List
from datetime import date

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.smoking import (
    SmokingEventCreate, SmokingEventResponse, CravingEventCreate,
    CravingEventUpdate, CravingEventResponse, SmokingBaselineCreate,
    SmokingBaselineResponse, TriggerCategoryResponse,
)
from app.services import smoking_service

router = APIRouter(prefix="/smoking", tags=["Smoking & Cravings"])


@router.post("/smoking-events", response_model=dict)
async def create_smoking_event(
    event_data: SmokingEventCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Record a new smoking event."""
    event = await smoking_service.create_smoking_event(db, current_user.id, event_data.model_dump(exclude_unset=True))
    return {"id": event.id, "cigarettes_count": event.cigarettes_count,
            "event_time": event.event_time.isoformat(), "mood": event.mood,
            "trigger_category": event.trigger_category, "craving_intensity": event.craving_intensity,
            "notes": event.notes, "created_at": event.created_at.isoformat()}


@router.get("/smoking-events")
async def get_smoking_events(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
):
    events = await smoking_service.get_smoking_events(db, current_user.id, start_date, end_date, limit, offset)
    return [{"id": e.id, "cigarettes_count": e.cigarettes_count, "event_time": e.event_time.isoformat(),
             "mood": e.mood, "trigger_category": e.trigger_category, "craving_intensity": e.craving_intensity,
             "social_context": e.social_context, "notes": e.notes, "latitude": e.latitude,
             "longitude": e.longitude, "created_at": e.created_at.isoformat()} for e in events]


@router.get("/today-count")
async def get_today_count(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    count = await smoking_service.get_today_smoking_count(db, current_user.id)
    return {"count": count}


@router.get("/weekly-data")
async def get_weekly_data(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    data = await smoking_service.get_weekly_smoking_data(db, current_user.id)
    return data


@router.post("/craving-events")
async def create_craving_event(
    event_data: CravingEventCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = await smoking_service.create_craving_event(db, current_user.id, event_data.model_dump(exclude_unset=True))
    return {"id": event.id, "intensity_before": event.intensity_before,
            "intensity_after": event.intensity_after, "trigger_category": event.trigger_category,
            "feeling": event.feeling, "intervention_used": event.intervention_used,
            "intervention_helped": event.intervention_helped, "created_at": event.created_at.isoformat()}


@router.get("/craving-events")
async def get_craving_events(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    events = await smoking_service.get_craving_events(db, current_user.id)
    return [{"id": e.id, "intensity_before": e.intensity_before, "intensity_after": e.intensity_after,
             "trigger_category": e.trigger_category, "feeling": e.feeling,
             "intervention_used": e.intervention_used, "intervention_helped": e.intervention_helped,
             "created_at": e.created_at.isoformat()} for e in events]


@router.patch("/craving-events/{event_id}")
async def update_craving_event(
    event_id: int,
    data: CravingEventUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = await smoking_service.update_craving_event(db, current_user.id, event_id, data.model_dump(exclude_unset=True))
    if not event:
        raise HTTPException(status_code=404, detail="Craving event not found")
    return {"id": event.id, "intensity_before": event.intensity_before,
            "intensity_after": event.intensity_after, "intervention_helped": event.intervention_helped}


@router.get("/triggers")
async def get_triggers(db: AsyncSession = Depends(get_db), _: User = Depends(get_current_user)):
    cats = await smoking_service.get_trigger_categories(db)
    return [{"id": c.id, "name": c.name, "description": c.description, "is_default": c.is_default} for c in cats]


@router.get("/top-triggers")
async def get_top_triggers(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await smoking_service.get_top_triggers(db, current_user.id)


@router.get("/smoking-baseline")
async def get_baseline(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    baseline = await smoking_service.get_baseline(db, current_user.id)
    if not baseline:
        raise HTTPException(status_code=404, detail="No baseline set")
    return {"id": baseline.id, "cigarettes_per_day": baseline.cigarettes_per_day,
            "cost_per_day": baseline.cost_per_day, "recorded_at": baseline.recorded_at.isoformat()}


@router.post("/smoking-baseline")
async def create_baseline(
    data: SmokingBaselineCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    baseline = await smoking_service.get_or_create_baseline(
        db, current_user.id, data.cigarettes_per_day, data.cost_per_day
    )
    return {"id": baseline.id, "cigarettes_per_day": baseline.cigarettes_per_day,
            "cost_per_day": baseline.cost_per_day}
