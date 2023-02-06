module Renderers.WebGL.Renderer exposing (Model, Msg, main)

import Browser
import Common.About as About
import Common.LocalCoords exposing (LocalCoords)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import FlatColors.ChinesePalette
import FlatColors.FlatUIPalette
import Html exposing (Html, div)
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
    ( { scene = [] }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageFromMainProcess value ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    layout [] <|
        paragraph
            [ width fill, padding 20 ]
        <|
            [ html <| Markdown.toHtml [] About.aboutText ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]
