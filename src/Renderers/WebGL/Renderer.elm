module Renderers.WebGL.Renderer exposing (Model, Msg, main)

import Browser
import Common.About as About
import Common.LocalCoords exposing (LocalCoords)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import FlatColors.ChinesePalette
import FlatColors.FlatUIPalette
import Html exposing (Html, div)
import Json.Decode as D
import Json.Encode as E
import Markdown
import Renderers.LoadButton.IpcStubs as Stubs
import Scene3d exposing (Entity)
import Task
import Time


type Msg
    = MessageFromMainProcess E.Value


type alias Model =
    -- Note we don't need a copy of the GPX here!
    { scene : List (Entity LocalCoords) }


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


init : () -> ( Model, Cmd Msg )
init _ =
    --TODO: Remove dummy message put here to make sure the port exists.
    ( { scene = [] }
    , Stubs.ipcRendererToMain E.null
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageFromMainProcess jsonMessage ->
            let
                cmd =
                    D.decodeValue (D.field "cmd" D.string) jsonMessage

                _ =
                    Debug.log "CMD" cmd
            in
            case cmd of
                Ok "track" ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


view : Model -> Html Msg
view model =
    layout [] <|
        paragraph
            [ width fill, padding 20, Font.size 14 ]
        <|
            [ html <| Markdown.toHtml [] About.aboutText ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]
