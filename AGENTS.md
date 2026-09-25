# Project agent memory

This file is the project's committed home for project-intrinsic agent knowledge: build, test, release, architecture, and sharp-edge notes that should travel with the code.

- Build, test and install go through the `Makefile` (`make test`, `make app`, `make install`); see `README.md`.
- Run tests with `make test`, not bare `swift test`: when the calling process runs under Rosetta, `swift test` loads xctest's x86_64 slice and silently runs 0 XCTest cases; the Makefile forces the hardware's native arch.
- Logic under test is UI-free and injected (`KeyboardLayoutController` takes run/sleep/loadMapping closures); keep SwiftUI/`Process`/`SMAppService` glue thin and untested.
- `hidutil property --set` exits 0 and prints nothing when no device matches; the controller treats empty output as "keyboard not found".

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
