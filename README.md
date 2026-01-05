# Mono

Mono is a Code Editor for Android built with Flutter, designed to provide a VSCode-like development environment on mobile devices.

## Features

- **Integrated Terminal**: Full xterm.js implementation for shell access, git commands, and file system navigation.
- **Code Editor**: Syntax highlighting, line numbers, auto-indentation, and smart editing features.
    - **Autocomplete**: Intelligent code suggestions.
    - **Snippets**: Quick code templates.
    - **Emmet**: Expanded abbreviations for HTML/CSS.
- **Git Integration**: Clone, commit, push, pull, and repository management.
- **File System**: Full project folder management and file explorer.
- **Diagnostics**: Real-time error and warning detection.

## Architecture

Mono utilizes a modular, service-based architecture with **Provider** for state management.

### Directory Structure

The `lib/` directory is organized by responsibility:

- **`services/`**: Core business logic and external system interactions.
    - `TerminalService`: Manages terminal sessions and pty execution.
    - `GitService`: Handles version control operations.
    - `FileService`: Manages file I/O and storage access.
    - `EditorService`: Handles autocomplete, emmet, and snippets.
- **`models/`**: Data classes (e.g., `FileNode`, `TerminalSession`).
- **`widgets/`**: Reusable UI components divided into `editor`, `terminal`, and general widgets.
- **`screens/`**: High-level application views.
- **`core/`**: Application configuration, themes, and constants.

### Data Flow

1.  **File Access**: `FileService` recursively maps directories to `FileNode` trees.
2.  **Editing**: File content is loaded into memory buffers. Changes are persisted to storage via `FileService` upon save.
3.  **State**: `Provider` notifies listeners of changes (e.g., terminal output, file updates), ensuring the UI stays in sync with the underlying state without unnecessary rebuilds.

## Tech Stack

- **Framework**: Flutter
- **Language**: Dart
- **Terminal**: xterm.dart
- **State Management**: Provider
- **Font**: JetBrains Mono / Roboto Mono

## License
This project is licensed under the **Apache License 2.0**.