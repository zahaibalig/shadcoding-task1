# Project Gallery - Full-Stack Web Application

A modern full-stack web application built with Django REST Framework (backend) and Vue.js 3 (frontend). This project demonstrates a complete implementation of authentication, public/private routes, and CRUD operations.

## 📋 Table of Contents

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Features](#features)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Documentation](#documentation)
- [Screenshots](#screenshots)
- [Contributing](#contributing)

## 🎯 Overview

This is a project management application that allows:
- **Public users** to view a list of projects without authentication
- **Public users** to check Norwegian car registration details via Statens Vegvesen API
- **Authenticated administrators** to manage (create, update, delete) projects
- **Modern UI** with Vue.js 3 and TypeScript
- **RESTful API** with Django REST Framework
- **JWT Authentication** for secure access

## 🆕 What's New

**Latest Updates:**

- **Unit Testing** - Added comprehensive test coverage for both frontend and backend. We now have 52 tests total (35 frontend + 17 backend), all passing. You can run them with `npm test` and `python manage.py test`.

- **Bug Fix** - Fixed the error message when you enter a wrong car registration number. Instead of showing a confusing "Unknown error occurred" message, it now properly tells you to "enter a correct registration number."

- **Better Error Handling** - Improved how the app handles different API errors (404s, timeouts, rate limits) with clearer user-facing messages.

### Application Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                         Landing Page                              │
│                             (/)                                   │
│                                                                   │
│  [View Projects]  [Check Car Registration]  [Admin Login]       │
└──────┬──────────────────────┬────────────────────────┬───────────┘
       │                      │                        │
       │                      │                        │
       ▼                      ▼                        ▼
┌──────────────┐     ┌────────────────┐      ┌─────────────┐
│ Public View  │     │ Car Reg Check  │      │ Admin Login │
│ (/projects)  │     │ (/car-reg)     │      │  (/admin)   │
│              │     │                │      │             │
│ No auth req. │     │ No auth req.   │      │ Username/   │
│ View projects│     │ Lookup vehicle │      │ Password    │
└──────────────┘     │ info via API   │      └──────┬──────┘
                     └────────────────┘             │
                                                    ▼
                                           ┌─────────────────┐
                                           │ Admin Dashboard │
                                           │ (/admin/dash)   │
                                           │                 │
                                           │ Full CRUD       │
                                           │ Search/Filter   │
                                           └─────────────────┘
```

## 🛠 Tech Stack

### Backend
- **Python 3.x** - Programming language
- **Django 5.2.7** - Web framework
- **Django REST Framework 3.16.1** - API framework
- **SQLite** - Database (dev environment)
- **django-cors-headers** - CORS support
- **djangorestframework-simplejwt** - JWT authentication
- **requests** - HTTP client for external API calls
- **unittest.mock** - Testing framework (built-in)

### Frontend
- **Vue.js 3.5.22** - Progressive JavaScript framework
- **TypeScript 5.9.0** - Type-safe JavaScript
- **Vite 7.1.11** - Build tool and dev server
- **Vue Router 4.6.3** - Client-side routing
- **Pinia 3.0.3** - State management
- **Axios 1.12.2** - HTTP client for API calls
- **Vitest 3.0.0** - Unit testing framework
- **@vue/test-utils 2.4.6** - Vue component testing
- **jsdom** - DOM environment for tests

## ✨ Features

### Public Features (No Authentication Required)
- ✅ Landing page with navigation
- ✅ View all projects in a list
- ✅ See project details (name, description, status, dates)
- ✅ Check Norwegian car registration numbers
  - Look up vehicle brand, model, year
  - Get next EU approval date
  - Integration with Statens Vegvesen API
  - Handles invalid registrations gracefully
- ✅ About page with project information

### Admin Features (Authentication Required)
- ✅ Secure JWT-based login
- ✅ Create new projects
- ✅ Update existing projects
- ✅ Delete projects
- ✅ Search projects by name/description
- ✅ Filter projects by active status
- ✅ User welcome message
- ✅ Secure logout

### Technical Features
- ✅ RESTful API design
- ✅ Public GET endpoints (no auth)
- ✅ Protected POST/PUT/PATCH/DELETE endpoints (auth required)
- ✅ JWT token-based authentication with automatic refresh
- ✅ CORS configured for frontend-backend communication
- ✅ External API integration (Statens Vegvesen)
- ✅ TypeScript for type safety
- ✅ Responsive design (mobile-friendly)
- ✅ Error handling and loading states
- ✅ Modern UI with gradient backgrounds
- ✅ **Comprehensive unit tests** (52 tests across frontend and backend)
- ✅ Test coverage for API services, components, and views

## 📁 Project Structure

```
shadcoding-task1/
├── backend/                    # Django backend
│   ├── backend/               # Project settings
│   │   ├── settings.py       # Configuration
│   │   ├── urls.py           # Main URL routing
│   │   ├── wsgi.py          # WSGI config
│   │   └── asgi.py          # ASGI config
│   ├── projects/             # Projects app
│   │   ├── models.py        # Database models
│   │   ├── serializers.py   # DRF serializers
│   │   ├── views.py         # API views
│   │   ├── urls.py          # App URLs
│   │   ├── tests.py         # Unit tests
│   │   └── migrations/      # Database migrations
│   ├── vehicles/            # Vehicle lookup app
│   │   ├── views.py        # API views (Statens Vegvesen integration)
│   │   ├── urls.py         # App URLs
│   │   ├── tests.py        # Unit tests (17 tests)
│   │   └── migrations/     # Database migrations
│   ├── manage.py           # Django management script
│   ├── db.sqlite3         # SQLite database
│   ├── requirements.txt   # Python dependencies
│   └── .LEARNING_GUIDE.md # Comprehensive backend guide
│
├── frontend/                  # Vue.js frontend
│   ├── src/
│   │   ├── components/      # Reusable components
│   │   ├── views/          # Page components
│   │   │   ├── __tests__/              # Component tests
│   │   │   │   └── CarRegistrationView.test.ts (20 tests)
│   │   │   ├── LandingView.vue         # Home page
│   │   │   ├── ProjectsView.vue        # Public projects
│   │   │   ├── AboutView.vue           # About page
│   │   │   ├── CarRegistrationView.vue # Car lookup
│   │   │   ├── AdminDashboardView.vue  # Login page
│   │   │   └── HomeView.vue            # Admin dashboard
│   │   ├── router/         # Vue Router config
│   │   │   └── index.ts   # Route definitions
│   │   ├── stores/        # Pinia stores
│   │   │   └── auth.ts   # Authentication state
│   │   ├── services/     # API services
│   │   │   ├── __tests__/          # Service tests
│   │   │   │   └── api.test.ts    (15 tests)
│   │   │   └── api.ts            # Axios configuration
│   │   ├── types/       # TypeScript types
│   │   │   ├── project.ts
│   │   │   └── vehicle.ts
│   │   ├── assets/     # Static assets
│   │   ├── App.vue    # Root component
│   │   └── main.ts   # App entry point
│   ├── public/            # Public static files
│   ├── package.json      # npm dependencies
│   ├── vite.config.ts   # Vite configuration
│   ├── vitest.config.ts # Vitest test configuration
│   ├── tsconfig.json   # TypeScript config
│   └── README.md      # Frontend documentation
│
├── API_DOCUMENTATION.md    # Complete API reference
├── DEPLOYMENT.md          # Deployment guide
└── README.md             # This file
```

## 🚀 Quick Start

### Prerequisites

- Python 3.x installed
- Node.js 20.19+ or 22.12+ installed
- npm or yarn package manager

### 1. Clone the Repository

```bash
git clone <repository-url>
cd shadcoding-task1
```

### 2. Backend Setup

```bash
# Navigate to backend directory
cd backend

# Create virtual environment (optional but recommended)
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run migrations
python3 manage.py migrate

# Create superuser (for admin access)
python3 manage.py createsuperuser
# Username: admin
# Password: admin123 (or your choice)

# Start development server
python3 manage.py runserver
```

Backend will be available at: `http://localhost:8000`

### 3. Frontend Setup

Open a new terminal:

```bash
# Navigate to frontend directory
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

Frontend will be available at: `http://localhost:5173`

### 4. Access the Application

- **Landing Page**: http://localhost:5173
- **View Projects** (public): http://localhost:5173/projects
- **Car Registration Check** (public): http://localhost:5173/car-registration
- **About Page**: http://localhost:5173/about
- **Admin Login**: http://localhost:5173/admin
- **Admin Dashboard** (after login): http://localhost:5173/admin/dashboard

**Default Admin Credentials:**
- Username: `admin`
- Password: `admin123` (or what you set during createsuperuser)

## 📚 Documentation

### Comprehensive Guides

- **[Backend Learning Guide](backend/.LEARNING_GUIDE.md)** - Complete beginner's guide to Django and DRF
- **[Frontend Documentation](frontend/README.md)** - Vue.js 3 with TypeScript guide
- **[API Documentation](API_DOCUMENTATION.md)** - Complete API reference with examples
- **[Deployment Guide](DEPLOYMENT.md)** - How to deploy this application

### Quick Links

**Backend:**
- Django Documentation: https://docs.djangoproject.com/
- DRF Documentation: https://www.django-rest-framework.org/

**Frontend:**
- Vue.js 3 Documentation: https://vuejs.org/
- Vite Documentation: https://vite.dev/
- Pinia Documentation: https://pinia.vuejs.org/

## 📸 Screenshots

### Landing Page
The main entry point with navigation buttons.

### Public Projects View
List of all projects accessible without login.

### Admin Login
Secure login form for administrators.

### Admin Dashboard
Full project management interface with search and filter capabilities.

## 🔑 Key Concepts

### Authentication Flow

```
1. User enters credentials on /admin login page
2. Frontend sends POST to /api/auth/jwt/create/
3. Backend validates and returns JWT tokens (access + refresh)
4. Frontend stores tokens in localStorage
5. Axios interceptor adds token to all API requests
6. Protected routes check for valid token
7. Token auto-refreshes on 401 errors
```

### API Access Patterns

| Endpoint | Method | Public Access | Auth Required |
|----------|--------|---------------|---------------|
| GET /api/projects/ | List all | ✅ Yes | ❌ No |
| GET /api/projects/:id/ | Single | ✅ Yes | ❌ No |
| POST /api/projects/ | Create | ❌ No | ✅ Yes |
| PUT /api/projects/:id/ | Update | ❌ No | ✅ Yes |
| PATCH /api/projects/:id/ | Partial update | ❌ No | ✅ Yes |
| DELETE /api/projects/:id/ | Delete | ❌ No | ✅ Yes |
| GET /api/vehicles/lookup/ | Vehicle info | ✅ Yes | ❌ No |

## 🧪 Testing

We've got pretty solid test coverage now - 52 tests total between frontend and backend. They all pass, which is nice.

### Backend Tests (Django + unittest)

**17 tests** covering the vehicle lookup API:

```bash
cd backend
python3 manage.py test vehicles
```

What's tested:
- Valid registration lookups (success case)
- Invalid/non-existent registrations (the 404 error we just fixed)
- Missing or empty registration numbers
- API timeout and connection errors
- Rate limiting (50k calls/day limit)
- Authentication errors (bad API key)
- Edge cases like empty response data
- Case-insensitive input handling

All tests use mocks, so you don't need an actual API key to run them.

### Frontend Tests (Vitest + Vue Test Utils)

**35 tests** across API services and components:

```bash
cd frontend
npm test
```

**Service tests** (15 tests in `api.test.ts`):
- Vehicle lookup with different scenarios
- Auth service (login, user info)
- Project CRUD operations
- Error handling for network failures

**Component tests** (20 tests in `CarRegistrationView.test.ts`):
- Component rendering
- Form validation (empty input, button states)
- Successful vehicle lookups
- Loading states
- Error messages (404s, network errors, rate limits)
- Data clearing between searches

**Other useful test commands:**

```bash
npm run test:ui       # Opens Vitest UI (nice visual interface)
npm run test:coverage # Shows which code is/isn't covered
```

The coverage report gets generated in `frontend/coverage/` if you're curious.

### Type Checking

Frontend uses TypeScript, so run this occasionally to catch type errors:

```bash
cd frontend
npm run type-check
```

### API Testing with Postman

If you want to test the actual API endpoints manually, check out [API_DOCUMENTATION.md](API_DOCUMENTATION.md) for examples with curl and Postman.

## 🐛 Troubleshooting

### Common Issues

**1. CORS Errors**
- Ensure backend is running on port 8000
- Ensure frontend is running on port 5173 or 5174
- Check `CORS_ALLOWED_ORIGINS` in `backend/backend/settings.py`

**2. Authentication Not Working**
- Clear localStorage: `localStorage.clear()`
- Check that Pinia is initialized in `main.ts`
- Verify JWT tokens in browser DevTools → Application → Local Storage

**3. Database Errors**
- Run migrations: `python3 manage.py migrate`
- Reset database: Delete `db.sqlite3` and run migrations again

**4. Frontend Build Errors**
- Clear node_modules: `rm -rf node_modules && npm install`
- Check Node.js version: `node --version` (should be 20.19+ or 22.12+)

## 🤝 Contributing

This is a learning project. Feel free to:
- Fork the repository
- Create feature branches
- Submit pull requests
- Report issues
- Suggest improvements

## 📝 License

This project is for educational purposes.

## 👨‍💻 Author

Created as a full-stack learning project demonstrating modern web development practices.

---

## 🎓 Learning Outcomes

By building this project, you've learned:

✅ **Backend Development:**
- Django project structure and configuration
- Django REST Framework for building APIs
- Database modeling with Django ORM
- JWT authentication implementation
- CORS configuration for cross-origin requests
- Permission classes for access control
- External API integration (calling third-party APIs)
- Writing unit tests with Django's test framework

✅ **Frontend Development:**
- Vue.js 3 Composition API
- TypeScript for type-safe code
- Vue Router for client-side routing
- Pinia for state management
- Axios for HTTP requests with interceptors
- Component architecture and props
- Unit testing with Vitest and Vue Test Utils
- Mocking API calls in tests

✅ **Full-Stack Integration:**
- RESTful API design
- Frontend-backend communication
- Authentication flow (login, token storage, auto-refresh)
- Public vs protected routes
- Error handling and loading states
- Testing both sides of the stack

✅ **Best Practices:**
- Separation of concerns
- DRY (Don't Repeat Yourself) principles
- Security considerations
- Code organization
- Documentation
- Test-driven development mindset
- User-friendly error messages

---

**Happy Coding! 🚀**

For detailed guides, see the documentation files listed above.
