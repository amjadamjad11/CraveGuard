"""CraveCoach AI chat service with LLM and fallback support."""
import random
from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.core.config import settings
from app.models.chat import ChatConversation, ChatMessage
from app.models.user import UserProfile


SYSTEM_PROMPT = """You are CraveCoach, a warm, compassionate AI assistant helping people manage smoking cravings and work towards quitting.

RULES:
- You are NOT a doctor. Never diagnose conditions or prescribe medications.
- Never guarantee that any method will work for everyone.
- Be supportive, practical, and nonjudgmental.
- When someone reports a lapse, respond without blame and help them learn from it.
- Suggest professional cessation support when appropriate.
- Use the user's data to personalize your responses, but never invent information.
- Keep responses concise but warm (2-4 paragraphs max).
- Suggest specific, actionable coping strategies.
"""

FALLBACK_RESPONSES = {
    "craving": [
        "I hear you — cravings can feel overwhelming, but they usually pass within 5-10 minutes. Let's try something together:\n\n🫁 **Breathing exercise**: Breathe in slowly for 4 counts, hold for 4, then breathe out for 6. Repeat 3-4 times.\n\nWhat triggered this craving? Understanding the trigger can help us find what works best for you.",
        "You're reaching out instead of reaching for a cigarette — that's a powerful choice. 💪\n\nTry this: drink a glass of cold water slowly, then take three deep breaths. Cravings are like waves — they rise, peak, and fall.\n\nWould you like to try a quick distraction activity?",
        "I'm here for you. Let's ride this craving out together. Try changing your environment — stand up, move to a different room, or step outside for fresh air.\n\nRemember: every craving you get through makes the next one a little easier. What are you feeling right now?",
    ],
    "lapse": [
        "Thank you for being honest about this — it takes real courage. One cigarette doesn't erase your progress. 🌱\n\nWhat was happening right before you smoked? Understanding the trigger helps us prepare better next time.\n\nYour journey isn't over. Most people who successfully quit have had setbacks along the way. What matters is that you're still here, still trying.",
        "Having a cigarette doesn't mean you've failed — it means you're human. Let's not focus on guilt; let's focus on what we can learn.\n\nThink about what led up to this moment. Was it stress? Social pressure? A specific place? Knowing this helps us build a better plan.\n\nYou've already shown strength by continuing this journey. 💛",
    ],
    "stress": [
        "Stress is one of the most common smoking triggers, and it makes complete sense that you'd feel the pull right now.\n\nHere are some quick stress-relief alternatives:\n- 🫁 Box breathing (4-4-4-4)\n- 💧 Splash cold water on your face\n- 🚶 Take a 5-minute walk\n- ✍️ Write down what's stressing you\n\nWhich one feels doable right now?",
    ],
    "progress": [
        "Let's celebrate how far you've come! Every small step counts. 🎉\n\nRemember: progress isn't always linear. Some days are harder than others, and that's completely normal.\n\nWhat's one thing you're proud of from your journey so far?",
    ],
    "savings": [
        "Money saved from reducing smoking is real savings! 💰 Think about what you could do with that money — a treat for yourself, savings towards a goal, or something nice for someone you love.\n\nWould you like to set a specific savings goal to stay motivated?",
    ],
    "default": [
        "I'm here to help in any way I can. You can tell me:\n- 'I'm having a craving' for immediate support\n- 'I smoked' without judgment\n- 'How am I doing?' for progress insights\n- 'Help me plan' for tomorrow's strategy\n\nWhat would be most helpful right now?",
        "Thanks for reaching out! I'm your CraveCoach, here to support your journey. Whether you need help with a craving, want to reflect on your progress, or just need someone to talk to — I'm here. 💙\n\nWhat's on your mind?",
    ],
}


