from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user
from app.models.user import User
from app.schemas.chat import ChatMessageCreate
from app.ai.chat_service import get_or_create_conversation, get_conversations, get_messages, send_message

router = APIRouter(prefix="/chat", tags=["CraveCoach AI"])


@router.get("/conversations")
async def list_conversations(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    convos = await get_conversations(db, current_user.id)
    return [{"id": c.id, "title": c.title, "created_at": c.created_at.isoformat(),
             "updated_at": c.updated_at.isoformat()} for c in convos]


@router.post("/conversations")
async def create_conversation(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    conv = await get_or_create_conversation(db, current_user.id)
    return {"id": conv.id, "title": conv.title}


@router.get("/conversations/{conversation_id}/messages")
async def list_messages(
    conversation_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    messages = await get_messages(db, conversation_id, current_user.id)
    return [{"id": m.id, "role": m.role, "content": m.content,
             "created_at": m.created_at.isoformat()} for m in messages]


@router.post("/conversations/{conversation_id}/messages")
async def post_message(
    conversation_id: int,
    data: ChatMessageCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    content = data.content
    if not content.strip():
        raise HTTPException(status_code=400, detail="Message content is required")

    user_msg, assistant_msg = await send_message(db, current_user.id, conversation_id, content)
    return {
        "user_message": {"id": user_msg.id, "role": "user", "content": user_msg.content,
                         "created_at": user_msg.created_at.isoformat()},
        "assistant_message": {"id": assistant_msg.id, "role": "assistant", "content": assistant_msg.content,
                              "created_at": assistant_msg.created_at.isoformat()},
    }
