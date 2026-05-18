from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas, database
# Importamos las funciones de seguridad recién creadas
from app.auth import crear_token_acceso, obtener_identidad_actual

# Crear las tablas en la base de datos automáticamente
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="SMAT - Sistema de Monitoreo de Alerta Temprana",
    description="API robusta y segura con arquitectura limpia y autenticación JWT para la gestión de desastres.",
    version="1.2.0"
)

# Middleware CORS (Manteniendo la interoperabilidad de la semana pasada)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =====================================================
# ENDPOINT DE SEGURIDAD (Simulación de Login)
# =====================================================
@app.post("/token", tags=["Seguridad"])
async def login_para_obtener_token(form_data: OAuth2PasswordRequestForm = Depends()):
    # Simulación de credenciales fijas para la Fase I
    if form_data.username == "admin_smat" and form_data.password == "fisi_2026":
        token = crear_token_acceso({"sub": form_data.username})
        return {"access_token": token, "token_type": "bearer"}
    raise HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED, 
        detail="Usuario o contraseña incorrectos"
    )

# =====================================================
# ENDPOINTS DE INFRAESTRUCTURA Y TELEMETRÍA
# =====================================================

@app.post(
    "/estaciones/", 
    status_code=201, 
    tags=["Estaciones"],
    summary="Registrar una nueva estación (PROTEGIDO)"
)
def crear_estacion(
    estacion: schemas.EstacionCreate, 
    db: Session = Depends(database.get_db),
    usuario: str = Depends(obtener_identidad_actual) # <-- PROTECCIÓN JWT
):
    existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion.id).first()
    if existe:
        raise HTTPException(status_code=400, detail="La estación ya existe")
    
    nueva_estacion = models.EstacionDB(id=estacion.id, nombre=estacion.nombre, ubicacion=estacion.ubicacion)
    db.add(nueva_estacion)
    db.commit()
    db.refresh(nueva_estacion)
    return {"msj": "Estación guardada en DB", "data": nueva_estacion}


@app.post(
    "/lecturas/", 
    status_code=201, 
    tags=["Telemetría"],
    summary="Registrar una lectura de sensor (PROTEGIDO)"
)
def registrar_lectura(
    lectura: schemas.LecturaCreate, 
    db: Session = Depends(database.get_db),
    usuario: str = Depends(obtener_identidad_actual) # <-- PROTECCIÓN JWT
):
    # RETO DE INTEGRIDAD CRUZADA (Puntos 3 y 4 del Laboratorio 4.4)
    estacion_db = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion_db:
        raise HTTPException(
            status_code=404, 
            detail="Error de Integridad: La estación no existe en la base de datos."
        )
    
    nueva_lectura = models.LecturaDB(valor=lectura.valor, estacion_id=lectura.estacion_id)
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura guardada en DB con validación de identidad cruzada"}


# --- Endpoints Públicos de Lectura (No requieren Token) ---

@app.get("/estaciones/", response_model=List[schemas.EstacionCreate], tags=["Estaciones"])
def listar_estaciones(db: Session = Depends(database.get_db)):
    return db.query(models.EstacionDB).all()

@app.get("/estaciones/{id}/riesgo", tags=["Análisis de Riesgo"])
def obtener_riesgo(id: int, db: Session = Depends(database.get_db)):
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

@app.get("/estaciones/{id}/historial", tags=["Reportes Históricos"])
def obtener_historial_y_promedio(id: int, db: Session = Depends(database.get_db)):
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