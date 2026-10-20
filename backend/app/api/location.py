from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.location import LocationRiskZone, RiskLevel, GeofenceEvent
from app.models.smoking import SmokingEvent, CravingEvent
from app.schemas.location import LocationRiskZoneCreate, LocationRiskZoneUpdate
from app.ai.risk_scoring import cluster_events, calculate_risk_score

router = APIRouter(prefix="/location", tags=["Risk Zones & Geofencing"])


@router.get("/risk-zones")
async def get_risk_zones(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LocationRiskZone).where(LocationRiskZone.user_id == current_user.id)
        .order_by(LocationRiskZone.created_at.desc())
    )
    zones = result.scalars().all()
    return [{"id": z.id, "name": z.name, "latitude": z.latitude, "longitude": z.longitude,
             "radius_meters": z.radius_meters, "risk_level": z.risk_level.value,
             "trigger_reason": z.trigger_reason, "is_user_confirmed": z.is_user_confirmed,
             "is_active": z.is_active, "cooldown_minutes": z.cooldown_minutes} for z in zones]


@router.post("/risk-zones")
async def create_risk_zone(
    data: LocationRiskZoneCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    zone = LocationRiskZone(
        user_id=current_user.id,
        name=data.name,
        latitude=data.latitude,
        longitude=data.longitude,
        radius_meters=data.radius_meters,
        risk_level=RiskLevel(data.risk_level),
        trigger_reason=data.trigger_reason,
        is_user_confirmed=True,
        cooldown_minutes=data.cooldown_minutes,
    )
    db.add(zone)
    await db.commit()
    await db.refresh(zone)
    return {"id": zone.id, "name": zone.name, "message": "Risk zone created"}


@router.put("/risk-zones/{zone_id}")
async def update_risk_zone(
    zone_id: int,
    data: LocationRiskZoneUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LocationRiskZone).where(
            LocationRiskZone.id == zone_id,
            LocationRiskZone.user_id == current_user.id,
        )
    )
    zone = result.scalar_one_or_none()
    if not zone:
        raise HTTPException(status_code=404, detail="Risk zone not found")
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        if hasattr(zone, key) and key not in ("id", "user_id"):
            if key == "risk_level" and value is not None:
                value = RiskLevel(value)
            setattr(zone, key, value)
    await db.commit()
    return {"message": "Risk zone updated"}


@router.delete("/risk-zones/{zone_id}")
async def delete_risk_zone(
    zone_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LocationRiskZone).where(
            LocationRiskZone.id == zone_id,
            LocationRiskZone.user_id == current_user.id,
        )
    )
    zone = result.scalar_one_or_none()
    if not zone:
        raise HTTPException(status_code=404, detail="Risk zone not found")
    await db.delete(zone)
    await db.commit()
    return {"message": "Risk zone deleted"}


@router.post("/risk-zones/{zone_id}/confirm")
async def confirm_risk_zone(
    zone_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(LocationRiskZone).where(
            LocationRiskZone.id == zone_id,
            LocationRiskZone.user_id == current_user.id,
        )
    )
    zone = result.scalar_one_or_none()
    if not zone:
        raise HTTPException(status_code=404, detail="Risk zone not found")
    zone.is_user_confirmed = True
    await db.commit()
    return {"message": "Risk zone confirmed"}


@router.get("/risk-candidates")
async def get_risk_candidates(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Auto-detect candidate risk locations from smoking and craving events."""
    smoking_result = await db.execute(
        select(SmokingEvent).where(
            SmokingEvent.user_id == current_user.id,
            SmokingEvent.latitude.isnot(None),
        )
    )
    craving_result = await db.execute(
        select(CravingEvent).where(
            CravingEvent.user_id == current_user.id,
            CravingEvent.latitude.isnot(None),
        )
    )

    events = []
    for e in smoking_result.scalars().all():
        events.append({"latitude": e.latitude, "longitude": e.longitude, "type": "smoking", "intensity": e.craving_intensity or 5})
    for e in craving_result.scalars().all():
        events.append({"latitude": e.latitude, "longitude": e.longitude, "type": "craving", "intensity": e.intensity_before})

    candidates = cluster_events(events)
    return candidates


@router.post("/geofence-events")
async def create_geofence_event(
    data: dict,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    event = GeofenceEvent(
        user_id=current_user.id,
        risk_zone_id=data["risk_zone_id"],
        event_type=data.get("event_type", "entry"),
        notification_sent=data.get("notification_sent", False),
        intervention_shown=data.get("intervention_shown"),
    )
    db.add(event)
    await db.commit()
    await db.refresh(event)
    return {"id": event.id, "event_type": event.event_type, "message": "Geofence event recorded"}
