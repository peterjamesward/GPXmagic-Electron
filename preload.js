// This piece of JS runs when a window is opened, and allows us to get hold of Electron context.
// For GPXmagic it effectively exposes the API between renderer and the main process.
// Not all renderers will use all the API.

const { contextBridge, ipcRenderer } = require('electron')

var responseFn;

contextBridge.exposeInMainWorld('electronAPI', {
    // Each renderer injects its response function here. This will be called
    // when the main process sends a message, see the `ipcRenderer.on` function below.
    setResponseFn: (f) => responseFn = f,
    requestAuth: (config) => ipcRenderer.send('requestAuth', config)
});

ipcRenderer.on('code', (_event, code) => {
    responseFn({ Cmd : 'Code', code : code});
})
