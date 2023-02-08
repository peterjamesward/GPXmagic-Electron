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

// This method will be called when Electron has finished
// initialization and is ready to create browser windows.
// TODO: Move window management into Elm, make this a mere servant.
app.on('ready',

    function() {

        //Signal readiness to Elm
        elmPorts.fromJavascript.send({ "cmd" : "ready" });

        // Forward IPC calls to Elm.
        ipcMain.on('elmMessage', (event, elmMessage) => {

            elmMessage.sender = event.sender.id;
            console.log("MAIN:", elmMessage.sender, " sent", elmMessage.cmd);
            elmPorts.fromJavascript.send( elmMessage );

        });
    }
);

// Collect and act on messages from Elm port on server.
function handleElmMessage(msg) {

//    console.log('MAIN: Message from Elm', msg)
//    console.log("OUTBOUND MAPPING", windowsElmToElectron, msg.target);

    switch (msg.cmd) {
        case 'newwindow':
            makeWindow(msg.id, msg.window);
            break;

        case 'track':
            // Send track to specified window only.
            console.log("MAIN: Sending track ", msg.target);
            webContents.fromId(msg.target).send('fromServer', msg);
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
            width: windowSpec.width,
            height: windowSpec.height,
            x : windowSpec.left,
            y : windowSpec.top,
            acceptFirstMouse : true, // only works on MacOS, sadly.
            webPreferences: {
                preload: path.join(__dirname, 'preload.js')
            }
        }
    );

    window.on('close',
        function() {
            elmPorts.fromJavascript.send({ cmd : "closed", sender : window.webContents.id });
        }
    );

    // and load the index.html of the app.
    window.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + windowSpec.html + '/Renderer.html');

    // Make any child views
    //TODO: Left and right toolboxes. Reserved left/top are gone away.
    //TODO: Move the layout maths into Main.elm, this is a dumb servant.
    contentSize = window.getContentSize();

    windowSpec.views.map((viewSpec) => { createAndAddView(viewSpec)});
    // where ...
    function createAndAddView(viewSpec) {

//        console.log("making view", viewSpec);

        // Having viewSpec match the args for new view makes this more concise.
        viewSpec.webPreferences = { preload: path.join(__dirname, 'preload.js') };

        const view = new BrowserView( viewSpec );
        window.addBrowserView( view );
        view.setBounds( viewSpec );
        view.setAutoResize(
            {
                width: true,
                height: true,
                horizontal : true,
                vertical : true
            }
        );

        // and load the index.html of the view.
        view.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + viewSpec.html + '/Renderer.html');

        // Open the devtools.
        view.webContents.openDevTools();

        view.webContents.on('close',
            function() {
                elmPorts.fromJavascript.send({ cmd : "closed", sender : view.webContents.id });
            }
        );
    };

};