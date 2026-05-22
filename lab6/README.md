# Лабораторная работа №6. Разработка RESTful API

## Цель

Разработать RESTful API для взаимодействия с базой данных сервиса бронирования жилья, созданной в предыдущих лабораторных работах.

API реализовано на `FastAPI`, для доступа к базе используется `SQLAlchemy ORM`, входные данные валидируются через `Pydantic`. Документация OpenAPI/Swagger генерируется автоматически.

## Что реализовано по ТЗ

| Требование | Где выполнено |
|---|---|
| Современный фреймворк | `FastAPI`, файл `lab6/app/main.py` |
| JSON-ответы | Все endpoint'ы FastAPI возвращают JSON |
| REST HTTP-методы | `GET`, `POST`, `PUT`, `PATCH`, `DELETE` |
| CRUD минимум для 3 таблиц | `users`, `properties`, `bookings` |
| Фильтрация, сортировка, пагинация | `?page=1&limit=10&sort=...&order=asc&filter=...` |
| Использование Views из лабораторной 2 | `/views/property-summary`, `/views/host-revenue`, `/views/active-bookings` |
| Вызов функций и процедур из лабораторной 3 | `/functions/...`, `/procedures/...` |
| Агрегации и отчеты | `/reports/revenue-by-city`, `/reports/top-guests`, `/reports/booking-statuses` |
| ORM-модели | `lab6/app/models.py` |
| Валидация | `lab6/app/schemas.py` |
| Обработка ошибок БД | `db_error()` в `lab6/app/main.py` |
| OpenAPI/Swagger | `/docs`, `/redoc`, `/openapi.json` |

## Теория

REST API — это способ организовать взаимодействие клиента с сервером через HTTP. В REST данные предметной области представляются как ресурсы: пользователи, объекты жилья, бронирования. Каждый ресурс имеет URL, а операция выбирается HTTP-методом.

Основные HTTP-методы:

- `GET` — получить данные без изменения состояния сервера.
- `POST` — создать новый ресурс или выполнить операцию, которая меняет состояние.
- `PUT` — заменить или обновить ресурс по известному ID.
- `PATCH` — частично обновить ресурс.
- `DELETE` — удалить ресурс.

HTTP-статусы нужны, чтобы клиент понимал результат операции:

- `200 OK` — успешное получение или обновление.
- `201 Created` — ресурс создан.
- `204 No Content` — удаление выполнено, тело ответа не нужно.
- `400 Bad Request` — неверные параметры запроса.
- `404 Not Found` — ресурс не найден.
- `409 Conflict` — конфликт с ограничениями БД, например дублирование уникального ключа или нарушение внешнего ключа.
- `422 Unprocessable Entity` — данные не прошли валидацию.

JSON — основной формат обмена данными в API. Он удобен для веб-клиентов, мобильных приложений и тестирования через Swagger/Postman/curl.

ORM — Object-Relational Mapping. ORM связывает таблицы базы данных с классами языка программирования. В этой лабораторной таблица `users` представлена классом `User`, `properties` — классом `Property`, `bookings` — классом `Booking`. Это позволяет писать запросы через Python-код и модели, а не собирать SQL-строки вручную.

Pydantic-схемы используются для валидации входных и выходных данных. Например, `price_per_night` должен быть больше нуля, `email` должен быть корректным email-адресом, `check_out_date` должен быть позже `check_in_date`. Если данные неверные, FastAPI автоматически возвращает `422`.

Пагинация нужна, чтобы не возвращать слишком много строк за один запрос. В API используется схема `page` + `limit`: `page=1&limit=10` возвращает первые 10 записей, `page=2&limit=10` — следующие 10.

Сортировка задается параметрами `sort` и `order`. Например, `/properties?sort=price_per_night&order=desc` вернет объекты жилья от дорогих к дешевым.

Фильтрация задается параметром `filter`. Для пользователей фильтр ищет по email, имени и фамилии; для объектов — по названию, городу и стране; для бронирований — по статусу.

Views — представления базы данных. Это сохраненные SQL-запросы, которые выглядят для клиента как таблицы только для чтения. В лабораторной 6 API читает представления из лабораторной 2: сводку по объектам, выручку хостов и активные бронирования.

Хранимые функции и процедуры — логика, которая выполняется внутри PostgreSQL. В этой работе API вызывает функции и процедуры из лабораторной 3: проверку активности пользователя, проверку существования объекта, создание бронирования с валидацией и пересчет рейтинга объекта.

OpenAPI — машинно-читаемое описание API: пути, методы, параметры, тела запросов и ответы. Swagger UI строит интерактивную документацию на основе OpenAPI. В FastAPI она создается автоматически.

## Структура

