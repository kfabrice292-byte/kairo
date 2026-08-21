const { app, BrowserWindow } = require('electron');
const path = require('path');
const express = require('express');

let mainWindow;
let server;

async function createServer() {
  return new Promise((resolve) => {
    const expressApp = express();
    expressApp.use(express.static(path.join(__dirname, 'dist')));
    
    // SPA fallback
    expressApp.use((req, res) => {
      res.sendFile(path.join(__dirname, 'dist', 'index.html'));
    });

    // Listen on port 0 to get a random available port
    server = expressApp.listen(0, '127.0.0.1', () => {
      const port = server.address().port;
      console.log(`Server running on http://127.0.0.1:${port}`);
      resolve(port);
    });
  });
}

async function createWindow() {
  const port = await createServer();
  
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 800,
    title: "KAIRO Admin",
    icon: path.join(__dirname, 'public', 'favicon.ico'),
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true
    },
    backgroundColor: '#000000',
    autoHideMenuBar: true
  });

  mainWindow.loadURL(`http://127.0.0.1:${port}/login.html`);
  
  mainWindow.on('closed', function () {
    mainWindow = null;
  });
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', function () {
    if (mainWindow === null) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (server) {
    server.close();
  }
  if (process.platform !== 'darwin') app.quit();
});
