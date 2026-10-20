from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.services import profile_service

router = APIRouter(prefix="/profile", tags=["Profile & Survey"])


@router.get("")
async def get_profile(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await profile_service.get_profile(db, current_user.id)
    if not profile:
        return {}
    return {
        "id": profile.id, "user_id": profile.user_id,
        "age_started_smoking": profile.age_started_smoking,
        "cigarettes_per_day": profile.cigarettes_per_day,
        "cigarettes_per_pack": profile.cigarettes_per_pack,
        "price_per_pack": profile.price_per_pack,
        "currency": profile.currency,
        "first_smoke_after_waking": profile.first_smoke_after_waking,
        "smoking_duration_years": profile.smoking_duration_years,
        "previous_quit_attempts": profile.previous_quit_attempts,
        "previous_quit_experience": profile.previous_quit_experience,
        "current_goal": profile.current_goal.value if profile.current_goal else None,
        "target_quit_date": profile.target_quit_date.isoformat() if profile.target_quit_date else None,
        "preferred_reminder_style": profile.preferred_reminder_style,
    }


@router.put("")
async def update_profile(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await profile_service.update_profile(db, current_user.id, data)
    return {"message": "Profile updated", "id": profile.id}


@router.post("/survey-responses")
async def save_survey(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    import json
    sr = await profile_service.save_survey_response(
        db, current_user.id, data["question_key"], json.dumps(data.get("response", ""))
    )
    return {"id": sr.id, "question_key": sr.question_key}


@router.get("/survey-responses")
async def get_surveys(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    import json
    responses = await profile_service.get_survey_responses(db, current_user.id)
    return [{"id": r.id, "question_key": r.question_key,
             "response": json.loads(r.response_json) if r.response_json else None} for r in responses]


@router.post("/quit-reasons")
async def add_quit_reason(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reason = await profile_service.add_quit_reason(db, current_user.id, data)
    return {"id": reason.id, "reason_category": reason.reason_category,
            "priority_rank": reason.priority_rank, "custom_text": reason.custom_text}


@router.get("/quit-reasons")
async def get_quit_reasons(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    reasons = await profile_service.get_quit_reasons(db, current_user.id)
    return [{"id": r.id, "reason_category": r.reason_category,
             "priority_rank": r.priority_rank, "custom_text": r.custom_text} for r in reasons]
