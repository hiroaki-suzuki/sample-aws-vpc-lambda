from sqlalchemy.orm import DeclarativeBase, Mapped
from sqlalchemy.orm import mapped_column
from sqlalchemy import String

class Base(DeclarativeBase):
    pass


class Message(Base):
    __tablename__ = 'messages'

    id: Mapped[int] = mapped_column(primary_key=True)
    message: Mapped[str] = mapped_column(String(50))

    def __repr__(self):
        return f"Message(id={self.id}, message={self.message})"
