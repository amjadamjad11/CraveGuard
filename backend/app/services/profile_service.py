from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.models.user import UserProfile
from app.models.consent import SurveyResponse
from app.models.motivation import QuitReason


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
        if value is not None and hasattr(profile, key):
            setattr(profile, key, value)
    await db.commit()
    await db.refresh(profile)
    return profile


async def save_survey_response(db: AsyncSession, user_id: int, question_key: str, response_json: str) -> SurveyResponse:
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
