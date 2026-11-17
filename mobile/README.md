# MOOV — Application mobile (Flutter)

Application Android / iOS de covoiturage universitaire, branchée sur l'API Django du dossier `backend/`.

## Écrans

| Onglet / écran | Fonction |
|---|---|
| Démarrage | Logo et slogan, connexion automatique si une session existe |
| Connexion / Inscription | Email + mot de passe (JWT), téléphone `+212`, statut étudiant / personnel, mode « Explorer sans compte » |
| **Recherche** | Départ, arrivée, date, passagers, trajets enregistrés, notifications |
| Résultats | Tri (plus tôt / moins cher), filtres (heure, prix max, identité vérifiée), enregistrement du trajet |
| Détail du trajet | Itinéraire, conducteur, véhicule, options, avis, réservation (places + message) |
| **Publier** | Villes, lieux, date/heure, prix, places, véhicule, bagages, préférences, réservation instantanée |
| **Trajets** | Réservations passager + trajets conducteur (à venir / historique), demandes en attente |
| Gérer un trajet | Accepter / refuser les demandes, coordonnées des passagers, annuler, marquer effectué, évaluer |
| Réservation | Statut, contact du conducteur après acceptation, annulation, laisser un avis |
| **Profil** | Photo, vérification, statistiques, avis reçus, véhicules, modification, mot de passe, déconnexion |
| Notifications | Demandes, acceptations, refus, annulations, invitations à laisser un avis |

## 1. Installer les outils (une seule fois)

1. **Flutter** : https://docs.flutter.dev/get-started/install/windows/mobile — dézippez par exemple dans `C:\src\flutter` et ajoutez `C:\src\flutter\bin` au PATH.
2. **Android Studio** : https://developer.android.com/studio — installez-le, puis dans *Device Manager* créez un émulateur (ex. Pixel 7).
3. Vérifiez :

```bash
flutter doctor
```

Acceptez les licences Android si demandé :

```bash
flutter doctor --android-licenses
```

## 2. Préparer le projet (une seule fois)

Dans le dossier `mobile` :

```bash
powershell -ExecutionPolicy Bypass -File setup.ps1
```

Ce script génère les dossiers natifs `android/` et `ios/`, autorise la connexion HTTP au serveur local, installe les dépendances et vérifie le code.

## 3. Lancer

1. Démarrez le backend (dans `backend`) en écoutant sur toutes les interfaces :

```bash
.venv\Scripts\python manage.py runserver 0.0.0.0:8000
```

2. Lancez l'émulateur Android, puis dans `mobile` :

```bash
flutter run
```

L'app contacte `http://10.0.2.2:8000/api` (l'adresse du PC vue depuis l'émulateur Android).

## Installer sur un vrai téléphone Android

1. Construire l'APK (≈ 18 Mo, téléphones 64 bits) :

```bash
flutter build apk --release --split-per-abi --target-platform android-arm64 --dart-define=API_URL=http://127.0.0.1:8000/api
```

   Le fichier est dans `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`.

2. Brancher le téléphone en USB (débogage USB activé ; sur Xiaomi, activer aussi « Installer via USB »), puis :

```bash
adb install -r build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

3. Relier le téléphone au backend du PC **par le câble** (indispensable sur le Wi-Fi UM6P, qui isole les appareils entre eux) :

```bash
adb reverse tcp:8000 tcp:8000
```

**Sans câble** : connecter le PC au partage de connexion du téléphone, puis dans l'app, écran de connexion → icône serveur en haut à droite → `http://<IP du PC>:8000/api` (IP donnée par `ipconfig`).

Problèmes déjà rencontrés : « Application non installée » = stockage du téléphone plein ; `INSTALL_FAILED_USER_RESTRICTED` = option Xiaomi « Installer via USB » désactivée.

Comptes de démo (après `python manage.py seed_demo`) : `amira@moov.ma`, `youssef@moov.ma`… mot de passe `Moov!2026demo`.

## Structure

```
lib/
├── main.dart              # Point d'entrée, thème, langue française
├── config.dart            # URL de l'API
├── theme.dart             # Couleurs et styles de la maquette
├── api/                   # Client HTTP (JWT + rafraîchissement) et appels typés
├── models/                # User, Trip, Booking, Review, Notification…
├── state/                 # AuthProvider (session)
├── utils/                 # Formats de date, prix, pluriels
├── widgets/               # Boutons, cartes, avatars, carte trajet…
└── screens/               # Tous les écrans
```
