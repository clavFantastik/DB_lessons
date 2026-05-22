from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Query, Response, status
from sqlalchemy import Select, asc, desc, func, select, text
from sqlalchemy.exc import DataError, IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from .database import get_db
from .models import Booking, Property, User
from .schemas import (
    AvailabilityRequest,
    BookingCreate,
    BookingRead,
    BookingUpdate,
    ProcedureBookingCreate,
    PropertyCreate,
    PropertyRead,
    PropertyUpdate,
    UserCreate,
    UserRead,
    UserUpdate,
)


app = FastAPI(
    title="DB Lessons Lab 6 API",
    description="RESTful API для базы данных сервиса бронирования жилья.",
    version="1.0.0",
)


def db_error(exc: SQLAlchemyError) -> HTTPException:
    message = "Database error"
    status_code = status.HTTP_400_BAD_REQUEST
    original = getattr(exc, "orig", None)
    if original is not None:
        message = str(original).splitlines()[0]
    if isinstance(exc, IntegrityError):
        status_code = status.HTTP_409_CONFLICT
    elif isinstance(exc, DataError):
        status_code = status.HTTP_422_UNPROCESSABLE_ENTITY
    return HTTPException(status_code=status_code, detail=message)


def apply_pagination(stmt: Select[Any], page: int, limit: int) -> Select[Any]:
    return stmt.offset((page - 1) * limit).limit(limit)


def apply_sort(stmt: Select[Any], model: Any, sort: str, order: str, allowed: set[str]) -> Select[Any]:
    if sort not in allowed:
        raise HTTPException(status_code=400, detail=f"Unsupported sort field: {sort}")
    column = getattr(model, sort)
    return stmt.order_by(desc(column) if order == "desc" else asc(column))


def get_or_404(db: Session, model: Any, pk_name: str, item_id: int) -> Any:
    item = db.get(model, item_id)
    if item is None:
        raise HTTPException(status_code=404, detail=f"{pk_name}={item_id} not found")
    return item


@app.get("/health")
def health(db: Session = Depends(get_db)) -> dict[str, str]:
    db.execute(text("SELECT 1"))
    return {"status": "ok"}


@app.get("/users", response_model=list[UserRead])
def list_users(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "user_id",
    order: str = Query("asc", pattern="^(asc|desc)$"),
    filter: str | None = None,
) -> list[User]:
    stmt = select(User)
    if filter:
        pattern = f"%{filter}%"
        stmt = stmt.where(
            User.email.ilike(pattern) | User.first_name.ilike(pattern) | User.last_name.ilike(pattern)
        )
    stmt = apply_sort(stmt, User, sort, order, {"user_id", "email", "first_name", "last_name", "created_at"})
    return list(db.scalars(apply_pagination(stmt, page, limit)))


@app.get("/users/{user_id}", response_model=UserRead)
def get_user(user_id: int, db: Session = Depends(get_db)) -> User:
    return get_or_404(db, User, "user_id", user_id)


@app.post("/users", response_model=UserRead, status_code=201)
def create_user(payload: UserCreate, db: Session = Depends(get_db)) -> User:
    user = User(**payload.model_dump())
    db.add(user)
    try:
        db.commit()
        db.refresh(user)
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return user


@app.put("/users/{user_id}", response_model=UserRead)
@app.patch("/users/{user_id}", response_model=UserRead)
def update_user(user_id: int, payload: UserUpdate, db: Session = Depends(get_db)) -> User:
    user = get_or_404(db, User, "user_id", user_id)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(user, key, value)
    try:
        db.commit()
        db.refresh(user)
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return user


@app.delete("/users/{user_id}", status_code=204)
def delete_user(user_id: int, db: Session = Depends(get_db)) -> Response:
    user = get_or_404(db, User, "user_id", user_id)
    db.delete(user)
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return Response(status_code=204)


