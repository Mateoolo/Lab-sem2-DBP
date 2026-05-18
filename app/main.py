from fastapi import FastAPI, HTTPException, Depends, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from typing import List

from app import models, schemas, database
from app.auth import crear_token_acceso, obtener_usuario_actual, obtener_password_hash, verificar_password

# Crear las tablas automáticamente
models.Base.metadata.create_all(bind=database.engine)

app = FastAPI(
    title="SMAT - Sistema de Monitoreo de Alerta Temprana",
    description="API robusta y segura con arquitectura limpia y autenticación JWT para la gestión de desastres.",
    version="1.2.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Credenciales oficiales indicadas en el laboratorio
USUARIO_DB = {
    "username": "admin_smat",
    "password_hash": obtener_password_hash("fisi_2026")
}

@app.post("/token", tags=["Seguridad"])
async def login_para_obtener_token(form_data: OAuth2PasswordRequestForm = Depends()):
    if form_data.username != USUARIO_DB["username"] or not verificar_password(form_data.password, USUARIO_DB["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, 
            detail="Usuario o contraseña incorrectos",
            headers={"WWW-Authenticate": "Bearer"},
        )
    token = crear_token_acceso(data={"sub": form_data.username})
    return {"access_token": token, "token_type": "bearer"}


# ==========================================
# GESTIÓN DE ESTACIONES Y TELEMETRÍA ASOCIADA
# ==========================================

@app.post("/estaciones/", status_code=201, tags=["Estaciones"], summary="Registrar una nueva estación (PROTEGIDO)")
def crear_estacion(
    datos: dict, # Diccionario flexible para recibir el JSON plano de Flutter sin trabas
    db: Session = Depends(database.get_db),
    usuario: str = Depends(obtener_usuario_actual)
):
    # Extraemos los campos estrictos enviados desde Flutter
    estacion_id = datos.get("id")
    nombre = datos.get("nombre")
    ubicacion = datos.get("ubicacion")
    riesgo_solicitado = datos.get("riesgo", "SIN DATOS")

    if not estacion_id or not nombre or not ubicacion:
        raise HTTPException(status_code=400, detail="Faltan campos obligatorios (id, nombre o ciudad)")

    # Validación de duplicados en la base de datos
    existe = db.query(models.EstacionDB).filter(models.EstacionDB.id == estacion_id).first()
    if existe:
        raise HTTPException(status_code=400, detail="El ID de esta estación ya existe en el sistema")
    
    # 1. Insertar la Estación en su tabla correspondiente
    nueva_estacion = models.EstacionDB(id=estacion_id, nombre=nombre, ubicacion=ubicacion)
    db.add(nueva_estacion)
    db.commit()
    db.refresh(nueva_estacion)

    # 2. Inyectar Lectura Inicial Automática para simular el comportamiento del sensor
    # Esto alimenta la lógica de semáforos de la pantalla de inicio de inmediato
    valor_sensor = 0.0
    if riesgo_solicitado == "PELIGRO":
        valor_sensor = 25.0  # > 20.0 activa Semáforo Rojo
    elif riesgo_solicitado == "ALERTA":
        valor_sensor = 15.0  # > 10.0 activa Semáforo Amarillo
    elif riesgo_solicitado == "NORMAL":
        valor_sensor = 5.0   # <= 10.0 activa Semáforo Verde

    if riesgo_solicitado != "SIN DATOS":
        nueva_lectura = models.LecturaDB(valor=valor_sensor, estacion_id=estacion_id)
        db.add(nueva_lectura)
        db.commit()

    return {"msj": "Estación y telemetría inicial guardadas", "creado_por": usuario, "data": nueva_estacion}


@app.get("/estaciones/", response_model=List[schemas.EstacionCreate], tags=["Estaciones"])
def listar_estaciones(db: Session = Depends(database.get_db)):
    return db.query(models.EstacionDB).all()


@app.put("/estaciones/{id}", tags=["Estaciones"], summary="Actualizar una estación existente (PROTEGIDO)")
def editar_estacion(
    id: int,
    datos: dict, 
    db: Session = Depends(database.get_db),
    usuario: str = Depends(obtener_usuario_actual)
):
    estacion_db = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion_db:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    if "nombre" in datos:
        estacion_db.nombre = datos["nombre"]
    if "ubicacion" in datos:
        estacion_db.ubicacion = datos["ubicacion"]
    
    db.commit()
    db.refresh(estacion_db)
    return {"msj": "Estación actualizada con éxito", "actualizado_por": usuario, "data": estacion_db}


@app.delete("/estaciones/{id}", tags=["Estaciones"], summary="Eliminar una estación (PROTEGIDO)")
def eliminar_estacion(
    id: int,
    db: Session = Depends(database.get_db),
    usuario: str = Depends(obtener_usuario_actual)
):
    estacion_db = db.query(models.EstacionDB).filter(models.EstacionDB.id == id).first()
    if not estacion_db:
        raise HTTPException(status_code=404, detail="Estación no encontrada")
    
    # Limpieza en cascada de lecturas para no violar restricciones de llave foránea
    db.query(models.LecturaDB).filter(models.LecturaDB.estacion_id == id).delete()
    
    db.delete(estacion_db)
    db.commit()
    return {"msj": "Estación eliminada de la DB correctamente", "eliminado_por": usuario}


# ==========================================
# TELEMETRÍA Y ANÁLISIS DE RIESGO
# ==========================================

@app.post("/lecturas/", status_code=201, tags=["Telemetría"], summary="Registrar una lectura de sensor (PROTEGIDO)")
def registrar_lectura(
    lectura: schemas.LecturaCreate, 
    db: Session = Depends(database.get_db),
    usuario: str = Depends(obtener_usuario_actual)
):
    estacion_db = db.query(models.EstacionDB).filter(models.EstacionDB.id == lectura.estacion_id).first()
    if not estacion_db:
        raise HTTPException(status_code=404, detail="Error de Integridad: La estación no existe.")
    
    nueva_lectura = models.LecturaDB(valor=lectura.valor, estacion_id=lectura.estacion_id)
    db.add(nueva_lectura)
    db.commit()
    return {"status": "Lectura guardada en DB con validación de identidad cruzada", "registrado_por": usuario}


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
    promedio = 0.0 if conteo == 0 else sum(l.valor for l in lecturas_estacion) / conteo
        
    return {
        "estacion_id": id,
        "lecturas": [{"estacion_id": l.estacion_id, "valor": l.valor} for l in lecturas_estacion],
        "conteo": conteo,
        "promedio": round(promedio, 2)
    }