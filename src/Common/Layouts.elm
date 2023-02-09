module Common.Layouts exposing (..)

import Common.RendererType exposing (RendererType(..))
import Json.Decode as D
import Json.Encode as E
import List.Extra


type LayoutStyle
    = LayoutSingle
    | LayoutDrawers
    | LayoutCupboards
    | LayoutGrid
    | LayoutDresser


type alias Layout =
    { layoutStyle : LayoutStyle
    , renderers : List RendererType
    }


type alias RendererWindow =
    -- Windows are positioned absolutely.
    { containerRenderer : RendererType
    , width : Int
    , height : Int
    , top : Int
    , left : Int
    , views : List RendererView
    , leftToolboxVisible : Bool
    , rightToolboxVisible : Bool
    }


type alias RendererView =
    -- Views are positioned relative to their containing window after toolboxes deducted.
    { rendererType : RendererType
    , widthPercent : Float
    , heightPercent : Float
    , topPercent : Float
    , leftPercent : Float
    }


type alias NewViewCmd =
    -- Electron main will use this to create a new view.
    { rendererType : RendererType
    , width : Int
    , height : Int
    , top : Int
    , left : Int
    }


type alias MoveViewCmd =
    -- Electron main will use this to reposition an existing view
    { viewRef : Int
    , width : Int
    , height : Int
    , top : Int
    , left : Int
    }


type alias SwitchViewCmd =
    -- Electron main will use this to change renderer for an existing view
    { viewRef : Int
    , renderer : RendererType
    }


initViewCmd : List NewViewCmd
initViewCmd =
    --Me, trying to bootstrap this currently ungainly process.
    [ leftToolbox
    , rightToolbox
    , newViewCmd defaultViewContainer paneFull
    ]


newViewCmd : RendererWindow -> RendererView -> NewViewCmd
newViewCmd window view =
    let
        ( left, right ) =
            ( if window.leftToolboxVisible then
                300

              else
                30
            , if window.rightToolboxVisible then
                window.width - 300

              else
                window.width - 30
            )

        ( contentWidthPercent, contentHeightPercent ) =
            ( toFloat (right - left) / 100
            , toFloat window.height / 100
            )

        ( viewLeft, viewWidth ) =
            ( left + (truncate <| contentWidthPercent * view.leftPercent)
            , truncate <| contentWidthPercent * view.widthPercent
            )

        ( viewTop, viewHeight ) =
            ( truncate <| contentHeightPercent * view.topPercent
            , truncate <| contentHeightPercent * view.heightPercent
            )
    in
    { rendererType = view.rendererType
    , left = viewLeft
    , top = viewTop
    , width = viewWidth
    , height = viewHeight
    }


emptyLayout : RendererWindow
emptyLayout =
    { containerRenderer = RendererMultiPane
    , width = 1000
    , height = 750
    , top = 120 + 28 --TODO: Get the actual title bar height and screen size.
    , left = 0
    , views = []
    , leftToolboxVisible = False
    , rightToolboxVisible = False
    }


leftToolbox : NewViewCmd
leftToolbox =
    { rendererType = RendererToolbox
    , left = emptyLayout.left
    , top = 0
    , width = 300
    , height = emptyLayout.height
    }


contentArea : NewViewCmd
contentArea =
    { rendererType = Renderer3D
    , left = leftToolbox.left + leftToolbox.width
    , top = 0
    , width = emptyLayout.width - leftToolbox.width - rightToolbox.width
    , height = emptyLayout.height
    }


rightToolbox : NewViewCmd
rightToolbox =
    { rendererType = RendererToolbox
    , left = emptyLayout.width - 300
    , top = 0
    , width = 300
    , height = emptyLayout.height
    }


defaultViewContainer : RendererWindow
defaultViewContainer =
    -- v3 compatible with toolbox on right.
    { containerRenderer = RendererMultiPane
    , width = 1000
    , height = 750
    , top = 120 + 28 --TODO: Get the actual title bar height and screen size.
    , left = 300
    , views = [ paneFull ]
    , leftToolboxVisible = True
    , rightToolboxVisible = True
    }


paneFull : RendererView
paneFull =
    { widthPercent = 100.0
    , heightPercent = 100.0
    , topPercent = 0.0
    , leftPercent = 0.0
    , rendererType = Renderer3D
    }


paneLeft : RendererView
paneLeft =
    { paneFull | widthPercent = 50.0 }


paneRight : RendererView
paneRight =
    { paneLeft | leftPercent = 50.0 }


paneTop : RendererView
paneTop =
    { paneFull | heightPercent = 50.0 }


paneBottom : RendererView
paneBottom =
    { paneTop | topPercent = 50.0 }


paneTopLeft : RendererView
paneTopLeft =
    { paneLeft | heightPercent = 50.0 }


paneBottomLeft : RendererView
paneBottomLeft =
    { paneTopLeft | topPercent = 50.0 }


paneTopRight : RendererView
paneTopRight =
    { paneRight | heightPercent = 50.0 }


paneBottomRight : RendererView
paneBottomRight =
    { paneTopRight | topPercent = 50.0 }


