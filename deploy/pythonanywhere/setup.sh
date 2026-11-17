#!/usr/bin/env bash
# Installation / mise à jour du backend MOOV sur PythonAnywhere (compte gratuit).
#
# À lancer dans une console Bash PythonAnywhere, APRÈS avoir créé la web app
# (onglet Web → Add a new web app → Manual configuration → Python 3.12) :
#
#   bash ~/moov/deploy/pythonanywhere/setup.sh
#
# Le script peut être relancé après chaque `git pull` pour mettre à jour.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BACKEND="$REPO/backend"
HOST="${USER}.pythonanywhere.com"
VENV="$HOME/.virtualenvs/moov"
WSGI_FILE="/var/www/${USER//./_}_pythonanywhere_com_wsgi.py"

echo "==> Projet : $REPO"
echo "==> Adresse : https://$HOST"

# 1. Environnement Python
if [ ! -x "$VENV/bin/python" ]; then
  PY=""
  for v in 3.12 3.13 3.11 3.10; do
    if command -v "python$v" >/dev/null 2>&1; then PY="python$v"; break; fi
  done
  [ -n "$PY" ] || { echo "Aucun Python >= 3.10 trouvé."; exit 1; }
  echo "==> Création de l'environnement virtuel avec $PY"
  "$PY" -m venv "$VENV"
fi
"$VENV/bin/pip" install --quiet --upgrade pip
"$VENV/bin/pip" install --quiet -r "$BACKEND/requirements.txt"

# 2. Configuration (.env), créée une seule fois
if [ ! -f "$BACKEND/.env" ]; then
  echo "==> Création de backend/.env"
  SECRET=$("$VENV/bin/python" -c "import secrets; print(secrets.token_urlsafe(50))")
  cat > "$BACKEND/.env" <<EOF
DJANGO_SECRET_KEY=$SECRET
DJANGO_DEBUG=false
DJANGO_ALLOWED_HOSTS=$HOST
CSRF_TRUSTED_ORIGINS=https://$HOST
SERVE_MEDIA=true
EOF
  chmod 600 "$BACKEND/.env"
fi

# 3. Base de données SQLite + fichiers statiques + données de démo
cd "$BACKEND"
"$VENV/bin/python" manage.py migrate --noinput
"$VENV/bin/python" manage.py collectstatic --noinput >/dev/null
if [ "${SEED_DEMO:-true}" = "true" ]; then
  "$VENV/bin/python" manage.py seed_demo
fi

# 4. Fichier WSGI de la web app
if [ -f "$WSGI_FILE" ]; then
  cat > "$WSGI_FILE" <<EOF
# Généré par deploy/pythonanywhere/setup.sh
import os
import sys

path = "$BACKEND"
if path not in sys.path:
    sys.path.insert(0, path)

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

from django.core.wsgi import get_wsgi_application  # noqa: E402

application = get_wsgi_application()
EOF
  echo "==> Fichier WSGI mis à jour : $WSGI_FILE"
else
  echo "!! Fichier WSGI introuvable ($WSGI_FILE)."
  echo "   Créez d'abord la web app (onglet Web → Add a new web app → Manual configuration),"
  echo "   puis relancez ce script."
fi

# 5. Compte administrateur (une seule fois)
if ! "$VENV/bin/python" manage.py shell -c "from accounts.models import User; import sys; sys.exit(0 if User.objects.filter(is_superuser=True).exists() else 1)"; then
  echo "==> Création du compte administrateur (/admin/)"
  "$VENV/bin/python" manage.py createsuperuser
fi

cat <<EOF

Terminé. Dans l'onglet Web de PythonAnywhere :
  1. Virtualenv : $VENV
  2. Bouton vert « Reload $HOST »
  3. Testez : https://$HOST/api/trips/
EOF
