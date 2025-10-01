# 🚀 Toxicify Sync Scripts

Snelle sync scripts om je addon bestanden naar WoW te kopiëren.

## ⚡ Instant Sync (Aanbevolen)

### `sync-now.bat` - Batch versie
- **Gebruik**: Dubbelklik op het bestand
- **Snelheid**: 0.5 seconden
- **Werkt**: Altijd, geen Git nodig

### `sync-now.ps1` - PowerShell versie  
- **Gebruik**: 
  ```powershell
  powershell -ExecutionPolicy Bypass -File "sync-now.ps1"
  ```
- **Snelheid**: 0.3 seconden
- **Werkt**: Sneller dan batch

## 📋 Workflow

1. **Maak wijzigingen** in je Lua bestanden
2. **Voer sync script uit** (dubbelklik of PowerShell)
3. **Test in WoW** - Addon is direct beschikbaar
4. **Commit wanneer je wilt** - Geen vertragingen meer

## 🎯 Voordelen

- ✅ **Geen Git vertragingen** meer
- ✅ **Geen GitKraken problemen** 
- ✅ **Instant sync** - 0.3 seconden
- ✅ **Geen hooks** die vastlopen
- ✅ **Volledige controle** - Jij bepaalt wanneer

## 📁 Wat Wordt Gesynct

- Alle `.lua` bestanden
- `Toxicify.toc`
- `Assets/logo.png`

**🎉 Nu kun je snel ontwikkelen zonder Git vertragingen!**
