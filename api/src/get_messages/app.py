import json

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from api_lib.database import get_engine
from api_lib.decorators import lambda_wrapper
from api_lib.messages import Message


@lambda_wrapper
def lambda_handler(event, context):
    messages = []

    session = Session(get_engine())
    stmt = select(Message).order_by(Message.id.desc()).limit(29)
    results = session.scalars(stmt).all()

    for message in results:
        messages.append({
            'id': message.id,
            'message': message.message
        })

    return {
        'body': json.dumps({'messages': messages}),
    }
