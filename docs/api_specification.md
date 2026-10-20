# CraveGuard API Specification

## Base URL
`http://localhost:8000/api/v1`

## Authentication
All endpoints except `/auth/register` and `/auth/login` require Bearer token authentication.

```
Authorization: Bearer <jwt_token>
```

## Endpoints

### Authentication
| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/register` | Register new user |
| POST | `/auth/login` | Login and get JWT token |
| GET | `/auth/me` | Get current user info |
| DELETE | `/auth/account` | Delete account and all data |

### Profile & Survey
| Method | Path | Description |
|--------|------|-------------|
| GET | `/profile` | Get user profile |
| PUT | `/profile` | Update user profile |
| GET | `/survey-responses` | Get all survey responses |
| POST | `/survey-responses` | Save survey response |
| PUT | `/survey-responses/{key}` | Update survey response |
| GET | `/quit-reasons` | Get quit reasons |
| POST | `/quit-reasons` | Add quit reason |
| GET | `/smoking-goal` | Get current smoking goal |
| PUT | `/smoking-goal` | Update smoking goal |

### Smoking Events
| Method | Path | Description |
|--------|------|-------------|
| POST | `/smoking-events` | Log smoking event |
| GET | `/smoking-events` | Get smoking events (paginated) |
| GET | `/smoking-baseline` | Get smoking baseline |
| POST | `/smoking-baseline` | Set smoking baseline |

### Craving Events
| Method | Path | Description |
|--------|------|-------------|
| POST | `/craving-events` | Log craving event |
| GET | `/craving-events` | Get craving events (paginated) |
| PATCH | `/craving-events/{id}` | Update craving (intensity_after) |

### Triggers
| Method | Path | Description |
|--------|------|-------------|
| GET | `/triggers` | Get trigger categories |
| POST | `/user-triggers` | Add user trigger |

### Risk Zones & Geofencing
| Method | Path | Description |
|--------|------|-------------|
| GET | `/risk-zones` | Get all risk zones |
| POST | `/risk-zones` | Create risk zone |
| PUT | `/risk-zones/{id}` | Update risk zone |
| DELETE | `/risk-zones/{id}` | Delete risk zone |
| POST | `/risk-zones/{id}/confirm` | Confirm suggested zone |
| GET | `/risk-candidates` | Get auto-detected candidates |
| POST | `/geofence-events` | Log geofence event |
| GET | `/visit-summaries` | Get location visit summaries |

### Interventions
| Method | Path | Description |
|--------|------|-------------|
| GET | `/interventions` | Get available interventions |
| GET | `/recommend-intervention` | Get personalized recommendation |
| POST | `/intervention-feedback` | Submit feedback |
| GET | `/intervention-history` | Get intervention history |

### Motivation & Support
| Method | Path | Description |
|--------|------|-------------|
| GET | `/motivational-media` | Get saved media |
| POST | `/motivational-media` | Save motivational item |
| DELETE | `/motivational-media/{id}` | Remove item |
| GET | `/trusted-contacts` | Get trusted contacts |
| POST | `/trusted-contacts` | Add trusted contact |
| PUT | `/trusted-contacts/{id}` | Update contact |
| DELETE | `/trusted-contacts/{id}` | Remove contact |
| POST | `/support-request` | Send support request |
| GET | `/support-messages` | Get support message log |
| POST | `/support-consent` | Grant consent |
| DELETE | `/support-consent/{id}` | Revoke consent |

### Progress & Savings
| Method | Path | Description |
|--------|------|-------------|
| GET | `/daily-summary` | Get daily progress |
| GET | `/weekly-summary` | Get weekly progress |
| GET | `/savings` | Get savings calculations |
| GET | `/savings-goals` | Get savings goals |
| POST | `/savings-goals` | Create savings goal |
| PUT | `/savings-goals/{id}` | Update savings goal |
| DELETE | `/savings-goals/{id}` | Delete savings goal |
| GET | `/milestones` | Get milestones |

### Chat (CraveCoach AI)
| Method | Path | Description |
|--------|------|-------------|
| GET | `/conversations` | Get conversations |
| POST | `/conversations` | Create conversation |
| GET | `/conversations/{id}/messages` | Get messages |
| POST | `/conversations/{id}/messages` | Send message (gets AI response) |

### Notifications
| Method | Path | Description |
|--------|------|-------------|
| GET | `/notification-preferences` | Get preferences |
| PUT | `/notification-preferences` | Update preferences |
