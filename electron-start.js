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

        // Handle view updates without server side Elm.
        ipcMain.on( 'viewMessage', handleViewMessage );
    }
);

// Collect and act on messages from Elm port on server.
function handleElmMessage(msg) {

    switch (msg.cmd) {
        case 'ElmReady':
            console.log("Elm is ready.");
            break;

        case 'newwindow':
            makeWindow(msg.id, msg.window);
            break;

        case 'track':
            // Send track to specified window only.
//            console.log("MAIN: Sending track ", msg.target);
            webContents.fromId(msg.target).send('fromServer', msg);
            break;

        default:
            console.log("MAIN: ", msg.cmd, " unknown command")
    };

};

// Basic window lifecycle.
function makeWindow(elmWindowId, windowSpec) {

//    console.log("MAIN:", windowSpec);
    windowSpec.webPreferences = { preload: path.join(__dirname, 'preload.js') };
    windowSpec.acceptFirstMouse = true;

    var window = new BrowserWindow( windowSpec );

    // We must tell a window how big it is. Send it the spec!
    window.webContents.send('viewResponse',
        { "cmd" : "bounds"
        , "bounds" : windowSpec
        }
    );

    window.on('close',
        function() {
            elmPorts.fromJavascript.send({ cmd : "closed", sender : window.webContents.id });
        }
    );

    // and load the index.html of the app.
    window.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + windowSpec.html + '/Renderer.html');
};

function handleViewMessage ( event, msg ) {
        // Message will contain "new", "move" and "switch" commands.
        if (msg.new != undefined) makeNewViews(event.sender.id, msg.new);
        if (msg.move != undefined) moveViews(event.sender.id, msg.move);
        if (msg.switch != undefined) switchView(event.sender.id, msg.switch); //singular!

};

//TODO: Dict Int ViewSpec (if we were in Elm)

function makeNewViews(windowId, newViewCmds) {

    // Make child views
    const window = BrowserWindow.fromId(windowId);

    newViewCmds.map((newViewCmd) => { createAndAddView(newViewCmd) } );
    // where ...
    function createAndAddView(newViewCmd) {

        console.log("making view", newViewCmd);

        // Having viewSpec match the args for new view makes this more concise.
        newViewCmd.webPreferences = { preload: path.join(__dirname, 'preload.js') };

        //TODO: Tell the ew view how big it is.
        const view = new BrowserView( newViewCmd );
        window.addBrowserView( view );
        view.setBounds( newViewCmd );
//        view.setAutoResize(
//            {
//                width: true,
//                height: true,
//                horizontal : true,
//                vertical : true
//            }
//        );

        // and load the index.html of the view.
        view.webContents.loadURL('file://' + __dirname + '/src/Renderers/' + newViewCmd.html + '/Renderer.html');

        // Open the devtools.
//        view.webContents.openDevTools();

        view.webContents.on('close',
            function() {
                elmPorts.fromJavascript.send({ cmd : "closed", sender : view.webContents.id });
            }
        );
    };
};