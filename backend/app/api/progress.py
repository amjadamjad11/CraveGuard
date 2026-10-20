from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.services import progress_service
from app.models.progress import SavingsGoal
from app.schemas.progress import SavingsGoalCreate, SavingsGoalUpdate
from sqlalchemy import select

router = APIRouter(prefix="/progress", tags=["Progress & Savings"])


@router.get("/daily-summary")
async def daily_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await progress_service.get_daily_summary(db, current_user.id)


@router.get("/weekly-summary")
async def weekly_summary(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await progress_service.get_weekly_summary(db, current_user.id)


@router.get("/savings")
async def get_savings(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await progress_service.get_savings_data(db, current_user.id)


@router.get("/milestones")
async def get_milestones(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    return await progress_service.get_milestones(db, current_user.id)


@router.get("/savings-goals")
async def get_savings_goals(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SavingsGoal).where(SavingsGoal.user_id == current_user.id)
        .order_by(SavingsGoal.created_at.desc())
    )
    goals = result.scalars().all()
    return [{"id": g.id, "title": g.title, "target_amount": g.target_amount,
             "current_amount": g.current_amount, "icon": g.icon,
             "is_completed": g.is_completed,
             "target_date": g.target_date.isoformat() if g.target_date else None} for g in goals]


@router.post("/savings-goals")
async def create_savings_goal(
    data: SavingsGoalCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    goal = SavingsGoal(
        user_id=current_user.id,
        title=data.title,
        target_amount=data.target_amount,
        icon=data.icon or "savings",
        target_date=data.target_date,
    )
    db.add(goal)
    await db.commit()
    await db.refresh(goal)
    return {"id": goal.id, "title": goal.title, "message": "Savings goal created"}


@router.put("/savings-goals/{goal_id}")
async def update_savings_goal(
    goal_id: int,
    data: SavingsGoalUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(SavingsGoal).where(SavingsGoal.id == goal_id, SavingsGoal.user_id == current_user.id)
    )
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    update_data = data.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        if hasattr(goal, k) and k not in ("id", "user_id"):
            setattr(goal, k, v)
    await db.commit()
    return {"message": "Goal updated"}


@router.delete("/savings-goals/{goal_id}")
async def delete_savings_goal(
    goal_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    from fastapi import HTTPException
    result = await db.execute(
        select(SavingsGoal).where(SavingsGoal.id == goal_id, SavingsGoal.user_id == current_user.id)
    )
    goal = result.scalar_one_or_none()
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")
    await db.delete(goal)
    await db.commit()
    return {"message": "Goal deleted"}
