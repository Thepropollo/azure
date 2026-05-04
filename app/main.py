from fastapi import FastAPI, HTTPException, Depends
from typing import List
from sqlmodel import Session
from app.models import Item
from app.database import init_db, get_session
import uvicorn

app = FastAPI(title="API Inventario - FastAPI")

@app.on_event("startup")
def on_startup():
    init_db()

@app.post("/items/", response_model=Item)
def create_item(item: Item, session: Session = Depends(get_session)):
    from app.crud import create_item as crud_create
    return crud_create(session, item)

@app.get("/items/", response_model=List[Item])
def list_items(session: Session = Depends(get_session)):
    from app.crud import list_items as crud_list
    return crud_list(session)

@app.get("/items/{item_id}", response_model=Item)
def get_item(item_id: int, session: Session = Depends(get_session)):
    from app.crud import get_item as crud_get
    item = crud_get(session, item_id)
    if not item:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    return item

@app.put("/items/{item_id}", response_model=Item)
def update_item(item_id: int, item: Item, session: Session = Depends(get_session)):
    from app.crud import update_item as crud_update
    updated = crud_update(session, item_id, item.dict(exclude_unset=True))
    if not updated:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    return updated

@app.delete("/items/{item_id}")
def delete_item(item_id: int, session: Session = Depends(get_session)):
    from app.crud import delete_item as crud_delete
    ok = crud_delete(session, item_id)
    if not ok:
        raise HTTPException(status_code=404, detail="Item no encontrado")
    return {"deleted": True}

if __name__ == "__main__":
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
