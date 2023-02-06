module Renderers.Proforma.Renderer exposing (Model, Msg, main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import FlatColors.ChinesePalette
import FlatColors.FlatUIPalette
import Html exposing (Html, div)
import Json.Encode as E
import Renderers.Proforma.IpcStubs as Stubs
import Task
import Time


type Msg
    = AdjustTimeZone Time.Zone
    | MessageFromMainProcess E.Value


type alias Model =
    -- Note we don't keep a copy of the GPX here!
    { filename : Maybe String
    , time : Time.Posix
    , zone : Time.Zone
    , isPopupOpen : Bool
    , backgroundColour : Element.Color
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
    ( { filename = Nothing
      , time = Time.millisToPosix 0
      , zone = Time.utc
      , isPopupOpen = False
      , backgroundColour = FlatColors.FlatUIPalette.silver
      }
    , Cmd.batch
        [ Task.perform AdjustTimeZone Time.here ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AdjustTimeZone newZone ->
            ( { model | zone = newZone }
            , Cmd.none
            )

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
        column
            [ centerX, centerY ]
            [ text "WebGL here" ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]
