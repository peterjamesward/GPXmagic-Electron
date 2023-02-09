port module Renderers.ViewContainer.IpcStubs exposing (..)

import Common.RendererType as RendererType exposing (RendererType)
import Json.Encode as E


port ipcRendererToMain : E.Value -> Cmd msg


port ipcMainToRenderer : (E.Value -> msg) -> Sub msg


port sendViewMessage : E.Value -> Cmd msg


port receiveViewMessage : (E.Value -> msg) -> Sub msg
