const { app, BrowserWindow } = require('electron');
const path = require('path');

// Phone-sized window (roughly iPhone screen proportions), floats over other apps.
const WINDOW_WIDTH = 380;
const WINDOW_HEIGHT = 780;

function createWindow() {
  const win = new BrowserWindow({
    width: WINDOW_WIDTH,
    height: WINDOW_HEIGHT,
    minWidth: 300,
    minHeight: 400,
    backgroundColor: '#f2d64b',
    titleBarStyle: 'hiddenInset',
    alwaysOnTop: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
    },
  });

  win.loadFile('index.html');
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') app.quit();
});
