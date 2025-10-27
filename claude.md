# Claude Code Project Context - ShadCoding Task1

> **Purpose**: This file provides comprehensive context about the project for Claude Code sessions.
> **Last Updated**: 2025-10-27
> **DO NOT commit this file to Git** - Added to .gitignore

---

## 📋 Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Directory Structure](#directory-structure)
5. [Key Components](#key-components)
6. [API Endpoints](#api-endpoints)
7. [Authentication Flow](#authentication-flow)
8. [Deployment Information](#deployment-information)
9. [Configuration Files](#configuration-files)
10. [Testing](#testing)
11. [Current Status](#current-status)
12. [Common Tasks](#common-tasks)

---

## 1. Project Overview

**Project Name**: ShadCoding Task1 - Full-Stack Portfolio Gallery Application
**Type**: Full-Stack Web Application
**Purpose**: Portfolio project gallery with vehicle registration lookup (Norwegian Statens Vegvesen API integration)

**Key Features**:
- Public project gallery (CRUD operations)
- Vehicle registration lookup (Norwegian license plates)
- JWT-based authentication
- Admin dashboard
- Responsive design
- RESTful API architecture

**Deployment**:
- **Production Domain**: zohaib.no (and www.zohaib.no)
- **Server**: AWS Ubuntu 20.04/22.04 LTS
- **Server IP**: 18.223.101.101
- **SSH User**: ubuntu
- **Deploy User**: deploy (used for running services)

---

## 2. Architecture

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────────┐
│                    GitHub Repository                         │
│                      (main branch)                           │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│                   CircleCI Pipeline                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Test Backend │  │Test Frontend │  │Build Frontend│     │
│  │  (17 tests)  │  │  (35 tests)  │  │  (Vite)      │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Deploy via SSH                             │  │
│  └──────────────────────────────────────────────────────┘  │
└───────────────────────┬─────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────┐
│              AWS Ubuntu Server (18.223.101.101)             │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                 Nginx (Port 80/443)                   │  │
│  │  - Serves Vue.js static files                         │  │
│  │  - Reverse proxy to Gunicorn                          │  │
│  │  - SSL termination (Let's Encrypt)                    │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                          │
│                   ▼                                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │            Gunicorn (Port 8000)                       │  │
│  │  - WSGI application server                            │  │
│  │  - Runs Django backend                                │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                          │
│                   ▼                                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │        Django Application (Python 3.11)               │  │
│  │  - REST API endpoints                                 │  │
│  │  - JWT authentication                                 │  │
│  │  - Database operations                                │  │
│  └────────────────┬─────────────────────────────────────┘  │
│                   │                                          │
│                   ▼                                          │
│  ┌──────────────────────────────────────────────────────┐  │
│  │          SQLite Database (db.sqlite3)                 │  │
│  │  - Projects data                                      │  │
│  │  - User authentication                                │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Client-Server Communication
```
Browser (Vue.js 3 SPA)
    │
    │ HTTP/HTTPS Requests
    ▼
Nginx (:80/:443)
    │
    ├─── Static Files: /var/www/shadcoding/frontend/ (Vue build)
    │
    └─── API Proxy: /api/* → Gunicorn (:8000) → Django
```

### Request Flow Example
1. User visits `https://zohaib.no`
2. Nginx serves `index.html` from Vue.js build
3. Vue.js app loads, makes API call to `/api/projects/`
4. Nginx proxies request to Gunicorn at `http://127.0.0.1:8000/api/projects/`
5. Django processes request, queries SQLite
6. JSON response sent back through chain
7. Vue.js renders data

---

## 3. Technology Stack

### Backend Stack
| Technology | Version | Purpose |
|------------|---------|---------|
| Python | 3.11 | Programming language |
| Django | 5.2.7 | Web framework |
| Django REST Framework | 3.16.1 | RESTful API |
| djangorestframework-simplejwt | 5.3.1 | JWT authentication |
| django-cors-headers | 4.9.0 | CORS management |
| Gunicorn | 21.2.0 | WSGI server |
| SQLite | 3.x | Database (default) |
| requests | 2.31.0 | HTTP client for external APIs |
| python-decouple | 3.8 | Environment config management |

### Frontend Stack
| Technology | Version | Purpose |
|------------|---------|---------|
| Vue.js | 3.5.22 | Frontend framework |
| TypeScript | 5.9.0 | Type safety |
| Vite | 7.1.11 | Build tool & dev server |
| Vue Router | 4.6.3 | Client-side routing |
| Pinia | 3.0.3 | State management |
| Axios | 1.12.2 | HTTP client |
| Vitest | 3.0.0 | Unit testing framework |
| @vue/test-utils | 2.4.6 | Component testing utilities |

### Infrastructure
| Technology | Purpose |
|------------|---------|
| Nginx | Web server & reverse proxy |
| Let's Encrypt | SSL certificates |
| CircleCI | CI/CD pipeline |
| UFW | Firewall |
| Systemd | Service management |

---

## 4. Directory Structure

```
shadcoding-task1/
│
├── backend/                          # Django Backend Application
│   ├── backend/                      # Django project settings
│   │   ├── __init__.py
│   │   ├── settings.py              # Main Django settings
│   │   ├── urls.py                  # Root URL configuration
│   │   ├── wsgi.py                  # WSGI entry point
│   │   └── asgi.py                  # ASGI entry point
│   │
│   ├── projects/                    # Projects App (CRUD)
│   │   ├── models.py                # Project model (name, description, status)
│   │   ├── serializers.py           # DRF serializers
│   │   ├── views.py                 # ViewSets (list, create, update, delete)
│   │   ├── urls.py                  # App URL patterns
│   │   ├── tests.py                 # Unit tests
│   │   ├── admin.py                 # Django admin configuration
│   │   └── migrations/              # Database migrations
│   │
│   ├── vehicles/                    # Vehicle Lookup App
│   │   ├── views.py                 # Statens Vegvesen API integration
│   │   ├── urls.py                  # Vehicle API endpoints
│   │   ├── tests.py                 # 17 unit tests (API mocking)
│   │   └── migrations/
│   │
│   ├── manage.py                    # Django management CLI
│   ├── db.sqlite3                   # SQLite database file
│   ├── gunicorn.conf.py             # Gunicorn configuration
│   ├── requirements.txt             # Python dependencies
│   └── .LEARNING_GUIDE.md           # Backend learning documentation
│
├── frontend/                         # Vue.js Frontend Application
│   ├── src/
│   │   ├── components/              # Reusable Vue components
│   │   │   ├── NavBar.vue
│   │   │   ├── ProjectCard.vue
│   │   │   └── ...
│   │   │
│   │   ├── views/                   # Page-level components
│   │   │   ├── __tests__/          # Component unit tests
│   │   │   ├── LandingView.vue     # Public landing page
│   │   │   ├── ProjectsView.vue    # Public projects gallery
│   │   │   ├── CarRegistrationView.vue  # Vehicle lookup
│   │   │   ├── AdminDashboardView.vue   # Login page
│   │   │   └── HomeView.vue        # Admin dashboard (protected)
│   │   │
│   │   ├── router/
│   │   │   └── index.ts            # Vue Router configuration
│   │   │
│   │   ├── stores/                  # Pinia state stores
│   │   │   └── auth.ts             # Authentication state
│   │   │
│   │   ├── services/                # API services
│   │   │   ├── __tests__/          # Service unit tests (15 tests)
│   │   │   └── api.ts              # Axios configuration & interceptors
│   │   │
│   │   ├── types/                   # TypeScript type definitions
│   │   │   └── index.ts
│   │   │
│   │   ├── assets/                  # Static assets (CSS, images)
│   │   ├── App.vue                  # Root component
│   │   └── main.ts                  # Application entry point
│   │
│   ├── public/                      # Public static files
│   ├── package.json                 # npm dependencies
│   ├── vite.config.ts              # Vite build configuration
│   ├── vitest.config.ts            # Vitest test configuration
│   ├── tsconfig.json               # TypeScript configuration
│   └── README.md                   # Frontend documentation
│
├── deployment/                      # Deployment Scripts & Configs
│   ├── setup-server.sh             # Initial server setup (Ubuntu)
│   ├── deploy.sh                   # Automated deployment script
│   ├── setup-ssl.sh                # Let's Encrypt SSL setup
│   ├── nginx.conf                  # Nginx virtual host configuration
│   ├── gunicorn.service            # Systemd service unit file
│   └── .env.production             # Production environment template
│
├── .circleci/
│   └── config.yml                  # CircleCI CI/CD pipeline
│
├── .gitignore                       # Git ignore patterns
├── claude.md                        # This file (project context for Claude)
├── README.md                        # Main project documentation
├── DEPLOYMENT.md                    # Comprehensive deployment guide
├── QUICK_START.md                   # Quick deployment guide for AWS
└── API_DOCUMENTATION.md             # Complete API reference
```

---

## 5. Key Components

### Backend Components

#### 1. Django Settings (backend/backend/settings.py)
**Key Configurations**:
- `SECRET_KEY`: Loaded from environment variable
- `DEBUG`: Set to False in production
- `ALLOWED_HOSTS`: Whitelist of allowed domains/IPs
- `CORS_ALLOWED_ORIGINS`: Frontend URLs for CORS
- `REST_FRAMEWORK`: DRF settings including JWT auth
- `SIMPLE_JWT`: JWT token configuration (5min access, 1day refresh)
- Database: SQLite default, PostgreSQL support via DATABASE_URL

#### 2. Projects App (backend/projects/)
**Model: Project**
```python
class Project(models.Model):
    name = models.CharField(max_length=200)
    description = models.TextField()
    status = models.CharField(max_length=50, choices=[
        ('planning', 'Planning'),
        ('in_progress', 'In Progress'),
        ('completed', 'Completed'),
    ])
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
```

**ViewSet**: `ProjectViewSet` (ModelViewSet)
- List projects (public)
- Retrieve project (public)
- Create project (authenticated)
- Update project (authenticated)
- Delete project (authenticated)

#### 3. Vehicles App (backend/vehicles/)
**Purpose**: Integrate with Statens Vegvesen (Norwegian Vehicle Authority) API

**View: VehicleLookupView**
- Endpoint: `/api/vehicles/lookup/?registration={PLATE}`
- External API: `https://www.vegvesen.no/ws/no/vegvesen/kjoretoy/felles/datautlevering/enkeltoppslag/kjoretoydata`
- Returns: Vehicle make, model, year, color, etc.
- Error handling: Rate limiting, timeouts, invalid plates

**Tests**: 17 unit tests covering:
- Valid registrations
- Invalid registrations
- API timeouts
- Rate limiting
- Missing query parameters

### Frontend Components

#### 1. Main Application (frontend/src/main.ts)
**Initialization**:
```typescript
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import router from './router'
import App from './App.vue'

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
```

#### 2. API Service (frontend/src/services/api.ts)
**Axios Configuration**:
```typescript
const api = axios.create({
  baseURL: 'https://zohaib.no/api',  // Production
  // baseURL: 'http://localhost:8000/api',  // Development
})

// Request interceptor - adds JWT token
api.interceptors.request.use(config => {
  const token = localStorage.getItem('access_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// Response interceptor - handles token refresh
api.interceptors.response.use(
  response => response,
  async error => {
    if (error.response?.status === 401) {
      // Attempt token refresh
      // If refresh fails, redirect to login
    }
  }
)
```

#### 3. Authentication Store (frontend/src/stores/auth.ts)
**Pinia Store**:
```typescript
export const useAuthStore = defineStore('auth', {
  state: () => ({
    isAuthenticated: false,
    user: null,
  }),
  actions: {
    async login(username: string, password: string) { ... },
    logout() { ... },
    async checkAuth() { ... },
  }
})
```

#### 4. Router (frontend/src/router/index.ts)
**Routes**:
- `/` - LandingView (public)
- `/projects` - ProjectsView (public)
- `/car-registration` - CarRegistrationView (public)
- `/admin` - AdminDashboardView (login page)
- `/dashboard` - HomeView (protected, requires auth)

**Navigation Guards**:
```typescript
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  if (to.meta.requiresAuth && !authStore.isAuthenticated) {
    next('/admin')
  } else {
    next()
  }
})
```

---

## 6. API Endpoints

### Base URL
- **Production**: `https://zohaib.no/api/`
- **Development**: `http://localhost:8000/api/`

### Authentication Endpoints

#### Login (Obtain JWT Tokens)
```
POST /api/auth/jwt/create/
Content-Type: application/json

Request:
{
  "username": "admin",
  "password": "password123"
}

Response (200 OK):
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

#### Refresh Access Token
```
POST /api/auth/jwt/refresh/
Content-Type: application/json

Request:
{
  "refresh": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}

Response (200 OK):
{
  "access": "eyJ0eXAiOiJKV1QiLCJhbGc..."
}
```

### Project Endpoints

#### List All Projects (Public)
```
GET /api/projects/

Response (200 OK):
[
  {
    "id": 1,
    "name": "Portfolio Website",
    "description": "Personal portfolio built with Vue.js",
    "status": "completed",
    "created_at": "2025-01-15T10:30:00Z",
    "updated_at": "2025-01-20T14:45:00Z"
  },
  ...
]
```

#### Get Single Project (Public)
```
GET /api/projects/{id}/

Response (200 OK):
{
  "id": 1,
  "name": "Portfolio Website",
  "description": "Personal portfolio built with Vue.js",
  "status": "completed",
  "created_at": "2025-01-15T10:30:00Z",
  "updated_at": "2025-01-20T14:45:00Z"
}
```

#### Create Project (Authenticated)
```
POST /api/projects/
Authorization: Bearer {access_token}
Content-Type: application/json

Request:
{
  "name": "New Project",
  "description": "Project description",
  "status": "planning"
}

Response (201 Created):
{
  "id": 2,
  "name": "New Project",
  "description": "Project description",
  "status": "planning",
  "created_at": "2025-01-27T12:00:00Z",
  "updated_at": "2025-01-27T12:00:00Z"
}
```

#### Update Project (Authenticated)
```
PUT /api/projects/{id}/
Authorization: Bearer {access_token}
Content-Type: application/json

Request:
{
  "name": "Updated Project Name",
  "description": "Updated description",
  "status": "in_progress"
}

Response (200 OK):
{ ... updated project ... }
```

#### Delete Project (Authenticated)
```
DELETE /api/projects/{id}/
Authorization: Bearer {access_token}

Response (204 No Content)
```

### Vehicle Lookup Endpoint

#### Lookup Vehicle by Registration (Public)
```
GET /api/vehicles/lookup/?registration=ABC123

Response (200 OK):
{
  "registration": "ABC123",
  "make": "Toyota",
  "model": "Corolla",
  "year": 2020,
  "color": "Blue",
  "fuel_type": "Gasoline"
}

Error Response (404):
{
  "error": "Vehicle not found"
}
```

---

## 7. Authentication Flow

### Login Flow
```
1. User enters credentials on /admin page
   ↓
2. Frontend sends POST to /api/auth/jwt/create/
   ↓
3. Django validates credentials
   ↓
4. Django returns { access, refresh } tokens
   ↓
5. Frontend stores tokens in localStorage
   ↓
6. Frontend sets isAuthenticated = true
   ↓
7. Router redirects to /dashboard
```

### Protected Request Flow
```
1. User navigates to protected route (/dashboard)
   ↓
2. Router guard checks isAuthenticated
   ↓
3. If not authenticated → redirect to /admin
   ↓
4. If authenticated → allow navigation
   ↓
5. Component makes API request (e.g., GET /api/projects/)
   ↓
6. Axios interceptor adds "Authorization: Bearer {token}"
   ↓
7. Django validates JWT token
   ↓
8. If valid → return data
   ↓
9. If expired → return 401
   ↓
10. Axios interceptor catches 401
    ↓
11. Attempts token refresh with refresh token
    ↓
12. If refresh succeeds → retry original request
    ↓
13. If refresh fails → logout and redirect to /admin
```

### Token Expiration
- **Access Token**: 5 minutes (short-lived)
- **Refresh Token**: 1 day (long-lived)
- Stored in: `localStorage`
  - `localStorage.getItem('access_token')`
  - `localStorage.getItem('refresh_token')`

---

## 8. Deployment Information

### Server Details
- **Provider**: AWS (Amazon Web Services)
- **OS**: Ubuntu 20.04/22.04 LTS
- **IP Address**: 18.223.101.101
- **Domain**: zohaib.no, www.zohaib.no
- **SSH User**: ubuntu
- **Deploy User**: deploy (runs Gunicorn, owns project files)

### Server Paths
```
/home/deploy/shadcoding-task1/               # Project root
├── backend/
│   ├── db.sqlite3                           # SQLite database
│   ├── staticfiles/                         # Collected Django static files
│   └── media/                               # User-uploaded files (optional)
│
└── frontend/
    └── dist/                                # Vite build output

/var/www/shadcoding/
└── frontend/                                # Nginx serves from here
    ├── index.html
    ├── assets/
    └── ...

/etc/nginx/sites-available/shadcoding        # Nginx config
/etc/nginx/sites-enabled/shadcoding          # Symlink to above

/etc/systemd/system/gunicorn.service         # Gunicorn systemd service

/var/log/gunicorn/                           # Gunicorn logs
/var/log/nginx/                              # Nginx logs
```

### Service Management Commands
```bash
# Gunicorn (Django backend)
sudo systemctl status gunicorn
sudo systemctl start gunicorn
sudo systemctl stop gunicorn
sudo systemctl restart gunicorn
sudo systemctl reload gunicorn

# Nginx (web server)
sudo systemctl status nginx
sudo systemctl start nginx
sudo systemctl stop nginx
sudo systemctl restart nginx
sudo systemctl reload nginx

# Check logs
sudo journalctl -u gunicorn -f              # Gunicorn logs
sudo tail -f /var/log/gunicorn/error.log    # Gunicorn error log
sudo tail -f /var/log/nginx/access.log      # Nginx access log
sudo tail -f /var/log/nginx/error.log       # Nginx error log
```

### Environment Variables Location
```
/home/deploy/shadcoding-task1/backend/.env
```

### Deployment Process (Automated via CircleCI)
1. Code pushed to GitHub `main` branch
2. CircleCI triggers pipeline:
   - Run backend tests (17 tests)
   - Run frontend tests (35 tests)
   - Build frontend (Vite)
   - SSH to server and run `deployment/deploy.sh`
3. `deploy.sh` script:
   - Pull latest code from Git
   - Install Python dependencies
   - Run Django migrations
   - Collect static files
   - Build frontend with Vite
   - Copy frontend build to `/var/www/shadcoding/frontend/`
   - Restart Gunicorn
   - Reload Nginx

### Manual Deployment
```bash
# SSH into server
ssh ubuntu@18.223.101.101

# Switch to deploy user
sudo su - deploy

# Navigate to project
cd ~/shadcoding-task1

# Run deployment script
bash deployment/deploy.sh
```

---

## 9. Configuration Files

### 1. backend/.env (Production)
**Location**: `/home/deploy/shadcoding-task1/backend/.env`

**Key Variables**:
```bash
SECRET_KEY=<50-char-random-string>
DEBUG=False
ALLOWED_HOSTS=zohaib.no,www.zohaib.no,18.223.101.101
STATENS_VEGVESEN_API_KEY=fea6488c-bf34-4326-8b83-d1cb5e25d810
CSRF_TRUSTED_ORIGINS=https://zohaib.no,https://www.zohaib.no
SECURE_SSL_REDIRECT=True
SESSION_COOKIE_SECURE=True
CSRF_COOKIE_SECURE=True
```

### 2. Nginx Configuration
**Location**: `/etc/nginx/sites-available/shadcoding`

**Key Sections**:
- HTTP → HTTPS redirect (port 80 → 443)
- SSL certificate paths (Let's Encrypt)
- Static file serving: `/var/www/shadcoding/frontend/`
- API proxy: `/api/` → `http://127.0.0.1:8000/api/`
- Django admin proxy: `/admin/` → `http://127.0.0.1:8000/admin/`
- Django static: `/static/` → project staticfiles
- Security headers (HSTS, X-Frame-Options, etc.)

### 3. Gunicorn Configuration
**Location**: `/home/deploy/shadcoding-task1/backend/gunicorn.conf.py`

**Key Settings**:
```python
bind = '127.0.0.1:8000'
workers = 4  # CPU cores * 2 + 1
worker_class = 'sync'
max_requests = 1000
timeout = 30
accesslog = '/var/log/gunicorn/access.log'
errorlog = '/var/log/gunicorn/error.log'
loglevel = 'info'
```

### 4. Systemd Service
**Location**: `/etc/systemd/system/gunicorn.service`

**Configuration**:
```ini
[Unit]
Description=Gunicorn daemon for ShadCoding Django app
After=network.target

[Service]
User=deploy
Group=deploy
WorkingDirectory=/home/deploy/shadcoding-task1/backend
EnvironmentFile=/home/deploy/shadcoding-task1/backend/.env
ExecStart=/home/deploy/shadcoding-task1/venv/bin/gunicorn \
          --config gunicorn.conf.py \
          backend.wsgi:application

[Install]
WantedBy=multi-user.target
```

### 5. CircleCI Configuration
**Location**: `.circleci/config.yml`

**Pipeline Jobs**:
1. `test-backend` - Python 3.11 executor
2. `test-frontend` - Node 20.19 executor
3. `build-frontend` - Node 20.19 executor
4. `deploy` - SSH to server, run deploy.sh

**Workflow**: Sequential execution, only on `main` branch

---

## 10. Testing

### Backend Tests
**Framework**: Django unittest + unittest.mock
**Location**: `backend/vehicles/tests.py`
**Count**: 17 tests

**Test Coverage**:
- Valid vehicle registration lookup
- Invalid registration handling
- API timeout handling
- Rate limiting
- Missing query parameters
- API error responses

**Run Tests**:
```bash
cd backend
python manage.py test vehicles
```

### Frontend Tests
**Framework**: Vitest + Vue Test Utils
**Location**: `frontend/src/**/__tests__/`
**Count**: 35 tests (15 service + 20 component)

**Test Coverage**:
- API service tests (axios mocking)
- Component rendering tests
- User interaction tests
- Router navigation tests
- Store state management tests

**Run Tests**:
```bash
cd frontend
npm test                 # Run all tests
npm run test:ui          # Visual test interface
npm run test:coverage    # Coverage report
```

### E2E Testing
**Status**: Not currently implemented
**Recommended**: Playwright or Cypress for future implementation

---

## 11. Current Status

### Git Status
- **Current Branch**: main
- **Main Branch**: main (for PRs)
- **Modified Files**: deployment/setup-server.sh

### Recent Commits
1. `346e179` - "added deployement config"
2. `c0a6a12` - "Merge origin/dev into main: drop __pycache__/*.pyc and add .gitignore"
3. `f807079` - "chore(git): ignore Python bytecode (__pycache__, *.pyc) and venv"

### Deployment Status
- **Server**: Configured and running (18.223.101.101)
- **DNS**: NOT YET CONFIGURED (zohaib.no not pointing to server)
- **SSL**: Claimed installed, but likely non-functional without DNS
- **Database**: SQLite (development database exists)
- **Services**: Gunicorn and Nginx should be running

### Current Issues
1. **DNS Not Configured**: Domain zohaib.no is not pointing to server IP
2. **SSL Concern**: SSL cannot work properly without DNS configured
3. **.env Configuration**: Needs proper configuration for current deployment state

---

## 12. Common Tasks

### Adding a New Feature

#### Backend (Django)
```bash
# Create new app
cd backend
python manage.py startapp new_app

# Add to INSTALLED_APPS in settings.py
# Create models, views, serializers
# Add URL patterns
# Create migrations
python manage.py makemigrations
python manage.py migrate

# Write tests in new_app/tests.py
python manage.py test new_app
```

#### Frontend (Vue.js)
```bash
cd frontend

# Create new component
touch src/components/NewComponent.vue

# Create new view
touch src/views/NewView.vue

# Add route in src/router/index.ts
# Add API service in src/services/api.ts

# Write tests
touch src/components/__tests__/NewComponent.spec.ts
npm test
```

### Updating Dependencies

#### Backend
```bash
cd backend
pip list --outdated              # Check outdated packages
pip install --upgrade package_name
pip freeze > requirements.txt
```

#### Frontend
```bash
cd frontend
npm outdated                     # Check outdated packages
npm update                       # Update all packages
npm install package@latest       # Update specific package
```

### Database Operations

#### Create Superuser
```bash
cd backend
python manage.py createsuperuser
```

#### Database Migrations
```bash
# Create migrations after model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Show migration status
python manage.py showmigrations

# Revert migration
python manage.py migrate app_name previous_migration_name
```

#### Database Backup (SQLite)
```bash
# On server
cp /home/deploy/shadcoding-task1/backend/db.sqlite3 \
   /home/deploy/backups/db_$(date +%Y%m%d_%H%M%S).sqlite3
```

### Debugging

#### Check Application Logs
```bash
# Gunicorn logs
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/gunicorn/error.log

# Nginx logs
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Django debug (temporarily set DEBUG=True in .env)
# Check logs in journalctl or gunicorn error log
```

#### Test API Endpoints
```bash
# Test from server
curl http://127.0.0.1:8000/api/projects/

# Test from outside
curl https://zohaib.no/api/projects/

# Test with authentication
curl -H "Authorization: Bearer YOUR_TOKEN" \
     https://zohaib.no/api/projects/
```

#### Verify Services Running
```bash
# Check if Gunicorn is running
sudo systemctl status gunicorn
ps aux | grep gunicorn

# Check if Nginx is running
sudo systemctl status nginx
ps aux | grep nginx

# Check port 8000 (Gunicorn)
sudo netstat -tlnp | grep :8000

# Check ports 80/443 (Nginx)
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### Performance Optimization

#### Frontend
```bash
cd frontend

# Analyze bundle size
npm run build -- --mode production
npx vite-bundle-visualizer

# Optimize images
# Use lazy loading for routes
# Implement code splitting
```

#### Backend
```bash
# Use Django Debug Toolbar (dev only)
pip install django-debug-toolbar

# Add database indexes
# Optimize queries (select_related, prefetch_related)
# Implement caching (Redis)
# Use database query logging
```

### Security Audit

#### Check for Vulnerabilities
```bash
# Backend
cd backend
pip install safety
safety check

# Frontend
cd frontend
npm audit
npm audit fix
```

#### Security Checklist
- [ ] DEBUG=False in production
- [ ] Strong SECRET_KEY
- [ ] ALLOWED_HOSTS properly configured
- [ ] CSRF_TRUSTED_ORIGINS set
- [ ] SSL redirect enabled
- [ ] Secure cookies enabled
- [ ] No secrets in Git
- [ ] Dependencies up to date
- [ ] Regular security updates
- [ ] Database backups configured

---

## Quick Reference Commands

### Local Development
```bash
# Start backend
cd backend
python manage.py runserver

# Start frontend
cd frontend
npm run dev

# Run tests
cd backend && python manage.py test
cd frontend && npm test
```

### Production Deployment
```bash
# SSH to server
ssh ubuntu@18.223.101.101

# Manual deploy
sudo su - deploy
cd ~/shadcoding-task1
bash deployment/deploy.sh

# Restart services
sudo systemctl restart gunicorn
sudo systemctl reload nginx
```

### Monitoring
```bash
# Check service status
sudo systemctl status gunicorn nginx

# View logs
sudo journalctl -u gunicorn -f
sudo tail -f /var/log/nginx/error.log

# Check disk space
df -h

# Check memory
free -h

# Check CPU
top
```

---

## Important Notes

1. **Never commit sensitive data**: Always use .env for secrets
2. **Test before deploying**: CircleCI enforces this, but test locally too
3. **Database backups**: Implement regular backup strategy for SQLite
4. **SSL renewal**: Let's Encrypt auto-renews via Certbot
5. **Monitoring**: Consider setting up proper monitoring (Sentry, etc.)
6. **Scaling**: If traffic grows, migrate to PostgreSQL and consider load balancing

---

## External Resources

- **Django Documentation**: https://docs.djangoproject.com/
- **Django REST Framework**: https://www.django-rest-framework.org/
- **Vue.js Documentation**: https://vuejs.org/guide/
- **Statens Vegvesen API**: https://www.vegvesen.no/
- **Let's Encrypt**: https://letsencrypt.org/
- **CircleCI Docs**: https://circleci.com/docs/

---

**End of Context Document**
