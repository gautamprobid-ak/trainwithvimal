# Train With Vimal

Coaching app for a gym / online coaching business, built from the "Train With Vimal" design canvas.
Three apps in one Flutter codebase — **Admin** (owner), **Trainer** and **Client** — plus a Django backend.

```
lib/                     Flutter app
  app/                   app widget + router (all routes, role shells)
  core/theme/            colour tokens, type scale, radii (from the design system)
  core/widgets/          design-system widgets: cards, buttons, badges, toasts, sheets, tabs …
  data/models/           typed models
  data/mock/             the design's data as mock data
  data/state/            session (role, sign-in)
  data/api/              API client (Dio + JWT refresh), auth API, Firebase push
  features/auth/         welcome, log in, join link, verify email, reset password, setup, permissions, intro
  features/client/       Home · Train · Food · Progress · More (+ workout logger, food log, habits, check-ins …)
  features/trainer/      Home · Clients · Check-ins · Calendar · More (+ My profile)
  features/admin/        Home · Clients · Approvals · Calendar · More (+ trainers, activity, forms, automations, emails, settings)
  features/build/        programs, exercises, nutrition, habits, content — shared by admin and trainer
  features/shared/       client profile (admin + trainer)
backend/                 Django REST API (MySQL, JWT, Celery/Redis, Firebase)
docs/screens/            behaviour spec: every screen and every button
```

## Run the Flutter app

```bash
flutter pub get
flutter run                     # mock data, no backend needed
```

Log in with any of the demo accounts (any password in mock mode):

| Role | Email |
|---|---|
| Admin (Vimal) | `vimal@trainwithvimal.app` |
| Trainer (Aman Verma) | `aman.verma@email.com` |
| Client (Riya Sharma) | `riya.sharma@email.com` |

### Against the backend

```bash
flutter run --dart-define=USE_API=true --dart-define=API_BASE_URL=http://10.0.2.2:8000/api/v1
```

(`10.0.2.2` is the host machine from the Android emulator; use your LAN IP on a real phone.)
Seeded accounts use the password `Train@123`.

### Push notifications (Firebase)

1. Create a Firebase project, add the Android and iOS apps (`com.trainwithvimal.train_with_vimal`).
2. Run `flutterfire configure` (or drop `google-services.json` in `android/app/` and
   `GoogleService-Info.plist` in `ios/Runner/`).
3. Run with `--dart-define=FIREBASE=true`. The Permissions screen registers the device token with the API.
4. On the backend set `FIREBASE_CREDENTIALS` to the service-account JSON path.

## Run the backend

With Docker (MySQL 8, Redis, API, Celery worker + beat):

```bash
cd backend
cp .env.example .env
docker compose up --build
docker compose exec api python manage.py seed_all          # loads the design's data
docker compose exec api python manage.py createsuperuser   # Django admin at /admin/
```

Without Docker (needs MySQL and Redis running):

```bash
cd backend
python -m venv .venv && . .venv/bin/activate
pip install -r requirements-dev.txt
cp .env.example .env              # set MYSQL_* to your database
python manage.py migrate
python manage.py seed_all
python manage.py runserver 0.0.0.0:8000
celery -A config worker -l info   # + `celery -A config beat -l info` for scheduled jobs
```

- API docs (Swagger): `http://localhost:8000/api/docs/`
- Tests: `DB_ENGINE=sqlite python -m pytest -q`

### What the backend uses

| Piece | Why |
|---|---|
| Django + DRF | REST API for all three apps, role-scoped (admin sees all, trainer their clients, client only self) |
| MySQL (utf8mb4) | main database |
| SimpleJWT | log in, refresh, log out (token blacklist) |
| Celery + Redis | automations, check-in reminders, at-risk flags on a schedule |
| Firebase Admin | push notifications (FCM) and optional photo storage |
| drf-spectacular | OpenAPI schema + Swagger UI |
