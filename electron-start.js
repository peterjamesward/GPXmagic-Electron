const path = require('path')
//var electron = require('electron')

//var app = electron.app; // Module to control application life.
//var BrowserWindow = electron.BrowserWindow; // Module to create native browser window.
const { electron, app, ipcMain, webContents, BrowserWindow, BrowserView } = require('electron');

// Need this for talking to the main process, which handles the OAuth (partly).
//const ipcMain = electron.ipcMain;

// Connect to Elm, where we will keep our domain logic.
const Elm = require('./site/ServerProcessMain').Elm;

const elmPorts = Elm.ServerProcess.Main.init().ports;
console.log("MAIN: ", elmPorts);

elmPorts.toJavascript.subscribe(handleElmMessage);

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

// JS dictionary of windows, should match the Elm version. Could go badly wrong.
var windowsElmToElectron = new Map();
var windowsElectronToElm = new Map();

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// TODO: Move window management into Elm, make this a mere servant.
app.on('ready',

    function() {

        //Signal readiness to Elm
        elmPorts.fromJavascript.send({ "cmd" : "ready" });

        // Forward IPC calls to Elm.
        ipcMain.on('elmMessage', (event, elmMessage) => {

            // Use the Elm source id, map back on response.
            elmMessage.sender = windowsElectronToElm.get(event.sender.id);
            console.log("MAIN: sending to Main", elmMessage.cmd);
            elmPorts.fromJavascript.send( elmMessage );

        });
    }
);

// Collect and act on messages from Elm port on server.
function handleElmMessage(msg) {

//    console.log('MAIN: Message from Elm', msg)
//    console.log("OUTBOUND MAPPING", windowsElmToElectron, msg.target);
    const targetRenderer = windowsElmToElectron.get(msg.target);

    switch (msg.cmd) {
        case 'newwindow':
            makeWindow(msg.id, msg.window);
            break;

        case 'track':
            // Send track to specified window only.
            console.log("MAIN: Sending track ", msg.target);
            webContents.fromId(targetRenderer).send('fromServer', msg);
            break;

        default:
            console.log("MAIN: ", msg.cmd, " unknown command")
    };

};

// Basic window lifecycle.
function makeWindow(elmWindowId, windowSpec) {

//    console.log("MAIN:", windowSpec);

    var window = new BrowserWindow(
        {
            width: windowSpec.width,
            height: windowSpec.height,
            x : windowSpec.left,
            y : windowSpec.top,
            acceptFirstMouse : true,
            webPreferences: {
                preload: path.join(__dirname, 'preload.js')
            }
        }
    );

    const view = new BrowserView(
        {
            width: windowSpec.width,
            height: windowSpec.height,
            x : windowSpec.left,
            y : windowSpec.top,
            acceptFirstMouse : true,
            webPreferences: {
                preload: path.join(__dirname, 'preload.js')
            }
        }
    )
    window.setBrowserView(view)
    view.setBounds({ x: 0, y: 20, width: 300, height: 120 })
    view.setAutoResize( { height : true, width : true } )

    // Keep track of windows on both sides.
    windowsElectronToElm.set(view.webContents.id, elmWindowId)
    windowsElmToElectron.set(elmWindowId, view.webContents.id)
    console.log("MAPPING", windowsElectronToElm)

    // and load the index.html of the app.
    view.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + windowSpec.html + '/Renderer.html');

    // Open the devtools.
    view.webContents.openDevTools();

    // Emitted when the window is closed.
    view.webContents.on('close',
        function() {
            const elmId = windowsElectronToElm.get(view.webContents.id);
            elmPorts.fromJavascript.send({ cmd : "closed", id : elmId });
            windowsElectronToElm.delete(view.webContents.id);
            windowsElmToElectron.delete(elmId);
        }
    );
};