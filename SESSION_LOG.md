# Herder - Session Log

*Última sesión: 2026-02-16*

## Estado Actual

**Versión actual:** v0.6.5
**Repo:** https://github.com/Qouter/herder (público)
**Homebrew tap:** https://github.com/Qouter/homebrew-tap

### Qué funciona ✅
- Menu bar app con contadores dinámicos (`🤖 3 | ⏳ 1`)
- Breathing pulse animation en agentes working
- Detección de agentes via hooks (SessionStart, SessionEnd, Stop, UserPromptSubmit)
- **Transcript polling** (cada 5s) para detectar plan review, permission prompts, preguntas intermedias
- Idle detection dual: hooks + transcript stale (10s threshold)
- Popover con lista de agentes: estado, último mensaje, tiempo, **git branch**
- Hooks reescritos en **Python 3 puro** (sin jq, sin socat — zero dependencies)
- Socket server (GCD-based, non-blocking)
- Self-update: `herder update`
- Installer one-liner: `curl -fsSL ... | bash`
- Detección de terminal (Warp, iTerm2, VS Code, Cursor, Terminal.app)
- Session timeouts inteligentes: 30min idle, 4h working
- README actualizado con screenshot real, listo para publicar
- LICENSE MIT añadida

### Qué falta / En progreso 🔧
- **Botón Open no abre el TAB específico en Warp** — Warp no expone tabs via Accessibility API (GPU rendering en Rust)
  - iTerm2 y Terminal.app sí funcionan con AppleScript
  - Para Warp solo activamos la ventana
- Tab cycling approach (leer window title al cambiar tabs) pendiente de test por Alejandro

## Arquitectura

```
Claude Code hooks (python3) → /tmp/herder.sock (Unix socket) → Herder.app (Swift+SwiftUI)
TranscriptMonitor (polling 5s) → idle detection → menu bar update
.git/HEAD reading → branch display
```

- **Hooks:** `~/.herder/hooks/` (4 scripts python3, async)
- **App:** `~/.herder/Herder.app` (SwiftUI, GCD socket server, TranscriptMonitor)
- **CLI:** `/usr/local/bin/herder` (bash wrapper)
- **Estado:** `~/.herder/VERSION`

## Changelog Reciente

- **v0.6.5** — Breathing pulse animation en working agents
- **v0.6.4** — Stale transcript threshold reducido a 10s
- **v0.6.3** — Mejor idle detection: más patrones + stale transcript fallback
- **v0.6.2** — Branch debajo del path (no al lado)
- **v0.6.1** — Git branch badge en agent list
- **v0.6.0** — TranscriptMonitor para detectar plan review prompts
- **v0.5.4** — Hooks reescritos en Python 3 puro (sin jq/socat)
- **v0.5.3** — Session timeouts: 30min idle, 4h working

## Próximos Pasos
- [ ] Test tab cycling en Warp (window title cambia al cambiar tab?)
- [ ] Detectar sesiones existentes al iniciar la app
- [ ] Notificación/sonido cuando un agente pasa a idle
- [ ] Launch at Login
- [ ] Mostrar nombre del proyecto (package.json, etc.)
- [ ] Publicar en comunidades (Reddit, HN, Twitter, etc.)

## Decisiones Pendientes
1. Warp tab navigation — ¿vale la pena el tab cycling approach?
2. ¿Monetización futura? MIT permite dual licensing / versión Pro

*Actualizado por Mota — 2026-02-16 21:05*
