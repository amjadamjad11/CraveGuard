"""Profile service — handles user profile, survey, quit reasons, and onboarding completion."""
import json
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, delete
from app.models.user import UserProfile
from app.models.consent import SurveyResponse
from app.models.motivation import QuitReason
from app.models.smoking import SmokingBaseline


async def get_profile(db: AsyncSession, user_id: int) -> Optional[UserProfile]:
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    return result.scalar_one_or_none()


async def update_profile(db: AsyncSession, user_id: int, data: dict) -> UserProfile:
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = UserProfile(user_id=user_id)
        db.add(profile)
    for key, value in data.items():
        if value is not None and hasattr(profile, key) and key not in ("id", "user_id"):
            setattr(profile, key, value)
    await db.commit()
    await db.refresh(profile)
    return profile


async def complete_onboarding(db: AsyncSession, user_id: int, payload: dict) -> dict:
    """Save all onboarding answers atomically and mark onboarding as complete.

    Expected payload keys (all optional except cigarettes_per_day):
      preferred_name, cigarettes_per_day, cigarettes_per_pack, price_per_pack,
      currency, first_smoke_after_waking, current_goal, triggers (list[str]),
      quit_reasons (list[str]), personal_reason_text
    """
    # 1. Update profile fields
    profile_fields = {
        "cigarettes_per_day": payload.get("cigarettes_per_day"),
        "cigarettes_per_pack": payload.get("cigarettes_per_pack"),
        "price_per_pack": payload.get("price_per_pack"),
        "currency": payload.get("currency", "INR"),
        "first_smoke_after_waking": payload.get("first_smoke_after_waking"),
        "current_goal": payload.get("current_goal"),
        "onboarding_complete": True,
    }
    result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
    profile = result.scalar_one_or_none()
    if not profile:
        profile = UserProfile(user_id=user_id)
        db.add(profile)
    for key, value in profile_fields.items():
        if value is not None and hasattr(profile, key):
            setattr(profile, key, value)
        elif key == "onboarding_complete":
            profile.onboarding_complete = True

    # 2. Create SmokingBaseline from onboarding data
    cigs = payload.get("cigarettes_per_day", 10)
    pack_price = payload.get("price_per_pack", 250.0)
    cigs_per_pack = payload.get("cigarettes_per_pack", 20)
    cost_per_day = (cigs / cigs_per_pack) * pack_price
    baseline = SmokingBaseline(
        user_id=user_id,
        cigarettes_per_day=cigs,
        cost_per_day=round(cost_per_day, 2),
    )
    db.add(baseline)

    # 3. Save quit reasons (replace existing)
    await db.execute(delete(QuitReason).where(QuitReason.user_id == user_id))
    for idx, reason in enumerate(payload.get("quit_reasons", []), start=1):
        db.add(QuitReason(user_id=user_id, reason_category=reason, priority_rank=idx))

    # 4. Save selected triggers as a survey response
    triggers = payload.get("triggers", [])
    if triggers:
        await save_survey_response(db, user_id, "selected_triggers", json.dumps(triggers))

    # 5. Save personal reason text if provided
    personal_reason = payload.get("personal_reason_text", "")
    if personal_reason:
        await save_survey_response(db, user_id, "personal_reason", json.dumps(personal_reason))

    await db.commit()
    return {"success": True, "message": "Onboarding complete"}


async def save_survey_response(
    db: AsyncSession, user_id: int, question_key: str, response_json: str
) -> SurveyResponse:
    result = await db.execute(
        select(SurveyResponse).where(
            SurveyResponse.user_id == user_id,
            SurveyResponse.question_key == question_key,
        )
    )
    existing = result.scalar_one_or_none()
    if existing:
        existing.response_json = response_json
        await db.commit()
        await db.refresh(existing)
        return existing
    sr = SurveyResponse(user_id=user_id, question_key=question_key, response_json=response_json)
    db.add(sr)
    await db.commit()
    await db.refresh(sr)
    return sr


async def get_survey_responses(db: AsyncSession, user_id: int) -> List[SurveyResponse]:
    result = await db.execute(
        select(SurveyResponse).where(SurveyResponse.user_id == user_id)
    )
    return list(result.scalars().all())


async def add_quit_reason(db: AsyncSession, user_id: int, data: dict) -> QuitReason:
    reason = QuitReason(user_id=user_id, **data)
    db.add(reason)
    await db.commit()
    await db.refresh(reason)
    return reason


async def get_quit_reasons(db: AsyncSession, user_id: int) -> List[QuitReason]:
    result = await db.execute(
        select(QuitReason).where(QuitReason.user_id == user_id).order_by(QuitReason.priority_rank)
    )
    return list(result.scalars().all())
