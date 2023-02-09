port module Renderers.ViewContainer.IpcStubs exposing (..)

import Common.RendererType as RendererType exposing (RendererType)
import Json.Encode as E


port ipcRendererToMain : E.Value -> Cmd msg


port ipcMainToRenderer : (E.Value -> msg) -> Sub msg


newView : RendererType -> Cmd msg
newView renderer =
    ipcRendererToMain <|
        E.object
            [ ( "cmd", E.string "newview" )
            , ( "renderer", E.string <| RendererType.rendererTypeAsString renderer )
            ]
