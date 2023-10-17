import json

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from api_lib.database import get_engine
from api_lib.decorators import lambda_wrapper
from api_lib.messages import Message


@lambda_wrapper
def lambda_handler(event, context):
    body = json.loads(event['body'])
    message = body['message']

    engine = get_engine()
    with Session(engine) as session:
        msg = Message(message=message)
        session.add(msg)
        session.commit()

    return {
        'body': json.dumps({'message': 'Message saved successfully'}),
    }