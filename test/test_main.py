from fastapi.testclient import TestClient
from smat.app.main import app

client = TestClient(app)

def test_crear_estacion():
    response = client.post("/estaciones/", json={
        "id": 1,
        "nombre": "Estación Rimac",
        "ubicacion": "Chosica"
    })
    assert response.status_code == 201
    assert response.json()["data"]["nombre"] == "Estación Rimac"

def test_registrar_lectura():
    response = client.post("/lecturas/", json={
        "estacion_id": 1,
        "valor": 12.5
    })
    assert response.status_code == 201
    assert response.json()["status"] == "Lectura recibida"


def test_riesgo_peligro():
    # 1. Registro de estación y lectura crítica (> 20.0)
    client.post("/estaciones/", json={"id": 10, "nombre": "Misti", "ubicacion": "Arequipa"})
    client.post("/lecturas/", json={"estacion_id": 10, "valor": 25.5})
    
    # 2. Prueba de endpoint de riesgo
    response = client.get("/estaciones/10/riesgo")
    assert response.status_code == 200
    assert response.json()["nivel"] == "PELIGRO"

# Test Fase 3: Error 404
def test_estacion_no_encontrada():
    response = client.get("/estaciones/999/riesgo")
    assert response.status_code == 404
    assert response.json()["detail"] == "Estación no encontrada"

def test_historial_y_promedio():
    client.post("/estaciones/", json={"id": 20, "nombre": "Río Yauli", "ubicacion": "La Oroya"})

    client.post("/lecturas/", json={"estacion_id": 20, "valor": 10.0})
    client.post("/lecturas/", json={"estacion_id": 20, "valor": 20.0})
    client.post("/lecturas/", json={"estacion_id": 20, "valor": 30.0})

    response = client.get("/estaciones/20/historial")

    assert response.status_code == 200
    assert response.json()["conteo"] == 3
    assert response.json()["promedio"] == 20.0
    