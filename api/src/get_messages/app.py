import json

from sqlalchemy import select
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from api_lib.database import get_engine
from api_lib.messages import Message


def lambda_handler(event, context):
    try:
        messages = []

        session = Session(get_engine())
        stmt = select(Message).order_by(Message.id.desc()).limit(29)
        results = session.scalars(stmt).all()

        for message in results:
            messages.append({
                'id': message.id,
                'message': message.message
            })
    except SQLAlchemyError as e:
        print(f"SQLAlchemyError occurred: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error_message': 'Invalid input'})
        }
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error_message': 'Message not found in body'})
        }

    # 処理結果をレスポンスとして返す
    return {
        'statusCode': 200,
        'body': json.dumps({'messages': messages}),
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }
    }
