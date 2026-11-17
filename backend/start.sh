#!/usr/bin/env bash
# Démarrage en production (Render) : migrations, admin, données de démo optionnelles, puis Gunicorn.
set -o errexit

python manage.py migrate --noinput
python manage.py ensure_superuser
if [ "${SEED_DEMO:-false}" = "true" ]; then
  python manage.py seed_demo
fi

exec gunicorn config.wsgi:application --bind "0.0.0.0:${PORT:-8000}" --workers 2 --timeout 60