def get_fallback_response(user_message: str) -> str:
    """Generate a response using keyword matching when LLM is unavailable."""
    msg = user_message.lower()

    if any(w in msg for w in ["crav", "urge", "want to smoke", "need a cigarette", "dying for"]):
        return random.choice(FALLBACK_RESPONSES["craving"])
    elif any(w in msg for w in ["smoked", "lapse", "relapse", "gave in", "had a cigarette", "slipped"]):
        return random.choice(FALLBACK_RESPONSES["lapse"])
    elif any(w in msg for w in ["stress", "anxious", "worried", "overwhelm", "panic", "tense"]):
        return random.choice(FALLBACK_RESPONSES["stress"])
    elif any(w in msg for w in ["progress", "doing", "streak", "milestone", "proud"]):
        return random.choice(FALLBACK_RESPONSES["progress"])
    elif any(w in msg for w in ["money", "save", "saved", "cost", "spend"]):
        return random.choice(FALLBACK_RESPONSES["savings"])
    else:
        return random.choice(FALLBACK_RESPONSES["default"])


async def get_or_create_conversation(db: AsyncSession, user_id: int, conversation_id: Optional[int] = None) -> ChatConversation:
    if conversation_id:
        result = await db.execute(
            select(ChatConversation).where(
                ChatConversation.id == conversation_id,
                ChatConversation.user_id == user_id,
            )
        )
        conv = result.scalar_one_or_none()
        if conv:
            return conv

    conv = ChatConversation(user_id=user_id, title="Chat with CraveCoach")
    db.add(conv)
    await db.commit()
    await db.refresh(conv)
    return conv


async def get_conversations(db: AsyncSession, user_id: int) -> List[ChatConversation]:
    result = await db.execute(
        select(ChatConversation).where(ChatConversation.user_id == user_id)
        .order_by(ChatConversation.updated_at.desc())
    )
    return list(result.scalars().all())


async def get_messages(db: AsyncSession, conversation_id: int, user_id: int) -> List[ChatMessage]:
    # Verify ownership
    result = await db.execute(
        select(ChatConversation).where(
            ChatConversation.id == conversation_id,
            ChatConversation.user_id == user_id,
        )
    )
    if not result.scalar_one_or_none():
        return []

    result = await db.execute(
        select(ChatMessage).where(ChatMessage.conversation_id == conversation_id)
        .order_by(ChatMessage.created_at.asc())
    )
    return list(result.scalars().all())


async def send_message(db: AsyncSession, user_id: int, conversation_id: int, content: str) -> tuple:
    """Process user message and generate response. Returns (user_msg, assistant_msg)."""
    # Save user message
    user_msg = ChatMessage(conversation_id=conversation_id, role="user", content=content)
    db.add(user_msg)

    # Try LLM API first
    response_text = None
    is_fallback = True

    if settings.LLM_API_KEY:
        try:
            import httpx
            # Build context from user profile
            profile_result = await db.execute(select(UserProfile).where(UserProfile.user_id == user_id))
            profile = profile_result.scalar_one_or_none()
            context = f"User smokes approximately {profile.cigarettes_per_day} cigarettes/day. " if profile else ""
            if profile and profile.current_goal:
                context += f"Goal: {profile.current_goal.value}. "

            messages = [
                {"role": "system", "content": SYSTEM_PROMPT + f"\nUser context: {context}"},
                {"role": "user", "content": content},
            ]

            async with httpx.AsyncClient(timeout=15.0) as client:
                resp = await client.post(
                    settings.LLM_API_URL,
                    headers={"Authorization": f"Bearer {settings.LLM_API_KEY}"},
                    json={"model": settings.LLM_MODEL, "messages": messages, "max_tokens": 500},
                )
                if resp.status_code == 200:
                    data = resp.json()
                    response_text = data["choices"][0]["message"]["content"]
                    is_fallback = False
        except Exception:
            pass  # Fall through to fallback

    if response_text is None:
        response_text = get_fallback_response(content)
        if is_fallback:
            response_text += "\n\n_ℹ️ This is a pre-written response. Live AI is not currently configured._"

    # Save assistant message
    assistant_msg = ChatMessage(conversation_id=conversation_id, role="assistant", content=response_text)
    db.add(assistant_msg)
    await db.commit()
    await db.refresh(user_msg)
    await db.refresh(assistant_msg)

    return user_msg, assistant_msg
