const path = require('path')
var electron = require('electron')

var app = electron.app; // Module to control application life.
var BrowserWindow = electron.BrowserWindow; // Module to create native browser window.

// Need this for talking to the main process, which handles the OAuth (partly).
const ipcMain = electron.ipcMain;

// Connect to Elm, where we will keep our domain logic.
const Elm = require('./site/ServerProcessMain').Elm;

const elmPorts = Elm.ServerProcessMain.init().ports;
console.log(elmPorts);
elmPorts.toJavascript.subscribe(msg => console.log('From Elm:', msg));

//TEST INBOUND PORT
elmPorts.fromJavascript.send({ someRandomJson : true });

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

var renderers = [];

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// TODO: Move window management into Elm, make this a mere servant.
app.on('ready',

    function() {
        // Create the browser window.
        mainWindow = new BrowserWindow(
            {
                width: 300,
                height: 100,
                webPreferences: {
                    preload: path.join(__dirname, 'preload.js')
                }
            }
        );

        // and load the index.html of the app.
        mainWindow.loadURL('file://' + __dirname + '/site/LoadButtonRenderer.html');

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

        // Forward IPC calls to Elm.
        ipcMain.on('elmMessage', (event, elmMessage) => {

//            console.log("sending to elm", elmMessage);
            elmPorts.fromJavascript.send(elmMessage);

        });
    }
);
