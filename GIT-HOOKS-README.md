# Toxicify Git Hooks

Deze Git hooks zorgen voor automatische sync en installer build bij elke commit en push.

## 🎯 Wat De Hooks Doen

### Pre-commit Hook
- **Wanneer:** Draait VOOR elke commit
- **Wat:** 
  - Kopieert alle `.lua` bestanden naar WoW AddOns folder
  - Kopieert alle `.toc` bestanden naar WoW AddOns folder
  - Kopieert `logo.png` naar WoW AddOns folder
  - Kopieert alle bestanden naar Installer folder
  - Bouwt nieuwe installer automatisch

### Post-commit Hook
- **Wanneer:** Draait NA elke commit
- **Wat:** Zelfde als pre-commit hook

### Pre-push Hook
- **Wanneer:** Draait VOOR elke push
- **Wat:** Zelfde als pre-commit hook

## 📁 Bestemmingen

**WoW AddOns Folder:**
```
D:\World of Warcraft\_retail_\Interface\AddOns\Toxicify\
```

**Installer Folder:**
```
D:\Development\Toxicify\Installer\
```

## 🔧 Technische Details

### Hook Bestanden
- `.git/hooks/pre-commit` - Pre-commit hook
- `.git/hooks/post-commit` - Post-commit hook  
- `.git/hooks/pre-push` - Pre-push hook

### PowerShell Commands
De hooks gebruiken PowerShell voor bestandskopie:
```powershell
Copy-Item *.lua 'DESTINATION' -Force
Copy-Item *.toc 'DESTINATION' -Force
Copy-Item Assets/logo.png 'DESTINATION' -Force
```

### Installer Build
Na elke sync wordt automatisch een nieuwe installer gebouwd:
```powershell
cd Installer; .\Build-Installer-NoDownload.bat
```

## ✅ Werkt Met

- **GitKraken** - Volledig ondersteund
- **Command Line Git** - Volledig ondersteund
- **Visual Studio Code** - Volledig ondersteund
- **Andere Git GUI's** - Volledig ondersteund

## 🚀 Gebruik

**Geen handmatige actie nodig!**

1. **Maak wijzigingen** in Lua bestanden
2. **Commit in GitKraken** → Hooks draaien automatisch
3. **Push in GitKraken** → Hooks draaien automatisch
4. **Bestanden zijn gesynct** naar WoW AddOns folder
5. **Nieuwe installer** is gebouwd

## 🔍 Troubleshooting

### Hooks Draaien Niet
- Controleer of Git hooks zijn ingeschakeld
- Controleer of PowerShell beschikbaar is
- Controleer of WoW AddOns folder bestaat

### Bestanden Worden Niet Gekopieerd
- Controleer of bestanden bestaan in project root
- Controleer of doel folders bestaan
- Controleer PowerShell execution policy

### Installer Wordt Niet Gebouwd
- Controleer of NSIS geïnstalleerd is
- Controleer of `Build-Installer-NoDownload.bat` bestaat
- Controleer of Installer folder bestaat

## 📝 Logs

De hooks draaien stil (geen output), maar je kunt zien dat ze werken door:
- **Windows Command Prompt** verschijnt tijdens commit/push
- **Bestanden worden bijgewerkt** in WoW AddOns folder
- **Nieuwe installer** wordt gebouwd in Installer folder

## 🎉 Resultaat

Na elke commit/push:
- ✅ **Alle Lua bestanden** gesynct naar WoW
- ✅ **Alle TOC bestanden** gesynct naar WoW
- ✅ **Logo bestand** gesynct naar WoW
- ✅ **Nieuwe installer** gebouwd
- ✅ **Geen handmatige actie** nodig
