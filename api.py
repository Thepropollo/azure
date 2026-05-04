import os
from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import create_engine, Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
from pydantic import BaseModel
from typing import List

# 1. Configuración de FastAPI y CORS
app = FastAPI(title="ULEAM Azure CRUD")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 2. Configuración de la Base de Datos
# Permite usar Azure SQL (por defecto) o SQLite para pruebas locales.
DB_PASS = os.getenv("DB_PASS", "TuPasswordPro123!")
DB_SERVER = os.getenv("DB_SERVER", "sql-server-thepropollo.database.windows.net")
DB_NAME = os.getenv("DB_NAME", "crud-db")
DB_USER = os.getenv("DB_USER", "azureuser")

# Si se define USE_SQLITE=1, usamos SQLite para pruebas locales (evita dependencia ODBC)
USE_SQLITE = os.getenv("USE_SQLITE", "0") == "1"

if USE_SQLITE:
    DATABASE_URL = "sqlite:///./test.db"
    engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
else:
    # El driver 'ODBC Driver 17 for SQL Server' es el estándar en Azure Linux
    DATABASE_URL = (
        f"mssql+pyodbc:///?odbc_connect="
        f"Driver={{ODBC Driver 17 for SQL Server}};"
        f"Server=tcp:{DB_SERVER},1433;"
        f"Database={DB_NAME};"
        f"Uid={DB_USER};"
        f"Pwd={DB_PASS};"
        f"Encrypt=yes;"
        f"TrustServerCertificate=no;"
        f"Connection Timeout=30;"
    )
    engine = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# 3. Modelo de la Tabla
class Task(Base):
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(100))
    description = Column(String(255))

# Crear tabla si no existe
Base.metadata.create_all(bind=engine)

# 4. Esquemas Pydantic
class TaskBase(BaseModel):
    title: str
    description: str = None

class TaskSchema(TaskBase):
    id: int
    class Config:
        from_attributes = True

# 5. Dependencia para la DB
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# 6. Endpoints
@app.get("/")
def read_root():
    return {"status": "Online", "message": "API corriendo en Azure Central US"}

@app.get("/tasks", response_model=List[TaskSchema])
def get_tasks(db: Session = Depends(get_db)):
    return db.query(Task).all()

@app.post("/tasks", response_model=TaskSchema)
def create_task(task: TaskBase, db: Session = Depends(get_db)):
    db_task = Task(title=task.title, description=task.description)
    db.add(db_task)
    db.commit()
    db.refresh(db_task)
    return db_task

@app.delete("/tasks/{task_id}")
def delete_task(task_id: int, db: Session = Depends(get_db)):
    task = db.query(Task).filter(Task.id == task_id).first()
    if not task:
        raise HTTPException(status_code=404, detail="No existe la tarea")
    db.delete(task)
    db.commit()
    return {"message": "Eliminado correctamente"}