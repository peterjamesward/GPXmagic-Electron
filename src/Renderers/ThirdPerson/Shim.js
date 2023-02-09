// We will have one of these for each renderer.
// It glues the Elm app to JS and tells Elm where to render its HTML.

const app = Elm.Renderers.ThirdPerson.Renderer.init({
    node: document.getElementById("myapp")
});

app.ports.ipcRendererToMain.subscribe(ipcElmToMain);

// Relies on msg.cmd to denote meaning as these all flow across the same ports.
function ipcElmToMain(msg) {

    gpxMagicAPI.sendToServer(msg);

};

// Directly connect Electron messages from upstream into inbound Elm port.
gpxMagicAPI.fromServer(
    (_event, value) => {
        console.log(value);
        app.ports.ipcMainToRenderer.send(value);
    }
);

// Similarly for view-related messages
gpxMagicAPI.viewMessageResp(
    (_event, value) => {
        console.log(value);
        app.ports.receiveViewMessage.send(value);
    }
);
