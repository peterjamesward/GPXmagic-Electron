module Renderers.WebGL.SceneBuilder3D exposing (render3dView)

import Color exposing (Color, lightOrange)
import Common.LocalCoords exposing (LocalCoords)
import Length exposing (Meters)
import Pixels
import Point3d exposing (Point3d)
import Scene3d exposing (Entity)
import Scene3d.Material as Material


roadWidth =
    Length.meters 4.0


render3dView : List (Point3d Meters LocalCoords) -> List (Entity LocalCoords)
render3dView points =
    let
        renderPoint =
            Scene3d.point { radius = Pixels.pixels 2 } (Material.color Color.black)
    in
    List.map renderPoint points
