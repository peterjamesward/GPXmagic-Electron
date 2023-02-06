port module ServerProcessMain exposing (main)

import Angle
import Dict exposing (Dict)
import Direction2d
import DomainModel exposing (GPXSource)
import GpxPoint exposing (GpxPoint)
import Json.Decode as D
import Json.Encode as E
import Length
import Platform exposing (Program)
import RendererType exposing (RendererType(..))


port fromJavascript : (E.Value -> msg) -> Sub msg


port toJavascript : E.Value -> Cmd msg


type Msg
    = MessageFromRenderer E.Value


type alias Model =
    -- This is the minimal model for our first renderer, which will begin
    -- with only a "Load GPX" button, will become the toolbox.
    -- Note we don't keep a copy of the GPX here!
    { filename : Maybe String
    , tree : Maybe DomainModel.PeteTree
    , windows : Dict Int RendererWindow
    , nextWindowId : Int
    }


startModel =
    { filename = Nothing
    , tree = Nothing
    , windows = Dict.empty
    , nextWindowId = 0
    }


main : Program () Model Msg
main =
    Platform.worker
        { init = always init
        , update = update
        , subscriptions = subscriptions
        }


init =
    ( startModel
    , toJavascript <| E.object [ ( "msg", E.string "Hello from Elm" ) ]
    )



{- Start by processing newgpx...
   E.object
       [ ( "cmd", E.string "newgpx" )
       , ( "content", pointsAsJSON )
       ]
-}


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageFromRenderer jsonMessage ->
            let
                cmd =
                    D.decodeValue (D.field "cmd" D.string) jsonMessage

                pointConverter : GpxPoint -> DomainModel.GPXSource
                pointConverter gpx =
                    { longitude = Direction2d.fromAngle <| Angle.degrees gpx.longitude
                    , latitude = Angle.degrees gpx.latitude
                    , altitude = Length.meters gpx.altitude
                    , timestamp = gpx.timestamp
                    }

                _ =
                    Debug.log "CMD" cmd
            in
            case cmd of
                Ok "ready" ->
                    --The Electron server is ready to execute our instructions.
                    --Begin by making a main window; this will become our toolbox, probably.
                    makeNewWindow toolWindow model

                Ok "newgpx" ->
                    let
                        rawGpxPoints =
                            D.decodeValue
                                (D.field "content" (D.list GpxPoint.gpxDecoder))
                                jsonMessage
                    in
                    case rawGpxPoints of
                        Ok rawPoints ->
                            let
                                internalPoints : List GPXSource
                                internalPoints =
                                    List.map pointConverter rawPoints

                                tree =
                                    DomainModel.treeFromSourcePoints internalPoints
                            in
                            ( { model | tree = tree }
                            , Cmd.none
                            )

                        _ ->
                            --TODO: Return errors.
                            ( model, Cmd.none )

                Ok "newview" ->
                    --When view added, send it a tree if available.
                    --When tree loaded, send to all views.
                    case D.decodeValue (D.field "renderer" D.string) jsonMessage of
                        Ok foundRenderer ->
                            case RendererType.rendererTypeFromString foundRenderer of
                                Just renderer ->
                                    makeNewWindow
                                        (rendererWindow renderer)
                                        model

                                Nothing ->
                                    ( model, Cmd.none )

                        Err _ ->
                            ( model, Cmd.none )

                Ok "closed" ->
                    --User closed a window, remove it.
                    let
                        windowId =
                            D.decodeValue (D.field "id" D.int) jsonMessage
                    in
                    case windowId of
                        Ok id ->
                            ( { model | windows = Dict.remove id model.windows }
                            , Cmd.none
                            )

                        Err _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fromJavascript MessageFromRenderer ]



--TODO: Extract to separate module...


type alias RendererWindow =
    { rendererType : RendererType
    , width : Int
    , height : Int
    }


toolWindow =
    { rendererType = RendererToolbox
    , width = 300
    , height = 100
    }


rendererWindow rendererType =
    { rendererType = rendererType
    , width = 800
    , height = 600
    }


makeNewWindow : RendererWindow -> Model -> ( Model, Cmd Msg )
makeNewWindow window model =
    ( { model
        | windows = model.windows |> Dict.insert model.nextWindowId window
        , nextWindowId = 1 + model.nextWindowId
      }
    , toJavascript <|
        E.object
            [ ( "cmd", E.string "newwindow" )
            , ( "id", E.int model.nextWindowId )
            , ( "window", windowAsJson window )
            ]
    )


rendererHtmlFile : RendererType -> String
rendererHtmlFile rendererType =
    --Yes, this is crucial Electron-level config here.
    --TODO: Add each type carefully.
    case rendererType of
        RendererToolbox ->
            "LoadButtonRenderer"

        Renderer3D ->
            "WebGLRenderer"

        RendererProfile ->
            "WebGLRenderer"

        RendererCanvasChart ->
            "WebGLRenderer"

        RendererMap ->
            "WebGLRenderer"


windowAsJson : RendererWindow -> E.Value
windowAsJson window =
    E.object
        [ ( "html", E.string <| rendererHtmlFile window.rendererType )
        , ( "width", E.int window.width )
        , ( "height", E.int window.height )
        ]
