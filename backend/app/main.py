"""CraveGuard API — Main Application"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.core.database import create_tables
from app.api import (
    auth_router, profile_router, smoking_router, location_router,
    intervention_router, motivation_router, progress_router,
    chat_router, notification_router,
)


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: create tables and seed data
    from app.models import _all_models  # noqa: F401 — register all models
    await create_tables()
    await seed_defaults()
    yield


app = FastAPI(
    title="CraveGuard API",
    description="AI-Powered Personalized Smoking Cessation Backend",
    version="1.0.0",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
API_PREFIX = "/api/v1"
app.include_router(auth_router, prefix=API_PREFIX)
app.include_router(profile_router, prefix=API_PREFIX)
app.include_router(smoking_router, prefix=API_PREFIX)
app.include_router(location_router, prefix=API_PREFIX)
app.include_router(intervention_router, prefix=API_PREFIX)
app.include_router(motivation_router, prefix=API_PREFIX)
app.include_router(progress_router, prefix=API_PREFIX)
app.include_router(chat_router, prefix=API_PREFIX)
app.include_router(notification_router, prefix=API_PREFIX)


@app.get("/")
async def root():
    return {"app": "CraveGuard API", "version": "1.0.0", "status": "running"}


@app.get("/health")
async def health():
    return {"status": "healthy"}


async def seed_defaults():
    """Seed default trigger categories and interventions if tables are empty."""
    from app.core.database import AsyncSessionLocal as async_session
    from app.models.smoking import TriggerCategory
    from app.models.intervention import Intervention
    from sqlalchemy import select, func

    async with async_session() as db:
        # Check if triggers already exist
        result = await db.execute(select(func.count(TriggerCategory.id)))
        if result.scalar() == 0:
            triggers = [
                TriggerCategory(name="Stress / Anxiety", description="Feeling stressed, anxious, or overwhelmed"),
                TriggerCategory(name="Sadness / Loneliness", description="Feeling sad, lonely, or isolated"),
                TriggerCategory(name="Anger / Frustration", description="Feeling angry, frustrated, or irritated"),
                TriggerCategory(name="Boredom", description="Having nothing to do or feeling understimulated"),
                TriggerCategory(name="Habit / Routine", description="Smoking as part of daily routine"),
                TriggerCategory(name="After Meals", description="Craving after eating"),
                TriggerCategory(name="With Tea / Coffee", description="During tea or coffee breaks"),
                TriggerCategory(name="Work / Study", description="While working or studying"),
                TriggerCategory(name="Social Pressure", description="Being around friends who smoke"),
                TriggerCategory(name="While Travelling", description="During commute or travel"),
                TriggerCategory(name="Difficulty Concentrating", description="Needing to focus"),
                TriggerCategory(name="Difficulty Relaxing", description="Trying to unwind or sleep"),
                TriggerCategory(name="Alcohol", description="Drinking or social drinking situations"),
                TriggerCategory(name="Nicotine Withdrawal", description="Physical withdrawal symptoms"),
            ]
            db.add_all(triggers)

        # Seed default interventions
        result = await db.execute(select(func.count(Intervention.id)))
        if result.scalar() == 0:
            interventions = [
                Intervention(name="Breathing Exercise", category="breathing",
                    description="A simple deep breathing exercise to calm your body and mind",
                    instructions="Breathe in slowly for 4 counts through your nose. Hold for 4 counts. Breathe out slowly for 6 counts through your mouth. Repeat 4-5 times.",
                    duration_minutes=3),
                Intervention(name="Grounding Exercise", category="grounding",
                    description="A 5-4-3-2-1 sensory grounding technique",
                    instructions="Notice: 5 things you can see, 4 things you can touch, 3 things you can hear, 2 things you can smell, 1 thing you can taste.",
                    duration_minutes=3),
                Intervention(name="Drink Water", category="physical",
                    description="Have a glass of cold water slowly",
                    instructions="Pour a glass of cold water. Drink it slowly, noticing the sensation. This can help reduce the intensity of a craving.",
                    duration_minutes=2),
                Intervention(name="5-Minute Walk", category="activity",
                    description="Take a short walk to change your environment",
                    instructions="Step outside or walk around your space for 5 minutes. Focus on your surroundings — what do you see, hear, feel?",
                    duration_minutes=5),
                Intervention(name="Delay 5 Minutes", category="delay",
                    description="Wait just 5 more minutes before deciding",
                    instructions="Set a 5-minute timer. Tell yourself you can smoke after it ends if you still want to. Most cravings pass within 5-10 minutes.",
                    duration_minutes=5),
                Intervention(name="Contact Someone", category="contact",
                    description="Reach out to a trusted friend or family member",
                    instructions="Call, text, or message someone you trust. You don't have to talk about smoking — just connecting can help.",
                    duration_minutes=5),
                Intervention(name="Review Your Progress", category="motivation",
                    description="Look at how far you've come",
                    instructions="Open your progress dashboard. Look at your savings, your cravings resisted, your milestones. You're doing this.",
                    duration_minutes=2),
                Intervention(name="Talk to CraveCoach", category="ai",
                    description="Chat with your AI support assistant",
                    instructions="Open CraveCoach and share what you're feeling. It can help you work through the craving with personalized suggestions.",
                    duration_minutes=5),
                Intervention(name="Motivational Reminder", category="motivation",
                    description="Look at your personal motivation vault",
                    instructions="Open your saved photos, messages, or reasons for quitting. Remember why you started this journey.",
                    duration_minutes=2),
                Intervention(name="Quick Distraction", category="distraction",
                    description="Do something engaging for a few minutes",
                    instructions="Play a quick game, watch a short video, solve a puzzle, or do something that engages your hands and mind.",
                    duration_minutes=5),
                Intervention(name="Change Environment", category="activity",
                    description="Move to a different room or space",
                    instructions="Physically move to a different environment. This breaks the association between your current setting and smoking.",
                    duration_minutes=2),
                Intervention(name="Chew Gum or Snack", category="physical",
                    description="Have sugar-free gum or a healthy snack",
                    instructions="Chew gum, eat a carrot stick, or have a small snack. This gives your mouth something to do and can reduce oral cravings.",
                    duration_minutes=3),
            ]
            db.add_all(interventions)

        await db.commit()
