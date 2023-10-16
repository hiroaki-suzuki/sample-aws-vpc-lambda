import json

from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from api_lib.database import get_engine
from api_lib.messages import Message


def lambda_handler(event, context):
    try:
        body = json.loads(event['body'])
        message = body['message']

        engine = get_engine()
        with Session(engine) as session:
            msg = Message(message=message)
            session.add(msg)
            session.commit()
    except KeyError:
        message = "'message' key not found in the body"
        print(f"KeyError: {message}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error_message': message})
        }
    except json.JSONDecodeError:
        message = 'Unable to parse event body as JSON'
        print(f"JSONDecodeError: {message}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error_message': message})
        }
    except SQLAlchemyError as e:
        print(f"SQLAlchemyError occurred: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error_message': "Unable to save message"}),
        }
    except Exception as e:
        print(f"An unexpected error occurred: {str(e)}")
        return {
            'statusCode': 400,
            'body': json.dumps({'error_message': "Unable to save message"}),
        }

    return {
        'statusCode': 200,
        'body': json.dumps({'message': 'Message saved successfully'}),
        'headers': {
            'Access-Control-Allow-Headers': 'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token',
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'OPTIONS,POST,GET'
        }
    }
