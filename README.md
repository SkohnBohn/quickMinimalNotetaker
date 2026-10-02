# Quick Minimal Notetaker

A tiny, distraction-free notetaking app for reading — a scrollable, chat-like
list of entries, each just a page number and free text (with lightweight
bullet formatting). Drag entries to reorder. Nothing else.

Native macOS app (Swift + SwiftUI/AppKit) — no Electron, no bundled
Chromium/Node runtime, no third-party framework to notarize. It's built
locally with your own Xcode/Swift toolchain.

## Requirements

- macOS 14 or later
- Xcode (or the standalone Swift toolchain / Command Line Tools) — provides
  `swift`

## Run (macOS)

```
swift run
```

This builds and launches the app directly. The window opens at phone-screen
proportions so it can sit alongside other apps on your desktop. Notes are
saved automatically to `~/Library/Application Support/QuickMinimalNotetaker/notes.json`
(no account, no sync, no network calls).

## Use

- **+** (top right) adds a new entry at the bottom.
- Each entry has a small page-number box and a text field below it.
- In the text field, start a line with `- ` to get bullet formatting —
  pressing Enter continues the bullet on the next line; pressing Enter on an
  empty bullet ends the list. Pressing Enter on a non-bullet line finishes
  (unselects) that entry rather than adding a new one — press Enter again
  with nothing selected to add a new entry.
- Tab cycles through page number → delete → text → next entry. Cmd+V and
  Cmd+Shift+V (paste and match style) work in the text field as usual.
- The small square checkbox sorts entries by ascending page number for
  display only; unchecking restores your drag-arranged order exactly.
- **⇅** opens Save Notes… / Load Notes… to export or import your notes as a
  JSON file.
- Drag an entry by its body to reorder it in the list.
- The **×** on an entry removes it.

## Build a standalone app

```
swift build -c release
```

The compiled binary is at `.build/release/QuickMinimalNotetaker`. To get a
proper double-clickable `.app` bundle (with an icon, Info.plist, etc.), open
the folder in Xcode (`File > Open...`) or wrap the binary in a minimal
`.app` bundle structure yourself — Swift Package Manager alone only produces
the raw executable.
