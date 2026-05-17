from fastapi import FastAPI, HTTPException, Depends
from pydantic import BaseModel
from typing import List
from sqlalchemy.orm import Session

# Importamos los componentes de la base de datos (Semana 3)
import models
from database import engine, get_db

# --- CREACIÓN AUTOMÁTICA DE TABLAS (Punto 4 de la guía) ---
# Esta instrucción crea físicamente las tablas en smat.db al iniciar el servidor
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SMAT - Persistencia de Datos")

# --- MODELOS DE DATOS MODIFICADOS (Pydantic Create Schemas) ---
class EstacionCreate(BaseModel):
    id: int
    nombre: str
    ubicacion: str

    class Config:
        from_attributes = True  # Permite mapear SQLAlchemy a Pydantic automáticamente

class LecturaCreate(BaseModel):
    estacion_id: int
    valor: float

    class Config:
        from_attributes = True


# --- ENDPOINTS REFACTORIZADOS ---

# 1. Gestión de Estaciones
@app.post("/estaciones/", status_code=201)
def crear_estacion(estacion: EstacionCreate, db: Session = Depends(get_db)):
    # Validar si ya existe la estación por ID para evitar duplicados en la BD
    existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion.id).first()
    if existe:
        raise HTTPException(status_code=400, detail="La estación ya existe")
        
    # Convertimos los datos que entran (Pydantic) al modelo de Base de Datos (SQLAlchemy)
    nueva_estacion = models.EstacionDB(id=estacion.id, nombre=estacion.nombre, ubicacion=estacion.ubicacion)
    db.add(nueva_estacion)   # Se prepara el guardado
    db.commit()              # Se asienta en el archivo smat.db de forma permanente
    db.refresh(nueva_estacion)
    return {"msj": "Estación guardada en DB", "data": nueva_estacion}

@app.get("/estaciones/", response_model=List[EstacionCreate])
def listar_estaciones(db: Session = Depends(get_db)):
    # Trae todas las estaciones registradas en la tabla SQL
    return db.query(models.EstacionDB).all()


# 2. Registro de Lecturas de Sensores
@app.post("/lecturas/", status_code=201)
def registrar_lectura(lectura: LecturaCreate, db: Session = Depends(get_db)):
    # Validar integridad: No podemos registrar lecturas de una estación que no existe
    estacion_existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion_existe:
        raise HTTPException(status_code=404, detail="Estación no existe")
        
    nueva_lectura = models.LecturaDB(valor=lectura.valor, estacion_id=lectura.estacion_id)
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura guardada en DB"}


# 3. Motor de Alertas (Manejo de Errores)
@app.get("/estaciones/{id}/riesgo")
def obtener_riesgo(id: int, db: Session = Depends(get_db)):
    # Validar existencia de la estación en las tablas SQL
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # Consultar las lecturas asociadas a esta estación mediante query
    lecturas = db.query(models.LecturaDB).filter(models.LecturaDB.estacion_id == id).all()
    if not lecturas:
        return {"id": id, "nivel": "SIN DATOS", "valor": 0.0}
    
    # Evaluamos el valor de la última lectura guardada
    ultima_lectura = lecturas[-1].valor
    if ultima_lectura > 20.0:
        nivel = "PELIGRO"
    elif ultima_lectura > 10.0:
        nivel = "ALERTA"
    else:
        nivel = "NORMAL"
        
    return {"id": id, "valor": ultima_lectura, "nivel": nivel}


# --- RETO DE SEMANA 3: HISTORIAL Y PROMEDIOS CON PERSISTENCIA ---
@app.get("/estaciones/{id}/historial")
def obtener_historial_y_promedio(id: int, db: Session = Depends(get_db)):
    # Paso 1: Verificar si la estación existe en la Base de Datos
    estacion = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # Paso 2: Traer las lecturas filtradas directamente desde la base de datos SQLite
    lecturas_estacion = db.query(models.LecturaDB).filter(models.LecturaDB.estacion_id == id).all()
    
    # Paso 3: Calcular métricas basadas en los registros encontrados
    conteo = len(lecturas_estacion)
    if conteo == 0:
        promedio = 0.0
    else:
        total_valores = sum(l.valor for l in lecturas_estacion)
        promedio = total_valores / conteo
        
    # Paso 4: Retornar la respuesta exacta estructurada
    return {
        "estacion_id": id,
        "lecturas": [
            {"estacion_id": l.estacion_id, "valor": l.valor} for l in lecturas_estacion
        ],
        "conteo": conteo,
        "promedio": round(promedio, 2)  # Mantenemos el redondeo limpio a 2 decimales
    }
