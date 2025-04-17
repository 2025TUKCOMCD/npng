from pydantic import BaseModel, Field
from typing import Optional

class UserUpdateRequest(BaseModel):
    email: Optional[str] = Field(None, example="new_email@example.com")
    full_name: Optional[str] = Field(None, example="홍길동")
        
    class Config:
        schema_extra = {
            "example": {
                "email": "updated@example.com",
                "full_name": "수정된 이름"
            }
        }

class UserResponse(BaseModel):
    id: int
    email: Optional[str]
    full_name: Optional[str]
    is_active: bool
    apple_id: Optional[str]
    firebase_uid: Optional[str]

    class Config:
        from_attributes = True