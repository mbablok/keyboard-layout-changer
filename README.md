# keyboard-layout-changer

A tiny macOS menu bar app that makes a USB PC keyboard (a THOR 303 TKL by default) Mac-like
with one click. It runs the same `hidutil` command as the `swap-cmd-option-keys` fish function,
so after you reconnect the keyboard you click the menu bar icon instead of opening a terminal.

## What it does

- Keyboard icon in the menu bar, no Dock icon (`LSUIElement`).
- **Swap Command/Option Keys** runs:

  ```sh
  /usr/bin/hidutil property \
    --matching '{"VendorID":0x331a,"ProductID":0x5018}' \
    --set "<mapping>"
  ```

  `<mapping>` is the contents of `~/.hidutil-swap-cmd-opt.json`, read on every click — the same file
  the fish function `cat`s. If it is missing or unreadable the app reports
  `mapping file not found or unreadable: <path>` and does not run `hidutil`; there is no built-in
  copy it could silently apply instead. It does not use fish or your login shell.
- Confirmation: the icon turns into a checkmark on success or a warning triangle on failure, then
  goes back to the keyboard after about two seconds. No windows, notifications or sounds.
- On failure the menu shows the error text (and a **Copy Error** item) until the next successful run.
  If the keyboard is unplugged, hidutil matches nothing; the app reports "Keyboard not found".
- **Launch at Login** toggle (uses `SMAppService.mainApp`) and **Quit**.

## Requirements

macOS 13 or later and the Xcode command line tools (Swift 5.9+).

## Build, test, install

```sh
make test      # unit tests
make app       # Release build, assembled into build/KeyboardLayoutChanger.app (ad-hoc signed)
make install   # builds, copies to ~/Applications and launches it
make install INSTALL_DIR=/Applications   # install somewhere else
make uninstall
```

`make install` quits a running copy first, so it is also how you upgrade.

## Launch at login

The app registers itself as a login item on launch, so it starts at login without any setup. macOS
may still ask you to approve it in System Settings → General → Login Items; while approval is
pending the menu says so instead of pretending the item is on. Turning **Launch at Login** off
unregisters the app and is remembered, so later launches leave it off. The app is only ad-hoc
signed, so after reinstalling a new build macOS may stop recognizing the login item; the menu
reports that too, and turning the toggle on again points it at the new binary.

## Changing the matched keyboard

1. Find the keyboard's IDs: `hidutil list --matching keyboard` (the `VendorID` and `ProductID`
   columns; write them as hex, e.g. `0x331a`).
2. Edit `keyboardMatchingJSON` in `Sources/KeyboardLayoutChanger/HidutilCommand.swift`.
3. `make install`.

To change *what* gets remapped, edit `~/.hidutil-swap-cmd-opt.json`; the app reads it on every
click, so no rebuild is needed. That file is the only mapping the app knows about
(`Sources/KeyboardLayoutChanger/KeyMapping.swift`).

## Why a Swift Package

The project is a plain Swift Package with one executable target plus tests rather than an Xcode
project: everything is text files that diff cleanly, `swift build`/`swift test` work from the
command line without opening Xcode, and there are no generated `.xcodeproj` settings to maintain.
The `.app` bundle is small enough to assemble in the `Makefile` (binary + `Resources/Info.plist`
+ ad-hoc `codesign`). The app is not sandboxed, because it has to run `/usr/bin/hidutil`.

## Possible follow-ups

- Apply the mapping automatically when the keyboard is reconnected or the Mac wakes
  (e.g. via IOKit device-matching notifications or `NSWorkspace.didWakeNotification`).
- Developer ID signing and notarization for distribution.
