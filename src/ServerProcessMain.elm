port module ServerProcessMain exposing (main)

import Json.Decode as D
import Json.Encode as E
import Platform exposing (Program)


port fromJavascript : (E.Value -> msg) -> Sub msg


port toJavascript : E.Value -> Cmd msg


type Msg
    = MessageFromRenderer E.Value


type alias Model =
    -- This is the minimal model for our first renderer, which will begin
    -- with only a "Load GPX" button, will become the toolbox.
    -- Note we don't keep a copy of the GPX here!
    { filename : Maybe String }


startModel =
    { filename = Nothing }


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
        MessageFromRenderer value ->
            let
                cmd =
                    D.decodeValue (D.field "cmd" D.string) value

                _ =
                    Debug.log "CMD" cmd
            in
            case cmd of
                Ok "newgpx" ->
                    ( model, Cmd.none )

                _ ->
                    ( model, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ fromJavascript MessageFromRenderer ]
