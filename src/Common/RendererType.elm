module Common.RendererType exposing (..)

import Json.Decode as D


type RendererType
    = RendererToolbox
    | RendererMultiPane
    | Renderer3D
    | RendererProfile
    | RendererCanvasChart
    | RendererMap


rendererTypeAsString : RendererType -> String
rendererTypeAsString renderer =
    case renderer of
        RendererToolbox ->
            "toolbox"

        Renderer3D ->
            "WebGL"

        RendererProfile ->
            -- Classic WebGL & SVG profile
            "profile"

        RendererCanvasChart ->
            -- New style profile
            "canvas"

        RendererMap ->
            "map"

        RendererMultiPane ->
            "panes"


rendererTypeFromString : String -> Maybe RendererType
rendererTypeFromString name =
    case name of
        "toolbox" ->
            Just RendererToolbox

        "WebGL" ->
            Just Renderer3D

        -- Classic WebGL & SVG profile
        "profile" ->
            Just RendererProfile

        -- New style profile
        "canvas" ->
            Just RendererCanvasChart

        "map" ->
            Just RendererMap

        "panes" ->
            Just RendererMultiPane

        _ ->
            Nothing
