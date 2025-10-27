"""
Gunicorn Configuration File for ShadCoding Task1

This file configures the Gunicorn WSGI HTTP server for the Django backend.

Documentation: https://docs.gunicorn.org/en/stable/settings.html
"""

import multiprocessing
import os

# Bind to localhost only (Nginx will handle external connections)
bind = "127.0.0.1:8000"

# Worker processes
# Recommended: (2 x CPU cores) + 1
workers = multiprocessing.cpu_count() * 2 + 1

# Worker class
worker_class = "sync"

# Max requests per worker before restart (prevents memory leaks)
max_requests = 1000
max_requests_jitter = 50

# Timeout (seconds) - increase if you have slow requests
timeout = 30

# Keep alive connections
keepalive = 2

# Logging
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"

# Access log format
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "gunicorn-shadcoding"

# Daemon mode (set to False when using systemd)
daemon = False

# Preload application for better performance
preload_app = True

# Graceful timeout for workers
graceful_timeout = 30

# Number of pending connections
backlog = 2048

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190

# Server hooks
def on_starting(server):
    """
    Called just before the master process is initialized.
    """
    server.log.info("Gunicorn is starting...")


def on_reload(server):
    """
    Called to recycle workers during a reload via SIGHUP.
    """
    server.log.info("Gunicorn is reloading...")


def when_ready(server):
    """
    Called just after the server is started.
    """
    server.log.info("Gunicorn is ready. Listening on: %s", bind)


def on_exit(server):
    """
    Called just before exiting Gunicorn.
    """
    server.log.info("Gunicorn is shutting down...")


def worker_int(worker):
    """
    Called when a worker receives the SIGINT or SIGQUIT signal.
    """
    worker.log.info("Worker received INT or QUIT signal")


def worker_abort(worker):
    """
    Called when a worker receives the SIGABRT signal.
    """
    worker.log.info("Worker received SIGABRT signal")
