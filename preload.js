// This piece of JS runs when a window is opened, and allows us to get hold of Electron context.
// For GPXmagic it effectively exposes the API between renderer and the main process.
// Not all renderers will use all the API.

const { contextBridge, ipcRenderer } = require('electron')

var responseFn;

contextBridge.exposeInMainWorld('gpxMagicAPI', {
    // Each renderer injects its response function here. This will be called
    // when the main process sends a message, see the `ipcRenderer.on` function below.
//    setResponseFn: (f) => responseFn = f,

    // IPC channel from client Elm to server Elm
    sendToServer: (content) => ipcRenderer.send('elmMessage', content),
    fromServer: (callback) => ipcRenderer.on('fromServer', callback),

    // Channel from client Elm to server Javascript to control views
    sendViewMessage: (content) => ipcRenderer.send('viewMessage', content),
    viewMessageResp: (callback) => ipcRenderer.on('viewResponse', content)
})

