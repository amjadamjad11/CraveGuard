from datetime import datetime, timezone
from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text
from app.core.database import Base


class MotivationalMedia(Base):
    __tablename__ = "motivational_media"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    media_type = Column(String(20), nullable=False)  # photo, voice, text
    title = Column(String(200), nullable=True)
    content_text = Column(Text, nullable=True)
    file_path = Column(String(500), nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class QuitReason(Base):
    __tablename__ = "quit_reasons"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    reason_category = Column(String(100), nullable=False)
    priority_rank = Column(Integer, default=0)
    custom_text = Column(Text, nullable=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class TrustedContact(Base):
    __tablename__ = "trusted_contacts"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    contact_name = Column(String(200), nullable=False)
    contact_method = Column(String(50), default="sms")  # sms, email, in_app
    contact_value = Column(String(200), nullable=True)
    support_type = Column(String(100), default="encouragement")
    message_template = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))


class SupportConsent(Base):
    __tablename__ = "support_consents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    trusted_contact_id = Column(Integer, ForeignKey("trusted_contacts.id", ondelete="CASCADE"), nullable=False)
    consent_type = Column(String(100), nullable=False)
    is_granted = Column(Boolean, default=True)
    granted_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    revoked_at = Column(DateTime, nullable=True)


class SupportMessageLog(Base):
    __tablename__ = "support_message_logs"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    trusted_contact_id = Column(Integer, ForeignKey("trusted_contacts.id", ondelete="CASCADE"), nullable=False)
    message_content = Column(Text, nullable=False)
    sent_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))
    delivery_status = Column(String(50), default="pending")
