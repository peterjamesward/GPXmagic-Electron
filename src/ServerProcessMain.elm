port module ServerProcessMain exposing (main)

import Angle
import Direction2d
import DomainModel exposing (GPXSource)
import GpxPoint exposing (GpxPoint)
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
    }


startModel =
    { filename = Nothing
    , tree = Nothing
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

                                _ =
                                    Debug.log "TREE HAS POINTS" <|
                                        Maybe.map DomainModel.skipCount tree
                            in
                            ( { model | tree = tree }
                            , Cmd.none
                            )

                        _ ->
                            --TODO: Return errors.
                            ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fromJavascript MessageFromRenderer ]
