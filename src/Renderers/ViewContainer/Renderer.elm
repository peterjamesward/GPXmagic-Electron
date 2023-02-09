module Renderers.ViewContainer.Renderer exposing (Model, Msg, main)

import Browser
import Common.Layouts as Layout
import Common.ViewPureStyles exposing (useIcon)
import Element exposing (..)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input exposing (button)
import FeatherIcons
import FlatColors.AussiePalette
import FlatColors.FlatUIPalette
import Html exposing (Html)
import Json.Encode as E
import Renderers.ViewContainer.IpcStubs as Stubs


type Msg
    = MessageFromMainProcess E.Value
    | NoOp
    | Layout Layout.LayoutStyle


type alias Model =
    -- This is the minimal model for our first renderer, which will begin
    -- with only a "Load GPX" button, will become the toolbox.
    -- Note we don't keep a copy of the GPX here!
    { backgroundColour : Element.Color
    , layout : Layout.LayoutStyle
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
    --We send the description of how the views should be arranged, as only the
    --electron main process can actually create them.
    ( { backgroundColour = FlatColors.FlatUIPalette.clouds
      , layout = Layout.LayoutSingle
      }
    , Stubs.sendViewMessage <|
        E.object
            [ ( "new", E.list Layout.newViewCmdAsJson Layout.initViewCmd ) ]
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MessageFromMainProcess value ->
            ( model, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        Layout layout ->
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    layout
        [ Background.color model.backgroundColour
        , centerY
        , centerX
        ]
    <|
        text "Container ready"


modeButtons =
    --TODO: If toolbox collapsed, show these in a column.
    --TODO: else in a row at top of toolbox.
    column
        [ alignTop
        , alignLeft
        , Background.color FlatColors.FlatUIPalette.clouds
        , Font.size 40
        , padding 2
        , spacing 8
        , Border.width 1
        , Border.rounded 4
        , Border.color FlatColors.AussiePalette.blurple
        ]
        [ Input.button []
            { onPress = Just <| Layout Layout.LayoutSingle
            , label = useIcon FeatherIcons.maximize
            }
        , Input.button []
            { onPress = Just <| Layout Layout.LayoutCupboards
            , label = useIcon FeatherIcons.columns
            }
        , Input.button []
            { onPress = Just <| Layout Layout.LayoutDrawers
            , label = useIcon FeatherIcons.server
            }
        , Input.button []
            { onPress = Just <| Layout Layout.LayoutGrid
            , label = useIcon FeatherIcons.grid
            }
        ]


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.batch
        [ Stubs.ipcMainToRenderer MessageFromMainProcess ]
