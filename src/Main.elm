module Main exposing (Model, Msg, main)

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
import IpcStubs
import Json.Encode as E
import Task
import Time


type Msg
    = AdjustTimeZone Time.Zone
    | GpxRequested
    | GpxSelected File
    | GpxLoaded String
    | MessageFromMainProcess E.Value


type alias Model =
    -- This is the minimal model for our first renderer, which will begin
    -- with only a "Load GPX" button, will become the toolbox.
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

        GpxRequested ->
            ( model
            , Select.file [ "text/gpx" ] GpxSelected
            )

        GpxSelected file ->
            ( model
            , Task.perform GpxLoaded (File.toString file)
            )

        GpxLoaded content ->
            let
                gpxPoints =
                    GpxParser.parseSegments content
                        |> Tuple.first
            in
            ( model
            , IpcStubs.loadNewGpx <| E.list identity <| List.map gpxPointAsJSON gpxPoints
            )

        MessageFromMainProcess value ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        loadGpxButton =
            button
                [ padding 5
                , Background.color FlatColors.ChinesePalette.antiFlashWhite
                , Border.color FlatColors.FlatUIPalette.peterRiver
                , Border.width 2
                ]
                { onPress = Just GpxRequested
                , label = text "Load GPX"
                }
    in
    layout
        [ Background.color model.backgroundColour ]
    <|
        wrappedRow
            [ centerX, centerY ]
            [ loadGpxButton

            --, buyMeACoffeeButton
            ]


buyMeACoffeeButton =
    newTabLink
        [ alignRight ]
        { url = "https://www.buymeacoffee.com/Peterward"
        , label =
            image [ height (Element.px 30), width (Element.px 130) ]
                { src = "https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png"
                , description = "Buy Me A Coffee"
                }
        }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ IpcStubs.ipcMainToRenderer MessageFromMainProcess
        ]
