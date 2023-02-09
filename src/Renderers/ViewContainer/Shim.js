// We will have one of these for each renderer.
// It glues the Elm app to JS and tells Elm where to render its HTML.

const app = Elm.Renderers.ViewContainer.Renderer.init({
    node: document.getElementById("myapp")
});

//app.ports.ipcRendererToMain.subscribe(ipcElmToMain);

app.ports.sendViewMessage.subscribe(sendViewMessage);

// Relies on msg.cmd to denote meaning as these all flow across the same ports.
function ipcElmToMain(msg) {
    gpxMagicAPI.sendToServer(msg);
};

function sendViewMessage(msg) {
    gpxMagicAPI.sendViewMessage(msg);
};

