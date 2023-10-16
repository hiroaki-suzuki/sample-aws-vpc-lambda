import os

from sqlalchemy import create_engine, Engine

db_host = os.getenv("DB_HOST")
db_user = os.getenv("DB_USER")
db_password = os.getenv("DB_PASSWORD")
db_uri = f"mysql+pymysql://{db_user}:{db_password}@{db_host}:3306/sample"
engine = create_engine(db_uri)


def get_engine() -> Engine:
    return engine
