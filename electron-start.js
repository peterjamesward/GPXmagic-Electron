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

        case 'ElmReady':
            console.log("Elm is ready.");
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
            width: 800, //windowSpec.width,
            height: 200, //windowSpec.height,
            x : windowSpec.left,
            y : windowSpec.top,
            acceptFirstMouse : true,
            webPreferences: {
                preload: path.join(__dirname, 'preload.js')
            }
        }
    );

    //TODO: Neaten this and generalise for different pane layouts. - In Elm or in JS??
    contentSize = window.getContentSize();

    const viewLeft = new BrowserView(
        {
            width: contentSize[0] / 2,
            height: contentSize[1],
            x : 0,
            y : 100,
            webPreferences: {
                preload: path.join(__dirname, 'preload.js')
            }
        }
    );
    const viewRight = new BrowserView(
        {
            width: contentSize[0] / 2,
            height: contentSize[1],
            x : 100,
            y : 0,
            webPreferences: {
                preload: path.join(__dirname, 'preload.js')
            }
        }
    );
    window.addBrowserView(viewLeft);
    window.addBrowserView(viewRight);
    viewLeft.setBounds(
        {
            width: 300,
            height: 100,
            x: 0,
            y: 0
        });
    viewRight.setBounds(
        {
            width: 400,
            height: 400,
            x : 300,
            y : 0
        });

    // Keep track of windows between Electron and Elm.
    windowsElectronToElm.set(viewLeft.webContents.id, elmWindowId);
    windowsElectronToElm.set(viewRight.webContents.id, elmWindowId);
    windowsElmToElectron.set(elmWindowId, viewLeft.webContents.id);
    windowsElmToElectron.set(elmWindowId, viewRight.webContents.id);
//    console.log("MAPPING", windowsElectronToElm);

//    viewLeft.setAutoResize(
//        {
//            width : true,
//            height : true,
//            horizontal : true,
//            vertical : true
//        }
//    );
//    viewRight.setAutoResize(
//        {
//            width : true,
//            height : true,
//            horizontal : true,
//            vertical : true
//        }
//    );

    // and load the index.html of the app.
    viewLeft.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + windowSpec.html + '/Renderer.html');
    viewRight.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + windowSpec.html + '/Renderer.html');

    // Open the devtools.
//    view.webContents.openDevTools();

    // Emitted when the window is closed.
    viewLeft.webContents.on('close',
        function() {
            const elmId = windowsElectronToElm.get(viewLeft.webContents.id);
            elmPorts.fromJavascript.send({ cmd : "closed", id : elmId });
            windowsElectronToElm.delete(viewLeft.webContents.id);
            windowsElmToElectron.delete(elmId);
        }
    );
    viewRight.webContents.on('close',
        function() {
            const elmId = windowsElectronToElm.get(viewRight.webContents.id);
            elmPorts.fromJavascript.send({ cmd : "closed", id : elmId });
            windowsElectronToElm.delete(viewRight.webContents.id);
            windowsElmToElectron.delete(elmId);
        }
    );
};