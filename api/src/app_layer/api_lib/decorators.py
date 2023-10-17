import json
import traceback


def lambda_wrapper(func):
    import functools

    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        try:
            response = func(*args, **kwargs)

            if 'statusCode' not in response:
                response['statusCode'] = 200
            if 'headers' in response:
                response['headers'].update(create_response_header())
            else:
                response['headers'] = create_response_header()

            print(response)

            return response
        except Exception as e:
            class_name = e.__class__.__name__
            message = str(e)
            stack_trace = traceback.format_exc()

            # ログに出力
            print(f"Exception caught: {class_name}")
            print(f"An unexpected error occurred: {message}")
            print(f"Stack Trace:\n{stack_trace}")
            return {
                'statusCode': 500,
                'body': json.dumps({'error_message': "An unexpected error occurred"}),
                'header': create_response_header()
            }

    return wrapper


def create_response_header():
    return {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': '*',
        'Access-Control-Allow-Headers':
            'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Requested-With,X-Requested-By',
    }
