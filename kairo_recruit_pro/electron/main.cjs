const { app, BrowserWindow, protocol } = require('electron');
const path = require('path');
const fs = require('fs');
const serve = require('electron-serve').default || require('electron-serve');

const loadURL = serve({ directory: path.join(__dirname, '../dist') });

try {

const isDev = process.env.NODE_ENV === 'development';

protocol.registerSchemesAsPrivileged([
  { scheme: 'app', privileges: { secure: true, standard: true, supportFetchAPI: true, corsEnabled: true } }
]);

function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 1024,
    minHeight: 768,
    webPreferences: {
      preload: path.join(__dirname, 'preload.cjs'),
      nodeIntegration: false,
      contextIsolation: true,
      webSecurity: false,
    },
    title: 'Kaïro Pro',
    show: true,
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
  } else {
    loadURL(mainWindow);
  }
  
  // ALWAYS open devtools for debugging the white screen
  mainWindow.webContents.openDevTools();

  mainWindow.webContents.on('console-message', (event, level, message, line, sourceId) => {
    console.log(`[Electron Console] ${message} (${sourceId}:${line})`);
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

} catch (e) {
  fs.writeFileSync(path.join(app.getPath('userData'), 'crash.log'), e.stack || e.toString());
}
