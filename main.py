from fastapi import FastAPI
from pydantic import BaseModel
from typing import Optional


app = FastAPI()

class Credentials(BaseModel):
    id: Optional[int] = None
    username: str
    password: Optional[str] = None
    is_active: Optional[bool] = True

Credenciales = [
    {
        "id": 1,
        "username": "admin",
        "password": "A.12",
        "is_active": True
    },
    {
        "id": 2,
        "username": "Criss",
        "password": "C.12",
        "is_active": False
    }
]

@app.get("/")
def mensaje():
    return {"message": "hola mundo"}

@app.get('/Credenciales') # Listar todas las Credenciales
def get_Credenciales():
    return Credenciales
    
@app.get('/Credenciales/{id}')
def get_username(id: int):
        return list(filter(lambda item: item['id'] == id, Credenciales))

@app.post('/Credenciales') # Crear una nueva Credencial
def create_Credenciales(Credencial: Credentials):
    Credenciales.append(Credencial)
    return Credenciales
     
@app.put('/Credenciales/{id}') # Actualizar una Credencial existente, excepto password
def update_Credenciales(id: int, Credencial: Credentials):
    for i, item in enumerate(Credenciales):
        if item['id'] == id:
            Credenciales[i]['username'] = Credencial.username
            Credenciales[i]['id'] = Credencial.id
            Credenciales[i]['is_active'] = Credencial.is_active
    return Credenciales

@app.delete('/Credenciales/{id}') # Eliminar una Credencial existente
def delete_Credenciales(id: int):
    for item in Credenciales:
          if item['id'] == id:
                Credenciales.remove(item)
    return Credenciales

@app.post('/login') # Autenticar usuario
def login(Credencial: Credentials):
    for item in Credenciales:
        if item['username'] == Credencial.username and item['password'] == Credencial.password:
            return {"message": "Login successful"}
    return {"message": "Invalid username or password"}