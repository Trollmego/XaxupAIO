# AGENTS.md

## Cursor Cloud specific instructions

### Codebase overview

This repository contains two unrelated projects:

1. **AI Snake Game** (`snake-ai-game.html`) — A self-contained single-file HTML5/JS game with A* pathfinding AI. Zero external dependencies; runs in any modern browser.
2. **SimplePlugin** (`SimplePlugin/`) — A C++ DLL plugin for the BGX/League of Legends scripting platform. Windows-only (Visual Studio 2019, MSVC v142/ClangCL). **Cannot be built or tested on Linux.**

### Running the AI Snake Game

Serve the game with Python's built-in HTTP server:

```bash
python3 -m http.server 8000
```

Then open `http://localhost:8000/snake-ai-game.html` in Chrome. Click "Start Game" to begin the AI autopilot. See `QUICK-START.md` for details.

### Limitations on Linux

- The C++ SimplePlugin requires Windows + Visual Studio 2019 + the BGX Plugin SDK (git submodule). It cannot be compiled or tested in this environment.
- The `plugin_sdk` git submodule must be initialized (`git submodule update --init`) before the C++ project can build (on Windows).

### Lint / Test / Build

- There are **no linters, automated tests, or build systems** configured for the Snake game (it's a single HTML file).
- The C++ project uses a Visual Studio `.sln`/`.vcxproj` — MSBuild on Windows only.
- No CI/CD pipeline is configured.
