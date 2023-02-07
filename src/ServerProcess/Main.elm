port module ServerProcess.Main exposing (main)

import Angle
import Common.DomainModel as DomainModel exposing (GPXSource, earthPointAsJson)
import Common.GpxPoint as GpxPoint exposing (GpxPoint)
import Common.Layouts exposing (RendererWindow, toolWindow, windowAsJson, windowGrid)
import Common.RendererType as RendererType exposing (RendererType(..))
import Dict exposing (Dict)
import Direction2d
import Json.Decode as D
import Json.Encode as E
import Length
import Platform exposing (Program)


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
    , windowsAndViews : Dict Int RendererType -- should suffice that we know what to send to each view.
    , nextWindowId : Int
    }


startModel : Model
startModel =
    { filename = Nothing
    , tree = Nothing
    , windowsAndViews = Dict.empty
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
    , toJavascript <| E.object [ ( "cmd", E.string "ElmReady" ) ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageFromRenderer jsonMessage ->
            let
                senderId =
                    D.decodeValue (D.field "sender" D.int) jsonMessage

                cmd =
                    D.decodeValue (D.field "cmd" D.string) jsonMessage

                renderer =
                    D.decodeValue (D.field "renderer" D.string) jsonMessage

                pointConverter : GpxPoint -> DomainModel.GPXSource
                pointConverter gpx =
                    { longitude = Direction2d.fromAngle <| Angle.degrees gpx.longitude
                    , latitude = Angle.degrees gpx.latitude
                    , altitude = Length.meters gpx.altitude
                    , timestamp = gpx.timestamp
                    }

                earthPoints tree =
                    Maybe.map (DomainModel.elidedEarthPoints 10) tree

                pointsAsJson tree =
                    case earthPoints tree of
                        Just points ->
                            E.list earthPointAsJson points

                        Nothing ->
                            E.null

                _ =
                    Debug.log "CMD" ( cmd, senderId )
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

                                newModel =
                                    { model | tree = DomainModel.treeFromSourcePoints internalPoints }
                            in
                            ( newModel
                            , sendToAll (pointsAsJson newModel.tree) newModel
                            )

                        _ ->
                            --TODO: Return errors.
                            ( model, Cmd.none )

                Ok "newview" ->
                    -- Just open a new window - it will say "hello" when ready.
                    case renderer of
                        Ok foundRenderer ->
                            case RendererType.rendererTypeFromString foundRenderer of
                                Just rendererType ->
                                    --TODO: Use rendererType
                                    makeNewWindow
                                        windowGrid
                                        model

                                Nothing ->
                                    ( model, Cmd.none )

                        Err _ ->
                            ( model, Cmd.none )

                Ok "hello" ->
                    -- Window is ready, send it track in appropriate format and detail.
                    case ( senderId, renderer ) of
                        ( Ok id, Ok foundRenderer ) ->
                            case RendererType.rendererTypeFromString foundRenderer of
                                Just rendererType ->
                                    ( { model
                                        | windowsAndViews =
                                            Dict.insert id rendererType model.windowsAndViews
                                      }
                                      --TODO: Use renderer type
                                    , sendTrackToRenderer (pointsAsJson model.tree) id
                                    )

                                Nothing ->
                                    let
                                        _ =
                                            Debug.log "unknown renderer" renderer
                                    in
                                    ( model, Cmd.none )

                        _ ->
                            let
                                _ =
                                    Debug.log "unknown" ( senderId, renderer )
                            in
                            ( model, Cmd.none )

                Ok "closed" ->
                    --User closed a window, remove it.
                    case senderId of
                        Ok id ->
                            ( { model | windowsAndViews = Dict.remove id model.windowsAndViews }
                            , Cmd.none
                            )

                        Err _ ->
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


sendTrackToRenderer pointsAsJson id =
    toJavascript <|
        E.object
            [ ( "cmd", E.string "track" )
            , ( "target", E.int id )
            , ( "track", pointsAsJson )
            ]


sendToAll : E.Value -> Model -> Cmd Msg
sendToAll pointsAsJson model =
    --TODO: Use renderer type.
    model.windowsAndViews
        |> Dict.keys
        |> List.map (sendTrackToRenderer pointsAsJson)
        |> Cmd.batch


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fromJavascript MessageFromRenderer ]


makeNewWindow : RendererWindow -> Model -> ( Model, Cmd Msg )
makeNewWindow window model =
    let
        newWindowCommand =
            --Try passing the track to send to the new window only.
            toJavascript <|
                E.object
                    [ ( "cmd", E.string "newwindow" )
                    , ( "id", E.int model.nextWindowId )
                    , ( "window", windowAsJson window )
                    ]
    in
    ( model
    , newWindowCommand
    )
