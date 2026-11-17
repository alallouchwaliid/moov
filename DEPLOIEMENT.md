# Mettre le backend MOOV en ligne (Render, gratuit)

Le dépôt contient tout ce qu'il faut : [render.yaml](render.yaml) crée l'API Django **et** la base PostgreSQL en une fois.

## 1. Mettre le code sur GitHub

1. Créez un compte sur https://github.com puis un dépôt **vide** nommé `moov` (privé ou public).
2. Dans le dossier `Moov` :

```bash
git init
git add .
git commit -m "MOOV : backend Django + app Flutter"
git branch -M main
git remote add origin https://github.com/<votre-compte>/moov.git
git push -u origin main
```

Le `.gitignore` exclut déjà les fichiers à ne pas publier (`.env`, base SQLite, `.venv`, APK, builds).

## 2. Déployer sur Render

1. Créez un compte sur https://render.com avec **« Sign in with GitHub »**.
2. **New → Blueprint**, choisissez le dépôt `moov` (autorisez Render à y accéder si demandé).
3. Render lit `render.yaml` et propose : `moov-api` (web) + `moov-db` (PostgreSQL). Renseignez :
   - `DJANGO_SUPERUSER_EMAIL` : votre email d'administrateur
   - `DJANGO_SUPERUSER_PASSWORD` : un mot de passe solide (pour `/admin/`)
4. **Apply**. Le premier déploiement prend 5 à 10 minutes.

L'API est ensuite disponible à l'adresse affichée par Render, par exemple :

- API : `https://moov-api.onrender.com/api/`
- Documentation : `https://moov-api.onrender.com/api/docs/`
- Back-office : `https://moov-api.onrender.com/admin/`

Chaque `git push` sur `main` redéploie automatiquement.

## 3. Brancher l'application mobile

**Sans recompiler** : écran de connexion → icône serveur en haut à droite → `https://moov-api.onrender.com/api`.

**APK qui pointe directement vers le serveur en ligne** (dans `mobile`) :

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64 --dart-define=API_URL=https://moov-api.onrender.com/api
```

## Limites de l'offre gratuite

- **Mise en veille** : après 15 min sans requête, le serveur s'endort ; la requête suivante attend ~50 s (l'app patiente jusqu'à 60 s). Pensez à ouvrir l'app une minute avant une démo.
- **Base de données** : la base PostgreSQL gratuite de Render a une durée de vie limitée (voir les conditions actuelles sur render.com) ; prévoir l'offre payante ou une autre base pour un usage durable.
- **Photos de profil** : stockées sur le disque du serveur, elles sont **effacées à chaque redéploiement**. Pour la production, utiliser un stockage externe (ex. Cloudinary, S3).
- **Données de démo** : `SEED_DEMO=true` recrée les comptes `amira@moov.ma`… au démarrage s'ils n'existent pas. Passez-le à `false` dans Render (*Environment*) pour une vraie mise en service.
