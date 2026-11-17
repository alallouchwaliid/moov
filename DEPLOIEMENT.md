# Mettre le backend MOOV en ligne

## Option recommandée : PythonAnywhere (gratuit, sans carte bancaire)

Résultat : l'API à l'adresse `https://waliiiiiid.pythonanywhere.com/api/`, base SQLite, HTTPS inclus.

### 1. Créer le compte

Sur https://www.pythonanywhere.com : **Pricing & signup → Create a Beginner account**.
Le nom d'utilisateur choisi donne l'adresse du site (ex. `moovapp` → `moovapp.pythonanywhere.com`).

### 2. Créer la web app

Onglet **Web → Add a new web app → Next → Manual configuration** (pas « Django ») → **Python 3.12** → Next.

### 3. Récupérer le code et tout installer

Onglet **Consoles → Bash**, puis :

```bash
git clone https://github.com/alallouchwaliid/moov.git
```

```bash
bash ~/moov/deploy/pythonanywhere/setup.sh
```

Le script (3 à 5 minutes) installe les dépendances, crée `backend/.env` avec une clé secrète, la base de données, les données de démo, configure le fichier WSGI, puis demande l'email et le mot de passe du compte administrateur.

### 4. Activer

Onglet **Web** :

1. **Virtualenv** : `/home/<votre-nom>/.virtualenvs/moov`
2. **Security → Force HTTPS** : activé
3. Bouton vert **Reload**

Vérifiez : `https://waliiiiiid.pythonanywhere.com/api/trips/`, `/api/docs/` et `/admin/`.

### Mettre à jour après un `git push`

```bash
cd ~/moov && git pull && bash deploy/pythonanywhere/setup.sh
```

Puis **Reload** dans l'onglet Web.

### Limites du compte gratuit

- La web app doit être **prolongée une fois par mois** : onglet Web → bouton « Run until 1 month from today ».
- Base **SQLite** (pas de PostgreSQL ni MySQL sur les nouveaux comptes gratuits) : suffisant pour un projet étudiant.
- 512 Mo d'espace disque, puissance limitée : adapté à une démo, pas à des milliers d'utilisateurs.

---

## Brancher l'application mobile

**Sans recompiler** : écran de connexion → icône serveur en haut à droite → `https://waliiiiiid.pythonanywhere.com/api`.

**APK pointant directement vers le serveur** (dans `mobile`) :

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64 --dart-define=API_URL=https://waliiiiiid.pythonanywhere.com/api
```

---

## Alternative : Render (PostgreSQL)

Le fichier [render.yaml](render.yaml) permet un déploiement Render (**New → Blueprint**). Selon les conditions du moment, Render peut demander une carte bancaire, limite la durée de vie de la base gratuite et met le serveur en veille après 15 min d'inactivité.
