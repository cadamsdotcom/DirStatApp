# DirStatApp

A macOS menu-bar app that displays real-time git repository status in floating borderless windows.

![macOS](https://img.shields.io/badge/macOS-15.7%2B-blue) ![Swift](https://img.shields.io/badge/Swift-6-orange)

## Features

- **Live git status** — current branch, latest commit, staged/unstaged changes with addition and deletion counts
- **Ahead/behind tracking** — shows commits ahead (green) and behind (red) relative to a configurable base branch
- **Visual git graph** — color-coded branch history rendered in a Canvas view
- **Multiple windows** — monitor several repositories simultaneously
- **Floating borderless windows** — drag to reposition, click to choose a directory, right-click for options
- **Adjustable transparency** — per-window opacity slider from 10% to 100%
- **Branch switching** — browse and select local and remote branches from the context menu
- **Persistent state** — window positions, sizes, opacity, and directories are saved and restored across launches
- **Auto-refresh** — polls git data every 2 seconds
- **No dock icon** — runs entirely in the menu bar

## Building

Requires Xcode with Swift 6 and macOS 15.7 SDK. No third-party dependencies.

```
open DirStatApp.xcodeproj
```

Build and run from Xcode (Cmd+R).

**Key build settings:**
- App Sandbox is disabled (required for running git via `Process`)
- Hardened Runtime is enabled
- `LSUIElement = YES` (menu-bar-only app)

## Usage

1. Launch the app — a status item appears in the menu bar
2. Click the menu bar icon to open a new window or manage existing ones
3. Click a window to choose a git repository directory
4. Drag a window to reposition it
5. Right-click a window for options: transparency, branches, new/close window

## Requirements

- macOS 15.7 or later
- Git installed on the system
