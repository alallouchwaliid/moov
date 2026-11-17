#!/bin/sh
set -e

# Attend que PostgreSQL accepte les connexions
if [ -n "$POSTGRES_HOST" ]; then
  echo "Attente de PostgreSQL ($POSTGRES_HOST:${POSTGRES_PORT:-5432})..."
  python - <<'EOF'
import os, time, psycopg
for _ in range(60):
    try:
        psycopg.connect(
            dbname=os.environ["POSTGRES_DB"], user=os.environ["POSTGRES_USER"],
            password=os.environ["POSTGRES_PASSWORD"], host=os.environ["POSTGRES_HOST"],
            port=os.environ.get("POSTGRES_PORT", "5432"),
        ).close()
        break
    except psycopg.OperationalError:
        time.sleep(1)
else:
    raise SystemExit("PostgreSQL injoignable")
EOF
fi

python manage.py migrate --noinput
python manage.py collectstatic --noinput >/dev/null

exec "$@"
