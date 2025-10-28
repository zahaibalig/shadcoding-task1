# Project Gallery - Full-Stack Web App

A portfolio project gallery with vehicle registration lookup, built with Django and Vue.js.

## What it does

- Browse projects (public - no login needed)
- Look up Norwegian car registration details
- Admin dashboard to manage projects (login required)

Simple, clean, and fully tested with CI/CD deployment.

## Tech Stack

**Backend**: Django 5.2, Django REST Framework, JWT auth, SQLite
**Frontend**: Vue.js 3, TypeScript, Vite, Pinia
**Testing**: Vitest + Django unittest (52 tests total)
**Deploy**: CircleCI → AWS Ubuntu Server → Nginx + Gunicorn

## Quick Start

### Run Locally

**Backend**:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r ../requirements.txt
python manage.py migrate
python manage.py createsuperuser  # Create admin account
python manage.py runserver  # http://localhost:8000
```

**Frontend** (new terminal):
```bash
cd frontend
npm install
npm run dev  # http://localhost:5173
```

### Default Login

Username: `admin`
Password: (whatever you set during createsuperuser)

## Project Structure

```
shadcoding-task1/
├── backend/          Django API + database
├── frontend/         Vue.js app
├── deployment/       Server configs and deploy scripts
└── .circleci/        CI/CD pipeline config
```

## API Endpoints

**Public** (no auth):
- `GET /api/projects/` - List all projects
- `GET /api/projects/{id}/` - Single project
- `GET /api/vehicles/lookup/?registration=ABC123` - Car lookup

**Protected** (auth required):
- `POST /api/projects/` - Create project
- `PUT /api/projects/{id}/` - Update project
- `DELETE /api/projects/{id}/` - Delete project
- `POST /api/auth/jwt/create/` - Login (get tokens)

## Testing

```bash
# Backend (17 tests)
cd backend && python manage.py test

# Frontend (35 tests)
cd frontend && npm test
```

All tests pass. Coverage includes API services, vehicle lookup, and Vue components.

## Deployment

The app auto-deploys to AWS when you push to `main`:

1. Push code → GitHub
2. CircleCI runs tests
3. Builds frontend
4. Deploys to AWS server
5. Live at http://18.217.70.110

Takes about 3-5 minutes from push to live.

## Current Status

✅ Backend API working
✅ Frontend responsive and tested
✅ JWT authentication implemented
✅ CircleCI CI/CD pipeline configured
✅ Deployed to AWS (Nginx + Gunicorn + SQLite)
✅ 52 tests passing

Everything's working and deployed!

## Key Features

**Authentication**: JWT tokens with auto-refresh
**External API**: Integrates with Norwegian Statens Vegvesen API
**State Management**: Pinia stores for auth state
**Routing**: Vue Router with protected routes
**Type Safety**: Full TypeScript on frontend
**Error Handling**: Proper error messages for users

## Environment Variables

The app uses different configs for dev/test/production:

- `.env.development` - Local development (localhost:8000)
- `.env.test` - Test environment (for Vitest)
- `.env.production` - Production (your server IP)

Vite automatically loads the right one based on the command you run.

## Common Commands

**Backend**:
```bash
python manage.py makemigrations   # After changing models
python manage.py migrate           # Apply database changes
python manage.py createsuperuser   # Create admin user
python manage.py test              # Run tests
```

**Frontend**:
```bash
npm run dev            # Dev server with hot reload
npm run build          # Build for production
npm test               # Run tests
npm run type-check     # TypeScript validation
```

**Server** (via SSH):
```bash
sudo systemctl restart gunicorn   # Restart backend
sudo systemctl reload nginx       # Reload web server
sudo journalctl -u gunicorn -f    # View backend logs
```

## Development Workflow

1. Create feature branch: `git checkout -b feature/my-feature`
2. Make your changes
3. Test locally: `npm test` + `python manage.py test`
4. Commit: `git commit -m "Add my feature"`
5. Push: `git push origin feature/my-feature`
6. CircleCI runs tests automatically
7. Merge to main when tests pass
8. Auto-deploys to AWS!

## Troubleshooting

**CORS errors?** Check that backend is on port 8000 and frontend on 5173.

**Can't login?** Clear localStorage in browser DevTools, or check if backend is running.

**Tests failing?** Make sure you're in the right directory and dependencies are installed.

**CircleCI deployment failing?** Check if sudo is configured for deploy user on AWS.

## What You'll Learn

This project demonstrates:
- REST API design with Django
- JWT authentication flow
- Frontend-backend integration
- State management (Pinia)
- Automated testing (unit tests)
- CI/CD with CircleCI
- Production deployment (AWS + Nginx)

Perfect for understanding how modern web apps work.

## License

Educational project. Feel free to use and learn from it!

---

**Live Demo**: http://18.217.70.110
**Questions?** The code is documented and includes tests you can learn from.

Built with Django + Vue.js. Deployed with CircleCI. Running on AWS.