windowSinglePane : RendererWindow
windowSinglePane =
    { defaultViewContainer | views = [ paneFull ] }


windowCupboards : RendererWindow
windowCupboards =
    { defaultViewContainer | views = [ paneLeft, paneRight ] }


windowDrawers : RendererWindow
windowDrawers =
    { defaultViewContainer | views = [ paneTop, paneBottom ] }


windowGrid : RendererWindow
windowGrid =
    { defaultViewContainer | views = [ paneTopLeft, paneTopRight, paneBottomLeft, paneBottomRight ] }


windowOneUpTwoDown : RendererWindow
windowOneUpTwoDown =
    { defaultViewContainer | views = [ paneTop, paneBottomLeft, paneBottomRight ] }


renderTypeNameAssoc : List ( RendererType, String )
renderTypeNameAssoc =
    --Yes, this is crucial Electron-level config here.
    [ ( RendererToolbox, "Toolbox" )
    , ( Renderer3D, "ThirdPerson" )
    , ( RendererProfile, "Profile" )
    , ( RendererCanvasChart, "Chart" )
    , ( RendererMap, "Map" )
    , ( RendererMultiPane, "ViewContainer" )
    ]


rendererTypeToString : RendererType -> String
rendererTypeToString rendererType =
    case List.Extra.find (\( a, _ ) -> a == rendererType) renderTypeNameAssoc of
        Just ( _, value ) ->
            value

        Nothing ->
            "unknown renderer"


rendererStringToType : String -> RendererType
rendererStringToType rendererName =
    --TODO: Have a error renderer as default.
    List.Extra.find (\( _, b ) -> b == rendererName) renderTypeNameAssoc
        |> Maybe.map Tuple.first
        |> Maybe.withDefault RendererToolbox


windowAsJson : RendererWindow -> E.Value
windowAsJson window =
    E.object
        [ ( "html", E.string <| rendererTypeToString window.containerRenderer )
        , ( "width", E.int window.width )
        , ( "height", E.int window.height )
        , ( "x", E.int window.left )
        , ( "y", E.int window.top )
        , ( "views", E.list viewAsJson window.views )
        , ( "leftToolbox", E.bool window.leftToolboxVisible )
        , ( "rightToolbox", E.bool window.rightToolboxVisible )
        ]


windowDecoder =
    D.map8 RendererWindow
        (D.map rendererStringToType <| D.field "html" D.string)
        (D.field "width" D.int)
        (D.field "height" D.int)
        (D.field "x" D.int)
        (D.field "y" D.int)
        (D.field "views" (D.list viewDecoder))
        (D.field "leftToolbox" D.bool)
        (D.field "rightToolbox" D.bool)


viewAsJson : RendererView -> E.Value
viewAsJson view =
    E.object
        [ ( "html", E.string <| rendererTypeToString view.rendererType )
        , ( "width", E.float view.widthPercent )
        , ( "height", E.float view.heightPercent )
        , ( "x", E.float view.topPercent )
        , ( "y", E.float view.leftPercent )
        ]


newViewCmdAsJson : NewViewCmd -> E.Value
newViewCmdAsJson view =
    E.object
        [ ( "html", E.string <| rendererTypeToString view.rendererType )
        , ( "width", E.int view.width )
        , ( "height", E.int view.height )
        , ( "x", E.int view.left )
        , ( "y", E.int view.top )
        ]


viewDecoder =
    D.map5 RendererView
        (D.map rendererStringToType <| D.field "html" D.string)
        (D.field "width" D.float)
        (D.field "height" D.float)
        (D.field "x" D.float)
        (D.field "y" D.float)


newCmdDecoder =
    D.map5 NewViewCmd
        -- Electron main will use this to create a new view.
        (D.map rendererStringToType <| D.field "html" D.string)
        (D.field "width" D.int)
        (D.field "height" D.int)
        (D.field "x" D.int)
        (D.field "y" D.int)


moveCmdDecoder =
    D.map5 MoveViewCmd
        -- Electron main will use this to reposition an existing view
        (D.field "view" D.int)
        (D.field "width" D.int)
        (D.field "height" D.int)
        (D.field "x" D.int)
        (D.field "y" D.int)


switchCmdDecoder =
    D.map2 SwitchViewCmd
        -- Electron main will use this to change renderer for an existing view
        (D.field "view" D.int)
        (D.map rendererStringToType <| D.field "html" D.string)


layoutStyleNameAssoc : List ( LayoutStyle, String )
layoutStyleNameAssoc =
    [ ( LayoutSingle, "LayoutSingle" )
    , ( LayoutDrawers, "LayoutDrawers" )
    , ( LayoutCupboards, "LayoutCupboards" )
    , ( LayoutGrid, "LayoutGrid" )
    , ( LayoutDresser, "LayoutDresser" )
    ]


layoutStyleToString : LayoutStyle -> String
layoutStyleToString style =
    case List.Extra.find (\( a, _ ) -> a == style) layoutStyleNameAssoc of
        Just ( _, value ) ->
            value

        Nothing ->
            "unknown renderer"
