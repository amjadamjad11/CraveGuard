"""Adaptive intervention recommendation engine."""
import random
from datetime import datetime, timedelta, timezone
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from app.models.intervention import Intervention, InterventionHistory, InterventionFeedback


# Ranking weights
WEIGHTS = {
    "user_preference": 0.3,
    "past_helpful": 0.3,
    "trigger_match": 0.2,
    "recency_cooldown": 0.1,
    "intensity_match": 0.1,
}

COOLDOWN_MINUTES = 30
EXPLORE_RATE = 0.2  # 20% chance of suggesting something new


async def get_all_interventions(db: AsyncSession) -> List[Intervention]:
    result = await db.execute(select(Intervention).order_by(Intervention.name))
    return list(result.scalars().all())


async def recommend_intervention(
    db: AsyncSession,
    user_id: int,
    trigger_category: Optional[str] = None,
    craving_intensity: Optional[int] = None,
) -> dict:
    """Recommend the best intervention based on user history and context."""
    interventions = await get_all_interventions(db)
    if not interventions:
        return {"intervention": None, "reason": "No interventions available"}

    # Explore: sometimes suggest a random one
    if random.random() < EXPLORE_RATE:
        chosen = random.choice(interventions)
        return {
            "intervention": _to_dict(chosen),
            "reason": "Trying something different today — variety can help discover what works best for you.",
        }

    # Get feedback history for this user
    scores = {}
    for intervention in interventions:
        score = await _score_intervention(
            db, user_id, intervention,
            trigger_category, craving_intensity
        )
        scores[intervention.id] = (intervention, score)

    # Sort by score descending
    ranked = sorted(scores.values(), key=lambda x: x[1]["total"], reverse=True)
    chosen_intervention, score_data = ranked[0]

    return {
        "intervention": _to_dict(chosen_intervention),
        "reason": score_data["explanation"],
        "score": score_data["total"],
    }


async def _score_intervention(
    db: AsyncSession,
    user_id: int,
    intervention: Intervention,
    trigger_category: Optional[str],
    craving_intensity: Optional[int],
) -> dict:
    """Score a single intervention for a user."""

    # 1. Past helpfulness
    result = await db.execute(
        select(func.count(InterventionFeedback.id))
        .join(InterventionHistory)
        .where(and_(
            InterventionHistory.user_id == user_id,
            InterventionHistory.intervention_id == intervention.id,
            InterventionFeedback.was_helpful == True,
        ))
    )
    helpful_count = result.scalar() or 0

    result = await db.execute(
        select(func.count(InterventionFeedback.id))
        .join(InterventionHistory)
        .where(and_(
            InterventionHistory.user_id == user_id,
            InterventionHistory.intervention_id == intervention.id,
            InterventionFeedback.was_helpful == False,
        ))
    )
    unhelpful_count = result.scalar() or 0

    total_feedback = helpful_count + unhelpful_count
    helpful_ratio = helpful_count / max(1, total_feedback)

    # Penalize heavily if mostly unhelpful
    if unhelpful_count >= 3 and helpful_ratio < 0.3:
        helpful_score = -0.5
    else:
        helpful_score = helpful_ratio

    # 2. Trigger match
    trigger_score = 0.5  # Default neutral
    if trigger_category:
        result = await db.execute(
            select(func.count(InterventionHistory.id))
            .where(and_(
                InterventionHistory.user_id == user_id,
                InterventionHistory.intervention_id == intervention.id,
                InterventionHistory.trigger_category == trigger_category,
            ))
        )
        trigger_uses = result.scalar() or 0
        if trigger_uses > 0:
            # Check if it was helpful for this trigger
            result = await db.execute(
                select(func.count(InterventionFeedback.id))
                .join(InterventionHistory)
                .where(and_(
                    InterventionHistory.user_id == user_id,
                    InterventionHistory.intervention_id == intervention.id,
                    InterventionHistory.trigger_category == trigger_category,
                    InterventionFeedback.was_helpful == True,
                ))
            )
            trigger_helpful = result.scalar() or 0
            trigger_score = trigger_helpful / max(1, trigger_uses)

    # 3. Recency/cooldown
    result = await db.execute(
        select(InterventionHistory.created_at)
        .where(and_(
            InterventionHistory.user_id == user_id,
            InterventionHistory.intervention_id == intervention.id,
        ))
        .order_by(InterventionHistory.created_at.desc())
        .limit(1)
    )
    last_used = result.scalar_one_or_none()
    recency_score = 1.0
    if last_used:
        minutes_ago = (datetime.now(timezone.utc) - last_used.replace(tzinfo=timezone.utc)).total_seconds() / 60
        if minutes_ago < COOLDOWN_MINUTES:
            recency_score = 0.1  # Heavy penalty for recent use
        elif minutes_ago < 120:
            recency_score = 0.6

    # 4. Intensity match — breathing/grounding better for high intensity
    intensity_score = 0.5
    if craving_intensity and craving_intensity >= 7:
        if intervention.category in ("breathing", "grounding", "contact"):
            intensity_score = 1.0
    elif craving_intensity and craving_intensity <= 3:
        if intervention.category in ("distraction", "activity"):
            intensity_score = 1.0

    # Calculate total
    total = (
        WEIGHTS["past_helpful"] * helpful_score
        + WEIGHTS["trigger_match"] * trigger_score
        + WEIGHTS["recency_cooldown"] * recency_score
        + WEIGHTS["intensity_match"] * intensity_score
    )

    # Build explanation
    explanations = []
    if helpful_count > 0:
        explanations.append(f"you've found this helpful {helpful_count} time(s) before")
    if trigger_category and trigger_score > 0.5:
        explanations.append(f"it has worked well for '{trigger_category}' triggers")
    if craving_intensity and intensity_score > 0.7:
        explanations.append(f"it's well-suited for your current craving level")

    explanation = f"This {intervention.name.lower()} is suggested because " + (
        ", ".join(explanations) + "." if explanations else "it's a good general coping strategy."
    )

    return {"total": round(total, 3), "explanation": explanation}


def _to_dict(intervention: Intervention) -> dict:
    return {
        "id": intervention.id,
        "name": intervention.name,
        "description": intervention.description,
        "category": intervention.category,
        "instructions": intervention.instructions,
        "duration_minutes": intervention.duration_minutes,
    }
