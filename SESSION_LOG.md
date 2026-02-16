# Herder - Session Log

*Última sesión: 2026-02-15*

## Estado Actual

**Versión actual:** v0.5.2 (compilando en GitHub Actions)
**Repo:** https://github.com/Qouter/herder (público)
**Homebrew tap:** https://github.com/Qouter/homebrew-tap

### Qué funciona ✅
- Menu bar app con contadores dinámicos (`🤖 3 | ⏳ 1`)
- Detección de agentes nuevos via hooks (SessionStart, SessionEnd, Stop, UserPromptSubmit)
- Popover con lista de agentes, estado (working/idle), último mensaje, tiempo corriendo
- Socket server (GCD-based, non-blocking)
- Self-update: `herder update` descarga última release de GitHub
- Installer: `curl -fsSL https://raw.githubusercontent.com/Qouter/herder/main/install.sh | bash`
- Detección de terminal (Warp, iTerm2, VS Code, Cursor, Terminal.app)
- Botón Open activa Warp correctamente
- Hooks registrados en `~/.claude/settings.json`

### Qué falta / En progreso 🔧
- **Botón Open no abre el TAB específico en Warp** — esto es donde lo dejamos
  - Warp no tiene AppleScript API para seleccionar tabs
  - Intentamos System Events pero solo abre Warp, no navega al tab correcto
  - **Próximo paso:** ejecutar `osascript -e 'tell application "System Events" to tell process "Warp" to get name of every window'` para ver cómo nombra Warp sus ventanas y poder matchear por título
  - Alternativa: usar el menú Window de Warp via System Events para buscar por nombre de directorio
- Versión en UI ahora lee de `~/.herder/VERSION` (fix en v0.5.2)

## Arquitectura

```
Claude Code hooks (bash+jq) → /tmp/herder.sock (Unix socket) → Herder.app (Swift+SwiftUI)
```

- **Hooks:** `~/.herder/hooks/` o `~/.claude/hooks/herder/` (4 scripts async)
- **App:** `~/.herder/Herder.app` (SwiftUI, GCD socket server)
- **CLI:** `/usr/local/bin/herder` (bash wrapper)
- **Estado:** `~/.herder/VERSION`

## Distribución

### Método principal: curl installer
```bash
curl -fsSL https://raw.githubusercontent.com/Qouter/herder/main/install.sh | bash
herder update  # para actualizar
```

### Homebrew (secundario, más problemático)
```bash
brew tap qouter/tap && brew install herder
```

### GitHub Actions
- Tag `v*` → compila universal binary (arm64+x86_64) → GitHub Release → auto-actualiza tap

## Próximos Pasos
- [ ] Resolver navegación a tab específico en Warp
- [ ] Probar con iTerm2 y Terminal.app
- [ ] Launch at Login
- [ ] Sonido/notificación cuando un agente pasa a idle
- [ ] Mostrar nombre del proyecto (package.json, etc.)
- [ ] Detectar sesiones existentes al iniciar la app

## Decisiones Pendientes
1. Cómo navegar al tab exacto en Warp (System Events vs otro approach)
2. ¿Pedir Accessibility permission al iniciar la app automáticamente?

*Actualizado por Mota — 2026-02-15 18:20*