@app.get("/properties", response_model=list[PropertyRead])
def list_properties(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "property_id",
    order: str = Query("asc", pattern="^(asc|desc)$"),
    filter: str | None = None,
) -> list[Property]:
    stmt = select(Property)
    if filter:
        pattern = f"%{filter}%"
        stmt = stmt.where(Property.title.ilike(pattern) | Property.city.ilike(pattern) | Property.country.ilike(pattern))
    stmt = apply_sort(stmt, Property, sort, order, {"property_id", "title", "city", "price_per_night", "max_guests"})
    return list(db.scalars(apply_pagination(stmt, page, limit)))


@app.get("/properties/{property_id}", response_model=PropertyRead)
def get_property(property_id: int, db: Session = Depends(get_db)) -> Property:
    return get_or_404(db, Property, "property_id", property_id)


@app.post("/properties", response_model=PropertyRead, status_code=201)
def create_property(payload: PropertyCreate, db: Session = Depends(get_db)) -> Property:
    item = Property(**payload.model_dump())
    db.add(item)
    try:
        db.commit()
        db.refresh(item)
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return item


@app.put("/properties/{property_id}", response_model=PropertyRead)
@app.patch("/properties/{property_id}", response_model=PropertyRead)
def update_property(property_id: int, payload: PropertyUpdate, db: Session = Depends(get_db)) -> Property:
    item = get_or_404(db, Property, "property_id", property_id)
    for key, value in payload.model_dump(exclude_unset=True).items():
        setattr(item, key, value)
    try:
        db.commit()
        db.refresh(item)
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return item


@app.delete("/properties/{property_id}", status_code=204)
def delete_property(property_id: int, db: Session = Depends(get_db)) -> Response:
    item = get_or_404(db, Property, "property_id", property_id)
    db.delete(item)
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return Response(status_code=204)


@app.get("/bookings", response_model=list[BookingRead])
def list_bookings(
    db: Session = Depends(get_db),
    page: int = Query(1, ge=1),
    limit: int = Query(10, ge=1, le=100),
    sort: str = "booking_id",
    order: str = Query("asc", pattern="^(asc|desc)$"),
    filter: str | None = None,
) -> list[Booking]:
    stmt = select(Booking)
    if filter:
        stmt = stmt.where(Booking.status == filter)
    stmt = apply_sort(stmt, Booking, sort, order, {"booking_id", "guest_id", "property_id", "check_in_date", "created_at", "total_price"})
    return list(db.scalars(apply_pagination(stmt, page, limit)))


@app.get("/bookings/{booking_id}", response_model=BookingRead)
def get_booking(booking_id: int, db: Session = Depends(get_db)) -> Booking:
    return get_or_404(db, Booking, "booking_id", booking_id)


@app.post("/bookings", response_model=BookingRead, status_code=201)
def create_booking(payload: BookingCreate, db: Session = Depends(get_db)) -> Booking:
    item = Booking(**payload.model_dump())
    db.add(item)
    try:
        db.commit()
        db.refresh(item)
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return item


@app.put("/bookings/{booking_id}", response_model=BookingRead)
@app.patch("/bookings/{booking_id}", response_model=BookingRead)
def update_booking(booking_id: int, payload: BookingUpdate, db: Session = Depends(get_db)) -> Booking:
    item = get_or_404(db, Booking, "booking_id", booking_id)
    data = payload.model_dump(exclude_unset=True)
    check_in = data.get("check_in_date", item.check_in_date)
    check_out = data.get("check_out_date", item.check_out_date)
    if check_out <= check_in:
        raise HTTPException(status_code=422, detail="check_out_date must be after check_in_date")
    for key, value in data.items():
        setattr(item, key, value)
    try:
        db.commit()
        db.refresh(item)
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return item


@app.delete("/bookings/{booking_id}", status_code=204)
def delete_booking(booking_id: int, db: Session = Depends(get_db)) -> Response:
    item = get_or_404(db, Booking, "booking_id", booking_id)
    db.delete(item)
    try:
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return Response(status_code=204)


@app.get("/views/property-summary")
def property_summary(db: Session = Depends(get_db), limit: int = Query(10, ge=1, le=100)) -> list[dict[str, Any]]:
    rows = db.execute(text("SELECT * FROM v_property_summary ORDER BY total_bookings DESC LIMIT :limit"), {"limit": limit})
    return [dict(row._mapping) for row in rows]


