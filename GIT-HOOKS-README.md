# 🔧 Toxicify Git Hooks

Deze repository bevat automatische Git hooks die de addon bestanden sync en een nieuwe installer bouwt wanneer er wijzigingen zijn in Lua bestanden.

## 📋 Beschikbare Hooks

### 1. **pre-commit** (Unix/Linux/macOS)
- **Bestand**: `.git/hooks/pre-commit`
- **Beschrijving**: Bash script voor Unix-achtige systemen
- **Gebruik**: Automatisch actief na installatie

### 2. **pre-commit.ps1** (Windows PowerShell)
- **Bestand**: `.git/hooks/pre-commit.ps1`
- **Beschrijving**: PowerShell script voor Windows
- **Gebruik**: Handmatig activeren (zie instructies hieronder)

### 3. **pre-commit.bat** (Windows Batch)
- **Bestand**: `.git/hooks/pre-commit.bat`
- **Beschrijving**: Batch script voor Windows
- **Gebruik**: Handmatig activeren (zie instructies hieronder)

## 🚀 Installatie en Gebruik

### Voor Unix/Linux/macOS:
```bash
# De hook is al geïnstalleerd en actief
# Geen extra stappen nodig
```

### Voor Windows:

#### Optie 1: CMD (Aanbevolen voor GitKraken)
```cmd
# Kopieer de CMD versie naar de juiste locatie (werkt met GitKraken)
copy ".git\hooks\pre-commit.cmd" ".git\hooks\pre-commit"
```

#### Optie 2: PowerShell
```powershell
# Kopieer de PowerShell versie naar de juiste locatie
Copy-Item ".git/hooks/pre-commit.ps1" ".git/hooks/pre-commit" -Force
```

#### Optie 3: Batch File
```cmd
# Kopieer de batch versie naar de juiste locatie
copy ".git\hooks\pre-commit.bat" ".git\hooks\pre-commit"
```

### Voor GitKraken Gebruikers:

#### Optie A: Pre-commit Hook (Aanbevolen)
De **CMD versie** (`.git/hooks/pre-commit.cmd`) is speciaal geoptimaliseerd voor GitKraken en lost het "pre-commit isn't executable" probleem op.

#### Optie B: Post-commit Hook (Alternatief)
Als de pre-commit hook nog steeds problemen geeft, kun je de **post-commit hook** gebruiken:
```cmd
# De post-commit hook draait NA een succesvolle commit
# Dit voorkomt het "isn't executable" probleem
```
**Voordeel**: Draait na de commit, dus geen blokkering
**Nadeel**: Bestanden worden pas gesynct na de commit

## 🎯 Wat Doet de Hook?

Wanneer je een commit maakt met wijzigingen in `.lua` bestanden, zal de hook automatisch:

1. **🔍 Detecteren** van Lua bestand wijzigingen
2. **📋 Syncen** van alle addon bestanden naar de `Installer/` directory
3. **🎮 Syncen** van alle addon bestanden naar de WoW AddOns directory
4. **🔨 Bouwen** van een nieuwe installer (als NSIS beschikbaar is)
5. **📝 Toevoegen** van de bijgewerkte bestanden aan de commit

## 📁 Bestanden die Worden Gesynct

### Naar Installer Directory:
- `Commands.lua`
- `Constants.lua`
- `Core.lua`
- `Events.lua`
- `GroupFinder.lua`
- `Minimap.lua`
- `Options.lua`
- `Player.lua`
- `Toxicify.lua`
- `UI.lua`
- `Toxicify.toc`
- `Assets/logo.png` (als beschikbaar)

### Naar WoW AddOns Directory:
- Alle bovenstaande bestanden worden ook gesynct naar: `D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify`
- De addon is direct beschikbaar in WoW na een commit!

## 🔧 Vereisten

### Voor Automatische Installer Bouw:
- **NSIS** moet geïnstalleerd zijn
- **Download**: https://nsis.sourceforge.io/
- **Of via package manager**:
  - Chocolatey: `choco install nsis`
  - Winget: `winget install NSIS.NSIS`
  - Scoop: `scoop install nsis`

### Voor PowerShell Hooks:
- Windows PowerShell 5.1+ of PowerShell Core 6+
- Git voor Windows

## 🧪 Testen van de Hook

1. **Maak een wijziging** in een `.lua` bestand
2. **Stage de wijziging**: `git add <bestand>`
3. **Maak een commit**: `git commit -m "Test wijziging"`
4. **Observeer** de automatische sync en installer build

## 🐛 Troubleshooting

### Hook Werkt Niet:
- Controleer of het bestand uitvoerbaar is (Unix): `chmod +x .git/hooks/pre-commit`
- Controleer of de juiste versie wordt gebruikt voor je OS
- Controleer Git configuratie: `git config --list`

### NSIS Niet Gevonden:
- Installeer NSIS via een van de bovenstaande methoden
- Controleer of `makensis` beschikbaar is in PATH
- Test handmatig: `makensis --version`

### PowerShell Execution Policy:
```powershell
# Als PowerShell scripts niet mogen draaien:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 📝 Logs en Output

De hook toont uitgebreide output tijdens het proces:
- 🔍 Detectie van wijzigingen
- 📋 Sync status van bestanden
- 🔨 Installer build status
- 📊 Installer grootte
- ✅ Success/error berichten

## 🔄 Uitschakelen

Om de hook tijdelijk uit te schakelen:
```bash
# Rename het bestand
mv .git/hooks/pre-commit .git/hooks/pre-commit.disabled

# Of verwijder het
rm .git/hooks/pre-commit
```

## 📞 Support

Voor problemen met de Git hooks:
1. Controleer de logs in de terminal output
2. Test handmatig de NSIS build: `cd Installer && makensis Toxicify-Installer.nsi`
3. Controleer of alle bestanden correct zijn gesynct

---

**🎉 Geniet van automatische addon sync en installer builds!**
