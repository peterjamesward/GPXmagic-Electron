module Renderers.WebGL.Renderer exposing (Model, Msg, main)

import Browser
import Common.About as About
import Common.LocalCoords exposing (LocalCoords)
import Element exposing (..)
import Element.Font as Font
import Html exposing (Html, div)
import Json.Decode as D
import Json.Encode as E
import Length
import Markdown
import Point3d
import Renderers.LoadButton.IpcStubs as Stubs
import Renderers.WebGL.SceneBuilder3D as Builder
import Scene3d exposing (Entity)


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
    , Stubs.ipcRendererToMain <| E.object [ ( "cmd", E.string "hello" ) ]
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
    layout [] <|
        paragraph
            [ width fill, padding 20, Font.size 14 ]
        <|
            [ html <| Markdown.toHtml [] About.aboutText ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]
