// We will have one of these for each renderer.
// It glues the Elm app to JS and tells Elm where to render its HTML.

const app = Elm.Main.init({
    node: document.getElementById("myapp")
});

app.ports.ipcRendererToMain.subscribe(ipcElmToMain);

// Relies on msg.cmd to denote meaning as these all flow across the same ports.
// Each case here should call a distinct API in the gpxMagicAPI.
function ipcElmToMain(msg) {

    switch (msg.cmd) {
        case 'newgpx':
//            gpxMagicAPI.setResponseFn(ipcMainToRenderer);
            console.log("SENDING" + msg.content);
            gpxMagicAPI.loadGpx(msg.content);
            break;

        case 'response':
            // Messages coming back from Main process we send to the port for Elm.
            app.ports.ipcMainToRenderer.send( msg.code );
            break;
    };
};

