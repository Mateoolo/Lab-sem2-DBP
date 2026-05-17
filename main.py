from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List

app = FastAPI(title="SMAT API")

# --- MODELOS DE DATOS (PYDANTIC) ---
class Estacion(BaseModel):
    id: int
    nombre: str
    ubicacion: str

class Lectura(BaseModel):
    estacion_id: int
    valor: float

# --- "BASE DE DATOS" EN MEMORIA ---
db_estaciones = []
db_lecturas = []

# --- ENDPOINTS ---

# 1. Gestión de Estaciones
@app.post("/estaciones/", status_code=201)
async def crear_estacion(estacion: Estacion):
    db_estaciones.append(estacion)
    return {"msj": "Estación creada", "data": estacion}

@app.get("/estaciones/", response_model=List[Estacion])
async def listar_estaciones():
    return db_estaciones

# 2. Registro de Lecturas de Sensores
@app.post("/lecturas/", status_code=201)
async def registrar_lectura(lectura: Lectura):
    db_lecturas.append(lectura)
    return {"status": "Lectura recibida"}

# 3. Motor de Alertas y Manejo de Errores (Reto Final)
@app.get("/estaciones/{id}/riesgo")
async def obtener_riesgo(id: int):
    # Validar existencia de la estación (Error 404)
    estacion_existe = any(e.id == id for e in db_estaciones)
    if not estacion_existe:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # Filtrar lecturas de la estación
    lecturas = [l for l in db_lecturas if l.estacion_id == id]
    if not lecturas:
        return {"id": id, "nivel": "SIN DATOS", "valor": 0.0}
    
    # Evaluar última lectura (Motor de Reglas)
    ultima_lectura = lecturas[-1].valor
    if ultima_lectura > 20.0:
        nivel = "PELIGRO"
    elif ultima_lectura > 10.0:
        nivel = "ALERTA"
    else:
        nivel = "NORMAL"
        
    return {"id": id, "valor": ultima_lectura, "nivel": nivel}

# --- ENDPOINT DEL RETO: HISTORIAL Y PROMEDIOS (alumno) ---

@app.get("/estaciones/{id}/historial")
async def obtener_historial_y_promedio(id: int):
    # 1. Validar si la estación existe
    estacion_existe = any(e.id == id for e in db_estaciones)
    if not estacion_existe:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # 2. Filtrar lecturas
    lecturas_estacion = [l for l in db_lecturas if l.estacion_id == id]
    
    # 3. Calcular métricas reales usando el campo .valor
    conteo = len(lecturas_estacion)
    if conteo == 0:
        promedio = 0.0
    else:
        # Aquí nos aseguramos de sumar los VALORES de los sensores
        total_valores = sum(lectura.valor for lectura in lecturas_estacion)
        promedio = total_valores / conteo
        
    return {
        "estacion_id": id,
        "lecturas": lecturas_estacion,
        "conteo": conteo,
        "promedio": promedio
    }
