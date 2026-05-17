from pydantic import BaseModel
from typing import List

class EstacionCreate(BaseModel):
    id: int
    nombre: str
    ubicacion: str

    class Config:
        from_attributes = True

class LecturaCreate(BaseModel):
    estacion_id: int
    valor: float

    class Config:
        from_attributes = True
        