module Common.Layouts exposing (..)

import Common.RendererType exposing (RendererType(..))
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


emptyWindow : RendererWindow
emptyWindow =
    -- v3 compatible with toolbox on right.
    { containerRenderer = RendererMultiPane
    , width = 1000
    , height = 750
    , top = 120 + 28 --TODO: Get the actual title bar height and screen size.
    , left = 0
    , views = []
    , leftToolboxVisible = False
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
    { emptyWindow | views = [ paneFull ] }


windowCupboards : RendererWindow
windowCupboards =
    { emptyWindow | views = [ paneLeft, paneRight ] }


windowDrawers : RendererWindow
windowDrawers =
    { emptyWindow | views = [ paneTop, paneBottom ] }


windowGrid : RendererWindow
windowGrid =
    { emptyWindow | views = [ paneTopLeft, paneTopRight, paneBottomLeft, paneBottomRight ] }


windowOneUpTwoDown : RendererWindow
windowOneUpTwoDown =
    { emptyWindow | views = [ paneTop, paneBottomLeft, paneBottomRight ] }


renderTypeNameAssoc : List ( RendererType, String )
renderTypeNameAssoc =
    --Yes, this is crucial Electron-level config here.
    [ ( RendererToolbox, "LoadButton" )
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


viewAsJson : RendererView -> E.Value
viewAsJson view =
    E.object
        [ ( "html", E.string <| rendererTypeToString view.rendererType )
        , ( "width", E.float view.widthPercent )
        , ( "height", E.float view.heightPercent )
        , ( "x", E.float view.topPercent )
        , ( "y", E.float view.leftPercent )
        ]


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
