# Import all models so they are registered with Base.metadata
from app.models.user import User, UserProfile  # noqa: F401
from app.models.smoking import (  # noqa: F401
    SmokingBaseline,
    SmokingEvent,
    CravingEvent,
    TriggerCategory,
    UserTrigger,
)
from app.models.location import (  # noqa: F401
    LocationRiskZone,
    LocationVisitSummary,
    GeofenceEvent,
)
from app.models.motivation import (  # noqa: F401
    MotivationalMedia,
    QuitReason,
    TrustedContact,
    SupportConsent,
    SupportMessageLog,
)
from app.models.intervention import (  # noqa: F401
    Intervention,
    InterventionHistory,
    InterventionFeedback,
)
from app.models.progress import DailyProgressSummary, SavingsGoal  # noqa: F401
from app.models.chat import ChatConversation, ChatMessage  # noqa: F401
from app.models.notification import (  # noqa: F401
    NotificationPreference,
    NotificationEvent,
)
from app.models.consent import UserConsent, SurveyResponse  # noqa: F401

_all_models = True  # Flag to indicate all models have been imported
