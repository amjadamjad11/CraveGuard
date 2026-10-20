from pydantic import BaseModel, ConfigDict
from typing import Optional
from datetime import datetime


class MotivationalMediaCreate(BaseModel):
    media_type: str  # photo/voice/text
    title: str
    content_text: Optional[str] = None
    file_path: Optional[str] = None


class MotivationalMediaResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    media_type: str
    title: str
    content_text: Optional[str] = None
    file_path: Optional[str] = None
    created_at: datetime


class QuitReasonCreate(BaseModel):
    reason_category: str
    priority_rank: int = 1
    custom_text: Optional[str] = None


class QuitReasonResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    reason_category: str
    priority_rank: int
    custom_text: Optional[str] = None
    created_at: datetime


class TrustedContactCreate(BaseModel):
    contact_name: str
    contact_method: str
    contact_value: str
    support_type: Optional[str] = None
    message_template: Optional[str] = None


class TrustedContactUpdate(BaseModel):
    contact_name: Optional[str] = None
    contact_method: Optional[str] = None
    contact_value: Optional[str] = None
    support_type: Optional[str] = None
    message_template: Optional[str] = None


class TrustedContactResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    contact_name: str
    contact_method: str
    contact_value: str
    support_type: Optional[str] = None
    message_template: Optional[str] = None
    is_active: bool
    created_at: datetime


class SupportRequestCreate(BaseModel):
    trusted_contact_id: int
    message_content: Optional[str] = None


class SupportMessageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: int
    user_id: int
    trusted_contact_id: int
    message_content: Optional[str] = None
    sent_at: datetime
    delivery_status: Optional[str] = None


class SupportConsentCreate(BaseModel):
    trusted_contact_id: int
    consent_type: str
