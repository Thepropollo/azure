from sqlmodel import select
from sqlalchemy.exc import NoResultFound
from app.models import Item

def create_item(session, item: Item):
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

def get_item(session, item_id: int):
    statement = select(Item).where(Item.id == item_id)
    result = session.exec(statement).first()
    return result

def list_items(session, limit: int = 100):
    statement = select(Item).limit(limit)
    return session.exec(statement).all()

def update_item(session, item_id: int, data: dict):
    item = get_item(session, item_id)
    if not item:
        return None
    for k, v in data.items():
        setattr(item, k, v)
    session.add(item)
    session.commit()
    session.refresh(item)
    return item

def delete_item(session, item_id: int):
    item = get_item(session, item_id)
    if not item:
        return False
    session.delete(item)
    session.commit()
    return True
