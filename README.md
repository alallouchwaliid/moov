# MOOV — Backend (Django REST Framework)

API REST de l'application mobile de covoiturage universitaire **MOOV**
(Flutter + Django REST + PostgreSQL, conteneurisée avec Docker Compose).

## Démarrage rapide avec Docker (recommandé)

```bash
cp .env.example .env
docker compose up --build
```

- API : http://localhost:8000/api/
- Documentation Swagger : http://localhost:8000/api/docs/
- Back-office : http://localhost:8000/admin/

Créer un administrateur et charger les données de démo :

```bash
docker compose exec api python manage.py createsuperuser
docker compose exec api python manage.py seed_demo
```

> Depuis l'émulateur Android, l'API est accessible sur `http://10.0.2.2:8000/api/`.

## Démarrage sans Docker (SQLite)

Si `POSTGRES_DB` n'est pas défini, le projet utilise SQLite automatiquement.

```bash
cd backend
python -m venv .venv
.venv\Scripts\activate          # Windows  (Linux/Mac : source .venv/bin/activate)
pip install -r requirements.txt
python manage.py migrate
python manage.py seed_demo
python manage.py runserver
```

Comptes de démo : `amira@moov.ma`, `youssef@moov.ma`, `salma@moov.ma`, `omar@moov.ma`,
mot de passe `Moov!2026demo`.

## Tests

```bash
cd backend
python manage.py test tests
```

Les tests couvrent le parcours complet du cahier des charges :
inscription → publication → recherche → réservation → acceptation → fin de trajet → avis,
ainsi que les règles métier (surréservation, double réservation, droits conducteur/passager…).

La collection Postman se trouve dans [docs/MOOV_API.postman_collection.json](docs/MOOV_API.postman_collection.json)
(les tokens JWT et les identifiants sont enregistrés automatiquement entre les requêtes).

## Structure

```
Moov/
├── docker-compose.yml        # Django + PostgreSQL
├── .env.example
├── docs/                     # Collection Postman
└── backend/
    ├── config/               # settings, urls, wsgi
    ├── accounts/             # Utilisateur (login par email), profil, véhicules
    ├── trips/                # Trajets, recherche, trajets enregistrés
    ├── bookings/             # Réservations (demande, acceptation, refus, annulation)
    ├── reviews/              # Avis 1-5 étoiles, signalement
    ├── notifications/        # Notifications in-app (lues par l'app Flutter)
    └── tests/                # Tests API
```

## Endpoints

Authentification JWT : en-tête `Authorization: Bearer <access>`.

| Méthode | Endpoint | Description |
|---|---|---|
| POST | `/api/auth/register/` | Inscription (renvoie user + tokens) |
| POST | `/api/auth/login/` | Connexion email / mot de passe |
| POST | `/api/auth/refresh/` | Nouveau token d'accès |
| POST | `/api/auth/logout/` | Invalide le refresh token |
| POST | `/api/auth/change-password/` | Changement de mot de passe |
| GET / PATCH / DELETE | `/api/me/` | Mon profil (avatar en multipart) ; DELETE désactive le compte |
| CRUD | `/api/me/vehicles/` | Mes véhicules |
| GET | `/api/users/{id}/` | Profil public + note moyenne |
| GET | `/api/trips/` | Recherche publique (`departure_city`, `arrival_city`, `date`, `departure_after`, `max_price`, `seats`, `verified_only`, `ordering`) |
| POST | `/api/trips/` | Publier un trajet |
| GET / PATCH | `/api/trips/{id}/` | Détail / modification |
| GET | `/api/trips/mine/` | Mes trajets publiés (`?status=`) |
| GET | `/api/trips/{id}/bookings/` | Demandes reçues pour un trajet |
| POST | `/api/trips/{id}/cancel/` | Annuler (prévient les passagers) |
| POST | `/api/trips/{id}/complete/` | Marquer effectué (ouvre les avis) |
| CRUD | `/api/saved-routes/` | Trajets enregistrés (accueil) |
| POST | `/api/bookings/` | Demande de réservation |
| GET | `/api/bookings/` | Mes réservations (passager) |
| GET | `/api/bookings/received/` | Demandes reçues (conducteur) |
| POST | `/api/bookings/{id}/accept/` · `refuse/` · `cancel/` | Transitions de statut |
| GET / POST | `/api/reviews/` | Avis (`?user=`, `?trip=`) / déposer un avis |
| POST | `/api/reviews/{id}/report/` | Signaler un avis |
| GET | `/api/notifications/` | Notifications (`?is_read=false`) |
| POST | `/api/notifications/{id}/read/` · `read-all/` | Marquer comme lu |

## Règles métier

- Les places disponibles sont calculées à partir des réservations **acceptées** ; l'acceptation
  verrouille le trajet en base pour éviter la surréservation.
- Un passager ne peut avoir qu'une réservation active par trajet et ne peut pas réserver son propre trajet.
- Pas de messagerie en V1 : une fois la réservation acceptée, le champ `contact` expose le
  téléphone / email de l'autre partie.
- Un avis n'est possible qu'après un trajet **terminé**, entre conducteur et passager acceptés,
  une seule fois par personne et par trajet.
- Annuler un trajet annule les réservations en cours et notifie les passagers.

## Back-office (Django Admin)

- Utilisateurs : validation d'identité, blocage / déblocage (actions groupées).
- Trajets : consultation, filtres, annulation par modération, réservations en ligne.
- Avis : filtre « signalé », masquage / rétablissement.
