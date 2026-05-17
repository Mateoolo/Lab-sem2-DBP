from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session

import models
from database import engine, get_db

# Crear las tablas automáticamente al inicializar
models.Base.metadata.create_all(bind=engine)

# 1. CONFIGURACIÓN DE METADATOS GLOBALES (Punto 2 de la guía)
app = FastAPI(
    title="SMAT - Sistema de Monitoreo de Alerta Temprana",
    description="""
API robusta para la gestión y monitoreo de desastres naturales.
Permite la telemetría de sensores en tiempo real y el cálculo de niveles de riesgo.

**Entidades principales:**
* **Estaciones:** Puntos de monitoreo físico.
* **Lecturas:** Datos capturados por sensores.
* **Riesgos:** Análisis de criticidad basado en umbrales.
""",
    version="1.0.0",
    contact={
        "name": "E.P. Ciencias de la Computación - UNMSM",
    }
)

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


# --- ENDPOINTS DOCUMENTADOS (Punto 3 y Retos de la guía) ---

@app.post(
    "/estaciones/", 
    status_code=201,
    tags=["Estaciones"],
    summary="Registrar una nueva estación",
    description="Inserta una nueva estación meteorológica en el sistema. El ID debe ser único."
)
def crear_estacion(estacion: EstacionCreate, db: Session = Depends(get_db)):
    existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion.id).first()
    if existe:
        raise HTTPException(status_code=400, detail="La estación ya existe")
    
    nueva_estacion = models.EstacionDB(id=estacion.id, nombre=estacion.nombre, ubicacion=estacion.ubicacion)
    db.add(nueva_estacion)
    db.commit()
    db.refresh(nueva_estacion)
    return {"msj": "Estación guardada en DB", "data": nueva_estacion}


@app.get(
    "/estaciones/", 
    response_model=List[EstacionCreate],
    tags=["Estaciones"],
    summary="Listar todas las estaciones",
    description="Retorna un arreglo con todas las estaciones de monitoreo registradas en la base de datos."
)
def listar_estaciones(db: Session = Depends(get_db)):
    return db.query(models.EstacionDB).all()


@app.post(
    "/lecturas/", 
    status_code=201,
    tags=["Telemetría"],
    summary="Registrar una lectura de sensor",
    description="Recibe el valor de un sensor (temperatura, nivel de río, etc.) asociado a una estación existente."
)
def registrar_lectura(lectura: LecturaCreate, db: Session = Depends(get_db)):
    estacion_existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion_existe:
        raise HTTPException(status_code=404, detail="Estación no existe")
    
    nueva_lectura = models.LecturaDB(valor=lectura.valor, estacion_id=lectura.estacion_id)
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura guardada en DB"}


@app.get(
    "/estaciones/{id}/riesgo",
    tags=["Análisis de Riesgo"],
    summary="Calcular nivel de criticidad",
    description="Analiza la última lectura registrada de una estación para categorizar el riesgo en NORMAL, ALERTA o PELIGRO."
)
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


# RETO 4.2: Endpoint con Tag "Reportes Históricos" y cálculo estadístico (Punto 4)
@app.get(
    "/estaciones/{id}/historial",
    tags=["Reportes Históricos"],
    summary="Obtener historial y métricas",
    description="Realiza cálculos estadísticos (conteo y promedio) sobre todas las lecturas de una estación específica.",
    responses={404: {"description": "Estación no encontrada"}}
)
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
