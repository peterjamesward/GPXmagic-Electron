module Common.Layouts exposing (..)

import Common.RendererType exposing (RendererType(..))
import Json.Encode as E


type alias RendererWindow =
    -- Windows are positioned absolutely.
    { containerRenderer : RendererType
    , width : Int
    , height : Int
    , top : Int
    , left : Int
    , views : List RendererView
    , reservedLeft : Int
    , reservedTop : Int
    }


type alias RendererView =
    -- Views are positioned relative to their containing window.
    { rendererType : RendererType
    , widthPercent : Float
    , heightPercent : Float
    , topPercent : Float
    , leftPercent : Float
    }


toolWindow : RendererWindow
toolWindow =
    { containerRenderer = RendererToolbox
    , width = 300
    , height = 120
    , top = 0
    , left = 300
    , views = []
    , reservedLeft = 0
    , reservedTop = 0
    }


emptyWindow : RendererWindow
emptyWindow =
    { containerRenderer = RendererMultiPane
    , width = 1000
    , height = 750
    , top = 120 + 28 --TODO: Get the actual title bar height and screen size.
    , left = 0
    , views = []
    , reservedLeft = 35
    , reservedTop = 0
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


rendererHtmlFile : RendererType -> String
rendererHtmlFile rendererType =
    --Yes, this is crucial Electron-level config here.
    --TODO: Add each type carefully.
    case rendererType of
        RendererToolbox ->
            "LoadButton"

        Renderer3D ->
            "WebGL"

        RendererProfile ->
            "WebGL"

        RendererCanvasChart ->
            "WebGL"

        RendererMap ->
            "WebGL"

        RendererMultiPane ->
            "ViewContainer"


windowAsJson : RendererWindow -> E.Value
windowAsJson window =
    E.object
        [ ( "html", E.string <| rendererHtmlFile window.containerRenderer )
        , ( "width", E.int window.width )
        , ( "height", E.int window.height )
        , ( "left", E.int window.left )
        , ( "top", E.int window.top )
        , ( "views", E.list viewAsJson window.views )
        , ( "reservedLeft", E.int window.reservedLeft )
        , ( "reservedTop", E.int window.reservedTop )
        ]


viewAsJson : RendererView -> E.Value
viewAsJson view =
    E.object
        [ ( "html", E.string <| rendererHtmlFile view.rendererType )
        , ( "width", E.float view.widthPercent )
        , ( "height", E.float view.heightPercent )
        , ( "top", E.float view.topPercent )
        , ( "left", E.float view.leftPercent )
        ]
