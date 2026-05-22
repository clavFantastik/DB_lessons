from datetime import date, datetime
from decimal import Decimal

from pydantic import BaseModel, ConfigDict, EmailStr, Field, field_validator

from .models import BookingStatus, UserRole


class UserBase(BaseModel):
    email: EmailStr
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    phone: str | None = Field(default=None, max_length=20)
    role: UserRole
    is_verified: bool = False


class UserCreate(UserBase):
    password_hash: str = Field(min_length=6, max_length=255)


class UserUpdate(BaseModel):
    email: EmailStr | None = None
    password_hash: str | None = Field(default=None, min_length=6, max_length=255)
    first_name: str | None = Field(default=None, min_length=1, max_length=100)
    last_name: str | None = Field(default=None, min_length=1, max_length=100)
    phone: str | None = Field(default=None, max_length=20)
    role: UserRole | None = None
    is_verified: bool | None = None


class UserRead(UserBase):
    model_config = ConfigDict(from_attributes=True)

    user_id: int
    created_at: datetime


class PropertyBase(BaseModel):
    host_id: int = Field(gt=0)
    type_id: int = Field(gt=0)
    title: str = Field(min_length=1, max_length=255)
    description: str | None = None
    address: str = Field(min_length=1, max_length=255)
    city: str = Field(min_length=1, max_length=100)
    country: str = Field(min_length=1, max_length=100)
    price_per_night: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    max_guests: int = Field(gt=0)
    bedrooms: int | None = Field(default=None, ge=0)
    bathrooms: int | None = Field(default=None, ge=0)
    is_active: bool = True


class PropertyCreate(PropertyBase):
    pass


class PropertyUpdate(BaseModel):
    host_id: int | None = Field(default=None, gt=0)
    type_id: int | None = Field(default=None, gt=0)
    title: str | None = Field(default=None, min_length=1, max_length=255)
    description: str | None = None
    address: str | None = Field(default=None, min_length=1, max_length=255)
    city: str | None = Field(default=None, min_length=1, max_length=100)
    country: str | None = Field(default=None, min_length=1, max_length=100)
    price_per_night: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    max_guests: int | None = Field(default=None, gt=0)
    bedrooms: int | None = Field(default=None, ge=0)
    bathrooms: int | None = Field(default=None, ge=0)
    is_active: bool | None = None


class PropertyRead(PropertyBase):
    model_config = ConfigDict(from_attributes=True)

    property_id: int


class BookingBase(BaseModel):
    guest_id: int = Field(gt=0)
    property_id: int = Field(gt=0)
    check_in_date: date
    check_out_date: date
    total_price: Decimal = Field(gt=0, max_digits=10, decimal_places=2)
    status: BookingStatus = BookingStatus.pending

    @field_validator("check_out_date")
    @classmethod
    def checkout_after_checkin(cls, value: date, info):
        check_in = info.data.get("check_in_date")
        if check_in and value <= check_in:
            raise ValueError("check_out_date must be after check_in_date")
        return value


class BookingCreate(BookingBase):
    pass


class BookingUpdate(BaseModel):
    guest_id: int | None = Field(default=None, gt=0)
    property_id: int | None = Field(default=None, gt=0)
    check_in_date: date | None = None
    check_out_date: date | None = None
    total_price: Decimal | None = Field(default=None, gt=0, max_digits=10, decimal_places=2)
    status: BookingStatus | None = None


class BookingRead(BookingBase):
    model_config = ConfigDict(from_attributes=True)

    booking_id: int
    created_at: datetime


class ProcedureBookingCreate(BaseModel):
    guest_id: int = Field(gt=0)
    property_id: int = Field(gt=0)
    check_in: date
    check_out: date

    @field_validator("check_out")
    @classmethod
    def procedure_checkout_after_checkin(cls, value: date, info):
        check_in = info.data.get("check_in")
        if check_in and value <= check_in:
            raise ValueError("check_out must be after check_in")
        return value


class AvailabilityRequest(BaseModel):
    property_id: int = Field(gt=0)
    start_date: date
    end_date: date
