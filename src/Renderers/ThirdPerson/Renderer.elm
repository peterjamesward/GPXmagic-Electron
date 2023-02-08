module Renderers.ThirdPerson.Renderer exposing (Model, Msg, main)

import Angle
import Browser
import Camera3d
import Color
import Common.About as About
import Common.LocalCoords exposing (LocalCoords)
import Direction2d
import Direction3d exposing (negativeZ, positiveZ)
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html, div)
import Json.Decode as D
import Json.Encode as E
import Length
import Markdown
import Pixels exposing (pixels)
import Point3d
import Renderers.LoadButton.IpcStubs as Stubs
import Renderers.ThirdPerson.SceneBuilder3D as Builder
import Scene3d exposing (Entity, backgroundColor)
import Viewpoint3d


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
    , Stubs.ipcRendererToMain <|
        E.object
            [ ( "cmd", E.string "hello" )
            , ( "renderer", E.string "ThirdPerson" )
            ]
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
                    let
                        points =
                            D.decodeValue
                                (D.field "track" (D.list localPointDecoder))
                                jsonMessage
                    in
                    case points of
                        Ok somePoints ->
                            ( { model
                                | scene =
                                    Builder.render3dView <|
                                        List.map
                                            (Point3d.fromRecord Length.meters)
                                            somePoints
                              }
                            , Cmd.none
                            )

                        Err _ ->
                            let
                                _ =
                                    Debug.log "NO POINTS " ()
                            in
                            ( model, Cmd.none )

                _ ->
                    let
                        _ =
                            Debug.log "CMD?? " cmd
                    in
                    ( model, Cmd.none )


type alias LocalPoint =
    { x : Float
    , y : Float
    , z : Float
    }


localPointDecoder =
    D.map3 LocalPoint
        (D.field "x" D.float)
        (D.field "y" D.float)
        (D.field "z" D.float)


view : Model -> Html Msg
view model =
    let
        cameraViewpoint =
            Viewpoint3d.orbitZ
                { focalPoint = Point3d.origin
                , azimuth = Direction2d.toAngle Direction2d.positiveX
                , elevation = Angle.degrees 45
                , distance = Length.kilometer
                }

        camera =
            Camera3d.perspective
                { viewpoint = cameraViewpoint
                , verticalFieldOfView = Angle.degrees 45
                }
    in
    layout [] <|
        if List.length model.scene == 0 then
            paragraph
                [ width fill, padding 20, Font.size 14 ]
            <|
                [ html <| Markdown.toHtml [] About.aboutText ]

        else
            html <|
                Scene3d.sunny
                    { camera = camera
                    , dimensions = ( pixels 800, pixels 600 )
                    , background = backgroundColor Color.lightBlue
                    , clipDepth = Length.meters 1
                    , entities = model.scene
                    , upDirection = positiveZ
                    , sunlightDirection = negativeZ
                    , shadows = False
                    }


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]