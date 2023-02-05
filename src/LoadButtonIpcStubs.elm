port module LoadButtonIpcStubs exposing (..)

import Json.Encode as E


port ipcRendererToMain : E.Value -> Cmd msg


port ipcMainToRenderer : (E.Value -> msg) -> Sub msg


loadNewGpx : E.Value -> Cmd msg
loadNewGpx pointsAsJSON =
    ipcRendererToMain <|
        E.object
            [ ( "cmd", E.string "newgpx" )
            , ( "content", pointsAsJSON )
            ]


openView : Cmd msg
openView =
    ipcRendererToMain <|
        E.object
            [ ( "cmd", E.string "openview" ) ]
