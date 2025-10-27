from pathlib import Path
from decouple import config

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = config('SECRET_KEY', default='django-insecure-your-secret-key-change-this-in-production')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = config('DEBUG', default=True, cast=bool)

# Statens Vegvesen API Key
STATENS_VEGVESEN_API_KEY = config('STATENS_VEGVESEN_API_KEY', default='')

# Read from .env: comma-separated list like "domain.com,www.domain.com,ip"
ALLOWED_HOSTS = config('ALLOWED_HOSTS', default='localhost,127.0.0.1').split(',')

# URL Configuration
ROOT_URLCONF = 'backend.urls'

# WSGI Application
WSGI_APPLICATION = 'backend.wsgi.application'

# Database
# https://docs.djangoproject.com/en/5.2/ref/settings/#databases
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}

# Password validation
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Default primary key field type
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

INSTALLED_APPS = [
    # Django defaults...
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third-party
    'rest_framework',
    'corsheaders',

    # Local
    'projects',
    'vehicles',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',  # must be high in the list
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',  # keep this for session auth safety
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

# Allow your Vue dev server (adjust host/port as needed)
CORS_ALLOWED_ORIGINS = [
    "http://localhost:5173",  # Vite default
    "http://127.0.0.1:5173",
    "http://localhost:5174",  # Vite alternate port
    "http://127.0.0.1:5174",
]

# Production CORS origins (read from .env if needed)
# Add production domains to CORS_ALLOWED_ORIGINS if deploying
if not DEBUG:
    production_origins = config('CORS_ALLOWED_ORIGINS', default='').split(',')
    CORS_ALLOWED_ORIGINS.extend([origin.strip() for origin in production_origins if origin.strip()])

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

# For quick local dev you can also do:
# CORS_ALLOW_ALL_ORIGINS = True  # NOT for production

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.SessionAuthentication",  # Browsable API + CSRF
        "rest_framework_simplejwt.authentication.JWTAuthentication",  # SPA-friendly
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.AllowAny",  # keep open for now; tighten later
    ],
}

# Required when 'django.contrib.staticfiles' is enabled
STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

# --- Media uploads (optional, if you will upload files) ---
# MEDIA_URL = "/media/"
# MEDIA_ROOT = BASE_DIR / "media"

# Timezone & language (Norway-friendly defaults if you like)
LANGUAGE_CODE = "en-us"
TIME_ZONE = "Europe/Oslo"
USE_I18N = True
USE_TZ = True

# Security Settings (Production)
# Read from .env: comma-separated list of trusted origins
csrf_origins = config('CSRF_TRUSTED_ORIGINS', default='')
if csrf_origins:
    CSRF_TRUSTED_ORIGINS = [origin.strip() for origin in csrf_origins.split(',') if origin.strip()]

# SSL/HTTPS Settings
SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=False, cast=bool)
SESSION_COOKIE_SECURE = config('SESSION_COOKIE_SECURE', default=False, cast=bool)
CSRF_COOKIE_SECURE = config('CSRF_COOKIE_SECURE', default=False, cast=bool)