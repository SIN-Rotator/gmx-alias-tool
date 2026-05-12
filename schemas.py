from typing import Optional, List
from pydantic import BaseModel, Field

class GmxAliasCreateRequest(BaseModel):
    alias_name: Optional[str] = Field(default=None)
    delete_existing: bool = Field(default=True)

class GmxAliasResponse(BaseModel):
    status: str
    alias_email: Optional[str] = None
    alias_name: Optional[str] = None
    steps_completed: List[str] = Field(default_factory=list)
    steps_failed: List[str] = Field(default_factory=list)
    execution_time: str
    error: Optional[str] = None

class GmxSessionCheckResponse(BaseModel):
    status: str
    current_url: str
    session_active: bool
    execution_time: str
    error: Optional[str] = None

class GmxAliasDeleteResponse(BaseModel):
    status: str
    deleted: bool = False
    alias: Optional[str] = None
    execution_time: str
    error: Optional[str] = None
