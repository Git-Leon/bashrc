# Copilot Instructions — bashrc

## Project overview

This is a personal dotfiles / shell-utilities repo (`~/bashrc`) used on **Windows + Git Bash (MINGW64)**.
It contains bash aliases, PowerShell helpers, and Python utility scripts that are sourced or invoked from the shell.

## Directory structure

```
bashrc/
├── .bashrc                         # Main shell config, sourced on login
├── .github/
│   └── copilot-instructions.md     # This file — LLM context
├── register-aliases.sh             # Sources all alias scripts
├── aliases/
│   ├── *.sh                        # Bash alias/script files (e.g. kill-bloat.sh, stems.sh)
│   ├── kill-process.sh             # Helper: kill a single process by name
│   ├── batch/
│   │   └── *.bat                   # Windows batch utility scripts
│   ├── powershell/
│   │   └── *.ps1                   # PowerShell utility scripts (e.g. check-ram-usage.ps1)
│   └── python/
│       └── demucs-wrapper.py       # Python wrapper for Demucs stem separation
└── target/                         # Temp/output files (CSVs, logs) — not checked in
```

## Key conventions

- **Platform**: Windows 10/11, Git Bash (MINGW64). Use Windows paths (`C:\...`) in PowerShell, Unix paths (`/c/...`) in bash.
- **Shell**: Bash 4+ (via Git for Windows). Scripts use `#!/usr/bin/env bash` and `set -euo pipefail`.
- **PowerShell**: Called from bash via `powershell.exe -ExecutionPolicy Bypass -File ...`.
- **Python**: System Python at `C:\Python311\`. No virtualenvs — packages installed globally via `pip`.
- **Process killing**: Use `aliases/kill-process.sh` as the canonical helper; other scripts call it.
- **Stem separation**: `aliases/stems.sh` calls `aliases/python/demucs-wrapper.py` which patches torchaudio to use the soundfile backend (avoids TorchCodec/FFmpeg DLL issues on Windows).

## Style guidelines

- Keep scripts short and self-contained.
- Use `ensure_pkg()` in bash to auto-install missing Python packages before use.
- Prefer associative arrays (`declare -A`) for mappings in bash.
- PowerShell scripts live under `aliases/powershell/`; Python scripts under `aliases/python/`.
- Output directories default to `$env:TEMP` (PowerShell) or system temp (bash) unless the script is project-local.
- When generating edits, preserve existing comments and structure; append rather than rewrite.

## Known issues / gotchas

- **torchcodec**: Do NOT auto-install. It requires FFmpeg full-shared DLLs on Windows which are usually missing. The `demucs-wrapper.py` patches `torchaudio.save` to use soundfile instead.
- **torchaudio 2.5+**: `TORCHAUDIO_USE_SOUNDFILE=1` env var is ignored by newer versions; the Python wrapper monkey-patch is the reliable workaround.
- **Bash on Windows**: `start` is a shell builtin in Git Bash (launches Windows programs). `explorer.exe` must be restarted after killing.
- **`declare -A`**: Requires bash 4+. Git Bash ships bash 5.x so this is fine, but avoid running these scripts with `/bin/sh`.
