# Bashrc Aliases
* From an administrative bash terminal, execute the commands below to install the `bashrc` aliases

```bash
git clone https://github.com/Git-Leon/bashrc ~/bashrc
chmod u+x ~/bashrc/install.sh
~/bashrc/install.sh
```

## How this repo is organized

This repository contains a collection of small shell utilities, PowerShell helpers, and Python wrappers that I use on Windows (Git Bash / MINGW64).

- `aliases/` — main scripts and utilities. Subfolders:
  - `aliases/powershell/` — PowerShell helpers (e.g. `check-ram-usage.ps1`).
  - `aliases/python/` — Python helper wrappers used by scripts (e.g. `demucs-wrapper.py`).
- `target/` — temporary outputs, not checked in.

All scripts are written for Git Bash on Windows and follow `#!/usr/bin/env bash` plus `set -euo pipefail` where appropriate.

## stems.sh — separating audio into stems (Demucs)

Location: `aliases/stems.sh`.

What it does:

- Accepts a path to an audio file and runs Demucs to separate stems into a directory named `<filename>.stems` next to the source file.
- If the output directory already exists the script prompts to delete it before continuing.
- After Demucs finishes the script flattens the nested model/song folders, renames the output WAV files to the pattern `<filename>.<stem>.wav` (e.g. `MySong.bass.wav`), and prints the resulting files.

Key implementation details:

- The script uses an internal helper `ensure_pkg()` to auto-install Python packages (via `pip`) when missing. This keeps the script runnable on a clean environment but is conservative about risky packages.
- The script calls a Python wrapper: `aliases/python/demucs-wrapper.py`. This wrapper patches `torchaudio.save` to use the Python `soundfile` backend before invoking Demucs. See the Troubleshooting section for rationale.

Basic usage:

```bash
stems /path/to/song.mp3
```

If you don't want the prompt to delete an existing output folder, remove it manually first:

```bash
rm -rf "/c/.../MySong.stems"
```

## demucs-wrapper.py

Location: `aliases/python/demucs-wrapper.py`.

Why it exists:

- On Windows, `torchaudio` may try to use its TorchCodec/FFmpeg native backend when saving audio. That path requires a `torchcodec` Python package and matching FFmpeg "full-shared" DLLs. Many Windows setups don't have that and loading fails at runtime with libtorchcodec errors.
- The wrapper monkey-patches `torchaudio.save` to write WAV files using the pure-Python `soundfile` backend. This avoids requiring native FFmpeg DLLs and makes stems extraction robust on Windows.

Notes:

- Do NOT auto-install `torchcodec` in `stems.sh`. Installing `torchcodec` without the matching FFmpeg full-shared DLLs will cause runtime failures.
- Newer `torchaudio` versions may ignore the `TORCHAUDIO_USE_SOUNDFILE=1` env var; the wrapper is the reliable workaround.

## Troubleshooting

- If you see errors about `libtorchcodec` or `torchcodec` during demucs runs, prefer one of:
  - Use the wrapper (default) which avoids the native path.
  - Install FFmpeg full-shared DLLs and a `torchcodec` build compatible with your PyTorch/Torchaudio version (advanced).
- If stems are not found, verify Demucs produced WAV files under the model folder; the script attempts to locate them and will error if none are present.

## Windows / Git Bash specifics and gotchas

- `start` is a Git Bash builtin used to launch Windows apps; some scripts rely on that.
- `declare -A` (associative arrays) require Bash 4+. Git Bash ships with Bash 5.x so this is safe in this repo; do not run these scripts with `/bin/sh`.

## Contributing / LLM instructions

- The `.github/copilot-instructions.md` file contains context used by local LLM tools (Copilot) when generating repository edits. It documents conventions, known gotchas (torchcodec/FFmpeg), and where helper scripts live.

---

If you'd like, I can also:

- add a small `target/scripts/run-stems.sh` wrapper that runs `stems.sh` with safe defaults and logs to `target/logs/` (helpful for batch processing), or
- add a short developer checklist for testing `stems.sh` on a fresh Windows machine.
