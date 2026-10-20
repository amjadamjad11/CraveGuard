from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables and .env file."""

    DATABASE_URL: str = "sqlite+aiosqlite:///./craveguard.db"
    SECRET_KEY: str = "dev-secret-key-change-in-production"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 1440
    LLM_API_KEY: str = ""
    LLM_API_URL: str = "https://api.openai.com/v1/chat/completions"
    LLM_MODEL: str = "gpt-3.5-turbo"
    DEMO_MODE: bool = True
    APP_ENV: str = "development"

    model_config = {
        "env_file": ".env",
        "env_file_encoding": "utf-8",
        "extra": "ignore",
    }


settings = Settings()
