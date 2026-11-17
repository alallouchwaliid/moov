# Prépare le projet Flutter MOOV après l'installation de Flutter.
# Usage (dans le dossier mobile) :  powershell -ExecutionPolicy Bypass -File setup.ps1
$ErrorActionPreference = "Stop"
$utf8 = New-Object System.Text.UTF8Encoding($false)  # UTF-8 sans BOM pour les fichiers natifs
Set-Location $PSScriptRoot

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "Flutter n'est pas installé ou pas dans le PATH. Voir README.md." -ForegroundColor Red
    exit 1
}

# 1. Génère les dossiers natifs android/ et ios/ (les fichiers existants comme lib/ ne sont pas écrasés)
flutter create --org ma.moov --project-name moov --platforms android,ios .

# 2. Android : autorise HTTP vers le serveur Django local et renomme l'app en « MOOV »
$manifest = "android\app\src\main\AndroidManifest.xml"
$xml = Get-Content $manifest -Raw
if ($xml -notmatch "usesCleartextTraffic") {
    $xml = $xml -replace '<application', '<application android:usesCleartextTraffic="true"'
}
$xml = $xml -replace 'android:label="moov"', 'android:label="MOOV"'
[IO.File]::WriteAllText((Resolve-Path $manifest), $xml, $utf8)

# 3. iOS : accès à la galerie photo (avatar) + HTTP local en développement
$plist = "ios\Runner\Info.plist"
if (Test-Path $plist) {
    $p = Get-Content $plist -Raw
    if ($p -notmatch "NSPhotoLibraryUsageDescription") {
        $extra = @"
	<key>NSPhotoLibraryUsageDescription</key>
	<string>MOOV utilise vos photos pour votre photo de profil.</string>
	<key>NSAppTransportSecurity</key>
	<dict>
		<key>NSAllowsArbitraryLoads</key>
		<true/>
	</dict>
"@
        $p = $p -replace '(?s)</dict>\s*</plist>', "$extra</dict>`n</plist>"
        $p = $p -replace '<string>Moov</string>', '<string>MOOV</string>'
        [IO.File]::WriteAllText((Resolve-Path $plist), $p, $utf8)
    }
}

# 4. Dépendances + vérification du code
flutter pub get
flutter analyze
Write-Host "`nProjet prêt. Lancez le backend puis :  flutter run" -ForegroundColor Green
