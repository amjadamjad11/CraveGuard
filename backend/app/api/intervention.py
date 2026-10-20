from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.ai.intervention_engine import recommend_intervention, get_all_interventions
from app.models.intervention import InterventionHistory, InterventionFeedback
from sqlalchemy import select

router = APIRouter(prefix="/interventions", tags=["Interventions"])


@router.get("")
async def list_interventions(
    db: AsyncSession = Depends(get_db),
    _: User = Depends(get_current_user),
):
    interventions = await get_all_interventions(db)
    return [{"id": i.id, "name": i.name, "description": i.description,
             "category": i.category, "instructions": i.instructions,
             "duration_minutes": i.duration_minutes} for i in interventions]


@router.get("/recommend")
async def get_recommendation(
    trigger_category: str = None,
    craving_intensity: int = None,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await recommend_intervention(db, current_user.id, trigger_category, craving_intensity)
    return result


@router.post("/history")
async def record_intervention_use(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    history = InterventionHistory(
        user_id=current_user.id,
        intervention_id=data["intervention_id"],
        craving_event_id=data.get("craving_event_id"),
        trigger_category=data.get("trigger_category"),
        context=data.get("context"),
    )
    db.add(history)
    await db.commit()
    await db.refresh(history)
    return {"id": history.id, "message": "Intervention use recorded"}


@router.post("/feedback")
async def submit_feedback(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    feedback = InterventionFeedback(
        user_id=current_user.id,
        intervention_history_id=data["intervention_history_id"],
        was_helpful=data["was_helpful"],
        craving_before=data.get("craving_before"),
        craving_after=data.get("craving_after"),
        notes=data.get("notes"),
    )
    db.add(feedback)
    await db.commit()
    await db.refresh(feedback)
    return {"id": feedback.id, "message": "Feedback recorded — thank you!"}


@router.get("/history")
async def get_history(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(InterventionHistory).where(InterventionHistory.user_id == current_user.id)
        .order_by(InterventionHistory.created_at.desc()).limit(50)
    )
    items = result.scalars().all()
    return [{"id": h.id, "intervention_id": h.intervention_id,
             "trigger_category": h.trigger_category, "context": h.context,
             "created_at": h.created_at.isoformat()} for h in items]
