# Quick Minimal Notetaker

A tiny, distraction-free notetaking app for reading — a scrollable, chat-like
list of entries, each just a page number and free text (with lightweight
bullet formatting). Drag entries to reorder. Nothing else.

## Run (macOS)

```
npm install
npm start
```

The window opens at phone-screen proportions so it can sit alongside other
apps on your desktop. Notes are saved automatically on your machine (no
account, no sync, no network calls).

## Use

- **+** (top right) adds a new entry at the bottom.
- Each entry has a small page-number box and a text field below it.
- In the text field, start a line with `- ` to get bullet formatting —
  pressing Enter continues the bullet on the next line; pressing Enter on an
  empty bullet ends the list.
- Drag an entry by its body to reorder it in the list.
- The **×** on an entry removes it.

## Build a standalone app

This project doesn't include a packager. To build a distributable `.app`,
add a tool like [electron-builder](https://www.electron.build/) or
[electron-packager](https://github.com/electron/packager) as a dev
dependency and configure it as needed.
