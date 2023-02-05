module ServerProcessMain exposing (Model, Msg, main)

import Browser
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Input as Input exposing (button)
import File exposing (File)
import File.Select as Select
import FlatColors.ChinesePalette
import FlatColors.FlatUIPalette
import GpxParser
import GpxPoint exposing (gpxPointAsJSON)
import Html exposing (Html, div)
import Json.Encode as E
import LoadButtonIpcStubs
import Task
import Time


type Msg
    = AdjustTimeZone Time.Zone
    | MessageFromRenderer E.Value


type alias Model =
    -- This is the minimal model for our first renderer, which will begin
    -- with only a "Load GPX" button, will become the toolbox.
    -- Note we don't keep a copy of the GPX here!
    { filename : Maybe String
    , time : Time.Posix
    , zone : Time.Zone
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

        MessageFromRenderer value ->
            ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ LoadButtonIpcStubs.ipcMainToRenderer MessageFromRenderer
        ]