- `lab6/app/main.py` — endpoint'ы API.
- `lab6/app/models.py` — SQLAlchemy ORM-модели таблиц.
- `lab6/app/schemas.py` — Pydantic-схемы валидации.
- `lab6/app/database.py` — подключение к PostgreSQL и создание сессий.
- `lab6/requirements.txt` — зависимости Python.
- `lab6/Dockerfile` — контейнер API.

## Запуск через Docker

В корне репозитория:

```bash
docker compose up -d postgres
```

Подготовить базу:

```bash
docker compose exec -T postgres psql -U db_user -d db_lessons -f /work/lab2/01_ddl.sql
docker compose exec -T postgres psql -U db_user -d db_lessons -f /work/lab2/02_seed.sql
docker compose exec -T postgres psql -U db_user -d db_lessons -f /work/lab2/06_views.sql
docker compose exec -T postgres psql -U db_user -d db_lessons -f /work/lab3/01_procedures_functions.sql
docker compose exec -T postgres psql -U db_user -d db_lessons -f /work/lab6/01_check_property_availability.sql
```

`lab6/01_check_property_availability.sql` добавляет функцию проверки доступности объекта. Основные функции и процедуры берутся из `lab3/01_procedures_functions.sql`.

Запустить API:

```bash
docker compose up -d api
```

Адреса:

- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`
- OpenAPI JSON: `http://localhost:8000/openapi.json`
- Health check: `http://localhost:8000/health`

Остановить:

```bash
docker compose down
```

## Подключение к БД в DBeaver

- host: `localhost`
- port: `15432`
- database: `db_lessons`
- user: `db_user`
- password: `db_password`

Через DBeaver можно вручную выполнить SQL-файлы подготовки базы и смотреть, как API меняет данные.

## Основные endpoint'ы

### Users

- `GET /users?page=1&limit=10&sort=user_id&order=asc&filter=john`
- `GET /users/{user_id}`
- `POST /users`
- `PUT /users/{user_id}`
- `PATCH /users/{user_id}`
- `DELETE /users/{user_id}`

Пример создания:

```json
{
  "email": "api.user@example.com",
  "password_hash": "secret_hash",
  "first_name": "Api",
  "last_name": "User",
  "phone": "+10000000000",
  "role": "guest",
  "is_verified": true
}
```

### Properties

- `GET /properties?page=1&limit=10&sort=price_per_night&order=desc&filter=Paris`
- `GET /properties/{property_id}`
- `POST /properties`
- `PUT /properties/{property_id}`
- `PATCH /properties/{property_id}`
- `DELETE /properties/{property_id}`

### Bookings

- `GET /bookings?page=1&limit=10&sort=check_in_date&order=asc&filter=confirmed`
- `GET /bookings/{booking_id}`
- `POST /bookings`
- `PUT /bookings/{booking_id}`
- `PATCH /bookings/{booking_id}`
- `DELETE /bookings/{booking_id}`

## Views

- `GET /views/property-summary`
- `GET /views/host-revenue`
- `GET /views/active-bookings`

Эти endpoint'ы читают представления из `lab2/06_views.sql`.

## Функции и процедуры

- `GET /functions/users/{user_id}/booking-activity`
- `GET /functions/properties/{property_id}/exists`
- `POST /procedures/bookings/validated`
- `POST /procedures/properties/{property_id}/update-rating`
- `POST /functions/properties/availability`

Пример вызова процедуры создания бронирования:

```json
{
  "guest_id": 4,
  "property_id": 1,
  "check_in": "2026-12-01",
  "check_out": "2026-12-05"
}
```

## Отчеты

- `GET /reports/revenue-by-city` — выручка и количество бронирований по городам.
- `GET /reports/top-guests?limit=10` — гости с наибольшей суммой бронирований.
- `GET /reports/booking-statuses` — количество бронирований по статусам.

## Как тестировать

1. Открой `http://localhost:8000/docs`.
2. Выполни `GET /health`. Должен вернуться `{"status": "ok"}`.
3. Проверь `GET /users`, `GET /properties`, `GET /bookings`.
4. Создай пользователя через `POST /users`.
5. Обнови его через `PATCH /users/{id}`.
6. Проверь фильтрацию: `GET /users?filter=api`.
7. Проверь сортировку: `GET /properties?sort=price_per_night&order=desc`.
8. Проверь views: `GET /views/host-revenue`.
9. Проверь функцию: `GET /functions/users/4/booking-activity`.
10. Проверь отчет: `GET /reports/revenue-by-city`.

Для проверки ошибок можно:

- создать пользователя с уже существующим `email` — ожидается `409 Conflict`;
- создать бронирование с несуществующим `guest_id` — ожидается ошибка внешнего ключа;
- отправить `check_out_date` раньше `check_in_date` — ожидается `422 Unprocessable Entity`.