@app.get("/views/host-revenue")
def host_revenue(db: Session = Depends(get_db), limit: int = Query(10, ge=1, le=100)) -> list[dict[str, Any]]:
    rows = db.execute(text("SELECT * FROM v_host_revenue ORDER BY total_revenue DESC LIMIT :limit"), {"limit": limit})
    return [dict(row._mapping) for row in rows]


@app.get("/views/active-bookings")
def active_bookings(db: Session = Depends(get_db), limit: int = Query(10, ge=1, le=100)) -> list[dict[str, Any]]:
    rows = db.execute(text("SELECT * FROM v_active_bookings ORDER BY check_in_date LIMIT :limit"), {"limit": limit})
    return [dict(row._mapping) for row in rows]


@app.get("/functions/users/{user_id}/booking-activity")
def user_booking_activity(user_id: int, db: Session = Depends(get_db)) -> dict[str, Any]:
    row = db.execute(text("SELECT * FROM check_user_booking_activity(:user_id)"), {"user_id": user_id}).mappings().first()
    if row is None:
        raise HTTPException(status_code=404, detail="Activity not found")
    return dict(row)


@app.get("/functions/properties/{property_id}/exists")
def property_exists(property_id: int, db: Session = Depends(get_db)) -> dict[str, Any]:
    exists = db.execute(text("SELECT property_exists(:property_id)"), {"property_id": property_id}).scalar_one()
    return {"property_id": property_id, "exists": exists}


@app.post("/procedures/bookings/validated", status_code=201)
def add_booking_with_validation(payload: ProcedureBookingCreate, db: Session = Depends(get_db)) -> dict[str, str]:
    try:
        db.execute(
            text("CALL add_booking_with_validation(:guest_id, :property_id, :check_in, :check_out)"),
            payload.model_dump(),
        )
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return {"status": "created"}


@app.post("/procedures/properties/{property_id}/update-rating")
def update_property_rating(property_id: int, db: Session = Depends(get_db)) -> dict[str, str]:
    try:
        db.execute(text("CALL update_property_rating(:property_id)"), {"property_id": property_id})
        db.commit()
    except SQLAlchemyError as exc:
        db.rollback()
        raise db_error(exc) from exc
    return {"status": "procedure executed"}


@app.post("/functions/properties/availability")
def check_availability(payload: AvailabilityRequest, db: Session = Depends(get_db)) -> dict[str, Any]:
    row = db.execute(
        text("SELECT * FROM check_property_availability(:property_id, :start_date, :end_date)"),
        payload.model_dump(),
    ).mappings().first()
    if row is None:
        raise HTTPException(status_code=404, detail="Availability result not found")
    return dict(row)


@app.get("/reports/revenue-by-city")
def revenue_by_city(db: Session = Depends(get_db)) -> list[dict[str, Any]]:
    rows = db.execute(
        select(
            Property.city,
            func.count(Booking.booking_id).label("bookings_count"),
            func.coalesce(func.sum(Booking.total_price), 0).label("total_revenue"),
        )
        .join(Booking, Booking.property_id == Property.property_id)
        .group_by(Property.city)
        .order_by(desc("total_revenue"))
    )
    return [dict(row._mapping) for row in rows]


@app.get("/reports/top-guests")
def top_guests(db: Session = Depends(get_db), limit: int = Query(10, ge=1, le=100)) -> list[dict[str, Any]]:
    rows = db.execute(
        select(
            User.user_id,
            User.email,
            func.count(Booking.booking_id).label("bookings_count"),
            func.coalesce(func.sum(Booking.total_price), 0).label("total_spent"),
        )
        .join(Booking, Booking.guest_id == User.user_id)
        .group_by(User.user_id, User.email)
        .order_by(desc("total_spent"))
        .limit(limit)
    )
    return [dict(row._mapping) for row in rows]


@app.get("/reports/booking-statuses")
def booking_statuses(db: Session = Depends(get_db)) -> list[dict[str, Any]]:
    rows = db.execute(
        select(Booking.status, func.count(Booking.booking_id).label("count"))
        .group_by(Booking.status)
        .order_by(Booking.status)
    )
    return [dict(row._mapping) for row in rows]
