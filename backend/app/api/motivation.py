from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.models.motivation import MotivationalMedia, TrustedContact, SupportConsent, SupportMessageLog

router = APIRouter(prefix="/motivation", tags=["Motivation & Support"])


# --- Motivational Media ---
@router.get("/media")
async def get_media(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(MotivationalMedia).where(MotivationalMedia.user_id == current_user.id)
        .order_by(MotivationalMedia.created_at.desc())
    )
    items = result.scalars().all()
    return [{"id": m.id, "media_type": m.media_type, "title": m.title,
             "content_text": m.content_text, "file_path": m.file_path,
             "created_at": m.created_at.isoformat()} for m in items]


@router.post("/media")
async def add_media(data: dict, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    media = MotivationalMedia(
        user_id=current_user.id,
        media_type=data.get("media_type", "text"),
        title=data.get("title"),
        content_text=data.get("content_text"),
        file_path=data.get("file_path"),
    )
    db.add(media)
    await db.commit()
    await db.refresh(media)
    return {"id": media.id, "message": "Motivational item saved"}


@router.delete("/media/{media_id}")
async def delete_media(media_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(MotivationalMedia).where(MotivationalMedia.id == media_id, MotivationalMedia.user_id == current_user.id)
    )
    media = result.scalar_one_or_none()
    if not media:
        raise HTTPException(status_code=404, detail="Item not found")
    await db.delete(media)
    await db.commit()
    return {"message": "Item deleted"}


# --- Trusted Contacts ---
@router.get("/trusted-contacts")
async def get_contacts(current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(TrustedContact).where(TrustedContact.user_id == current_user.id)
    )
    contacts = result.scalars().all()
    return [{"id": c.id, "contact_name": c.contact_name, "contact_method": c.contact_method,
             "contact_value": c.contact_value, "support_type": c.support_type,
             "message_template": c.message_template, "is_active": c.is_active} for c in contacts]


@router.post("/trusted-contacts")
async def add_contact(data: dict, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    contact = TrustedContact(
        user_id=current_user.id,
        contact_name=data["contact_name"],
        contact_method=data.get("contact_method", "sms"),
        contact_value=data.get("contact_value"),
        support_type=data.get("support_type", "encouragement"),
        message_template=data.get("message_template",
            "I'm having a difficult moment and could use some encouragement. Could you check in with me?"),
    )
    db.add(contact)
    await db.commit()
    await db.refresh(contact)
    return {"id": contact.id, "message": "Contact added"}


@router.put("/trusted-contacts/{contact_id}")
async def update_contact(contact_id: int, data: dict, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(TrustedContact).where(TrustedContact.id == contact_id, TrustedContact.user_id == current_user.id)
    )
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    for k, v in data.items():
        if hasattr(contact, k) and k not in ("id", "user_id"):
            setattr(contact, k, v)
    await db.commit()
    return {"message": "Contact updated"}


@router.delete("/trusted-contacts/{contact_id}")
async def delete_contact(contact_id: int, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(TrustedContact).where(TrustedContact.id == contact_id, TrustedContact.user_id == current_user.id)
    )
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")
    await db.delete(contact)
    await db.commit()
    return {"message": "Contact deleted"}


# --- Support Request ---
@router.post("/support-request")
async def send_support_request(data: dict, current_user: User = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    """Send a support request to a trusted contact (preview — actual messaging requires configured provider)."""
    contact_id = data["trusted_contact_id"]
    result = await db.execute(
        select(TrustedContact).where(TrustedContact.id == contact_id, TrustedContact.user_id == current_user.id)
    )
    contact = result.scalar_one_or_none()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact not found")

    message = data.get("message", contact.message_template or
        "I'm having a difficult moment and could use some encouragement.")

    log = SupportMessageLog(
        user_id=current_user.id,
        trusted_contact_id=contact_id,
        message_content=message,
        delivery_status="preview",
    )
    db.add(log)
    await db.commit()
    await db.refresh(log)

    return {
        "id": log.id,
        "message": "Support request recorded. Note: actual message delivery requires a configured messaging provider.",
        "contact_name": contact.contact_name,
        "preview": True,
    }
