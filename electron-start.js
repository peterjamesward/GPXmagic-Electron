const path = require('path')
var electron = require('electron')

var app = electron.app; // Module to control application life.
var BrowserWindow = electron.BrowserWindow; // Module to create native browser window.
// Need this for talking to the main process, which handles the OAuth (partly).
const ipcMain = electron.ipcMain;

// Keep a global reference of the window object, if you don't, the window will
// be closed automatically when the JavaScript object is GCed.
var mainWindow = null;

// Quit when all windows are closed.
app.on('window-all-closed',
    function() {
        // On OS X it is common for applications and their menu bar
        // to stay active until the user quits explicitly with Cmd + Q
        //if (process.platform != 'darwin')
        {
            app.quit();
        }
    }
);

app.setAboutPanelOptions({
    applicationName: "GPXmagic",
    applicationVersion: "4.0.0",
    copyright: "CC0 1.0 Universal",
    version: "9bb2df0a",
    authors: "Peter Ward"
});

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
app.on('ready',
function() {
    // Create the browser window.
    mainWindow = new BrowserWindow({
        width: 1000,
        height: 800,
        webPreferences: {
//            preload: path.join(__dirname, 'preload.js')
            preload: (__dirname + '/preload.js')
        }
    });

    // and load the index.html of the app.
    mainWindow.loadURL('file://' + __dirname + '/site/index.html');

    // Open the devtools.
    //mainWindow.openDevTools();
    // Emitted when the window is closed.
    mainWindow.on('closed',
        function() {
            // Dereference the window object, usually you would store windows
            // in an array if your app supports multi windows, this is the time
            // when you should delete the corresponding element.
            mainWindow = null;
        }
    );

    // Entry point for a renderer to trigger OAuth login with Strava.
    // This typifies our likely API, being a pair of messages exchanged.
    // Arguably should try to get invoke to work but our model is asynch anyway.
    ipcMain.on('requestAuth', (event, config) = >{

        const stravaOAuth = OAuth(config, windowParams);
        const options = config.scope;

        stravaOAuth.getAuthorizationCode(options).then(code = >{
            //console.log("Got token" + token)
            event.sender.send('code', code);
        },
        err = >{
            //console.log('Error while getting token', err);
            event.sender.send('code', null);
        });
    });

});

// Shim for OAuth module, driven by Elm code via the renderer process.
const windowParams = {
    alwaysOnTop: true,
    autoHideMenuBar: false,
    webPreferences: {
        nodeIntegration: false
    }
};
