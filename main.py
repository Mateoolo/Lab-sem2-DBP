from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session

import models
from database import engine, get_db

# Crear las tablas automáticamente al inicializar
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SMAT - Persistencia de Datos")

# --- MODELOS DE VALIDACIÓN (PYDANTIC) ---
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


# --- ENDPOINTS REFACTORIZADOS ---

@app.post("/estaciones/", status_code=201)
def crear_estacion(estacion: EstacionCreate, db: Session = Depends(get_db)):
    existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion.id).first()
    if existe:
        raise HTTPException(status_code=400, detail="La estación ya existe")
    
    nueva_estacion = models.EstacionDB(id=estacion.id, nombre=estacion.nombre, ubicacion=estacion.ubicacion)
    db.add(nueva_estacion)
    db.commit()
    db.refresh(nueva_estacion)
    return {"msj": "Estación guardada en DB", "data": nueva_estacion}


@app.get("/estaciones/", response_model=List[EstacionCreate])
def listar_estaciones(db: Session = Depends(get_db)):
    return db.query(models.EstacionDB).all()


@app.post("/lecturas/", status_code=201)
def registrar_lectura(lectura: LecturaCreate, db: Session = Depends(get_db)):
    estacion_existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion_existe:
        raise HTTPException(status_code=404, detail="Estación no existe")
    
    nueva_lectura = models.LecturaDB(valor=lectura.valor, estacion_id=lectura.estacion_id)
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura guardada en DB"}


@app.get("/estaciones/{id}/riesgo")
def obtener_riesgo(id: int, db: Session = Depends(get_db)):
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    lecturas = db.query(models.LecturaDB).filter(models.LecturaDB.estacion_id == id).all()
    if not lecturas:
        return {"id": id, "nivel": "SIN DATOS", "valor": 0.0}
    
    ultima_lectura = lecturas[-1].valor
    if ultima_lectura > 20.0:
        nivel = "PELIGRO"
    elif ultima_lectura > 10.0:
        nivel = "ALERTA"
    else:
        nivel = "NORMAL"
    return {"id": id, "valor": ultima_lectura, "nivel": nivel}


@app.get("/estaciones/{id}/historial")
def obtener_historial_y_promedio(id: int, db: Session = Depends(get_db)):
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    lecturas_estacion = db.query(models.LecturaDB).filter(models.LecturaDB.estacion_id == id).all()
    conteo = len(lecturas_estacion)
    if conteo == 0:
        promedio = 0.0
    else:
        total_valores = sum(l.valor for l in lecturas_estacion)
        promedio = total_valores / conteo
        
    return {
        "estacion_id": id,
        "lecturas": [{"estacion_id": l.estacion_id, "valor": l.valor} for l in lecturas_estacion],
        "conteo": conteo,
        "promedio": round(promedio, 2)
    }