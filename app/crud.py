from sqlalchemy.orm import Session
from app import models, schemas

# Una función limpia que solo se encarga de buscar una estación
def obtener_estacion_por_id(db: Session, estacion_id: int):
    return db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion_id).first()

# Una función que solo se encarga de guardar una estación
def guardar_nueva_estacion(db: Session, estacion: schemas.EstacionCreate):
    nueva_estacion = models.EstacionDB(id=estacion.id, nombre=estacion.nombre, ubicacion=estacion.ubicacion)
    db.add(nueva_estacion)
    db.commit()
    db.refresh(nueva_estacion)
    return nueva_estacion
