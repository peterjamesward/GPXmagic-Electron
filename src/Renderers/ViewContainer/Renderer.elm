module Renderers.ViewContainer.Renderer exposing (Model, Msg, main)

import Browser
import Common.GpxPoint as GpxPoint exposing (gpxPointAsJSON)
import Common.RendererType as RendererType exposing (RendererType(..))
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input exposing (button)
import File exposing (File)
import File.Select as Select
import FlatColors.ChinesePalette
import FlatColors.FlatUIPalette
import Html exposing (Html, div)
import Json.Encode as E
import Renderers.LoadButton.GpxParser as GpxParser
import Renderers.LoadButton.IpcStubs as Stubs
import Task
import Time


type Msg
    = MessageFromMainProcess E.Value


type alias Model =
    -- This is the minimal model for our first renderer, which will begin
    -- with only a "Load GPX" button, will become the toolbox.
    -- Note we don't keep a copy of the GPX here!
    { backgroundColour : Element.Color
    }


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
    ( { backgroundColour = FlatColors.FlatUIPalette.silver }
    , Stubs.ipcRendererToMain <|
        E.object
            [ ( "cmd", E.string "hello" )
            , ( "renderer", E.string "ViewContainer" )
            ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageFromMainProcess value ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        buttonStyles =
            [ padding 5
            , Background.color FlatColors.ChinesePalette.antiFlashWhite
            , Border.color FlatColors.FlatUIPalette.peterRiver
            , Border.width 2
            ]
    in
    layout
        [ Background.color model.backgroundColour ]
    <|
        none


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]
