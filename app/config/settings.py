# app/config/settings.py (JWT 설정 제거)
from dotenv import load_dotenv
from pydantic_settings import BaseSettings

load_dotenv()

class Settings(BaseSettings):
    # Database
    db_host: str 
    db_port: int 
    db_user: str
    db_password: str 
    db_name: str 
    
    # Apple
    apple_client_id: str
    apple_team_id: str
    apple_key_id: str
    apple_private_key: str
    apple_redirect_uri: str
    
    # Firebase
    firebase_project_id: str
    firebase_credentials_path: str

class Config:
    env_file = ".env"
    case_sensitive = False

settings = Settings()