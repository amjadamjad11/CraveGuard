# CraveGuard — Database Schema

## Entity Relationship Diagram

### Core User
- **User** — Authentication credentials and basic info
- **UserProfile** — Smoking habits, goals, preferences
- **SurveyResponse** — Flexible key-value survey answers
- **UserConsent** — Privacy and feature consent records

### Smoking Tracking
- **SmokingBaseline** — Starting point for comparison
- **SmokingEvent** — Individual smoking episodes
- **CravingEvent** — Craving episodes with before/after intensity
- **TriggerCategory** — Predefined + custom trigger types
- **UserTrigger** — User's personal triggers

### Location & Geofencing
- **LocationRiskZone** — User-confirmed or suggested risk areas
- **LocationVisitSummary** — Aggregated visit statistics per cluster
- **GeofenceEvent** — Entry/exit events at risk zones

### Motivation & Support
- **MotivationalMedia** — Photos, voice, text saved by user
- **QuitReason** — Prioritized reasons for quitting
- **TrustedContact** — Support people
- **SupportConsent** — Granular consent per contact
- **SupportMessageLog** — Record of sent support messages

### Interventions
- **Intervention** — Available coping strategies
- **InterventionHistory** — When interventions were used
- **InterventionFeedback** — User ratings of interventions

### Progress & Savings
- **DailyProgressSummary** — Aggregated daily metrics
- **SavingsGoal** — Financial goals with tracking

### Chat
- **ChatConversation** — Chat sessions
- **ChatMessage** — Individual messages (user/assistant/system)

### Notifications
- **NotificationPreference** — User notification settings
- **NotificationEvent** — Notification delivery records

## Key Relationships
- All user-owned tables have `user_id` FK to User
- CravingEvent → InterventionHistory (optional link)
- InterventionHistory → InterventionFeedback
- LocationRiskZone → GeofenceEvent
- TrustedContact → SupportConsent
- ChatConversation → ChatMessage
