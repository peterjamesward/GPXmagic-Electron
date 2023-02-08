module Common.RendererType exposing (..)

import List.Extra


type RendererType
    = RendererToolbox
    | RendererMultiPane
    | Renderer3D
    | RendererProfile
    | RendererCanvasChart
    | RendererMap
    | RendererFirstPerson


rendererAssocList : List ( RendererType, String )
rendererAssocList =
    [ ( RendererToolbox, "Toolbox" )
    , ( Renderer3D, "ThirdPerson" )
    , ( RendererProfile, "Profile" )
    , ( RendererCanvasChart, "Chart" )
    , ( RendererMap, "Map" )
    , ( RendererMultiPane, "ViewContainer" )
    , ( RendererFirstPerson, "FirstPerson" )
    ]


rendererTypeAsString : RendererType -> String
rendererTypeAsString renderer =
    case List.Extra.find (\( a, _ ) -> a == renderer) rendererAssocList of
        Just ( a, b ) ->
            b

        Nothing ->
            "unknown renderer"


rendererTypeFromString : String -> Maybe RendererType
rendererTypeFromString name =
    rendererAssocList
        |> List.Extra.find (\( _, b ) -> b == name)
        |> Maybe.map Tuple.first
