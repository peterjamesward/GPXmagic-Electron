port module Renderers.Proforma.IpcStubs exposing (..)

import Json.Encode as E


port ipcRendererToMain : E.Value -> Cmd msg


port ipcMainToRenderer : (E.Value -> msg) -> Sub msg



--loadNewGpx : E.Value -> Cmd msg
--loadNewGpx pointsAsJSON =
--    ipcRendererToMain <|
--        E.object
--            [ ( "cmd", E.string "newgpx" )
--            , ( "content", pointsAsJSON )
--            ]
--newView : RendererType -> Cmd msg
--newView renderer =
--    ipcRendererToMain <|
--        E.object
--            [ ( "cmd", E.string "newview" )
--            , ( "renderer", E.string <| RendererType.rendererTypeAsString renderer )
--            ]
