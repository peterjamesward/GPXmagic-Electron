module GpxPoint exposing (..)

import Json.Encode as E
import Time


type alias GpxPoint =
    { longitude : Float
    , latitude : Float
    , altitude : Float
    , timestamp : Maybe Time.Posix
    }


gpxPointAsJSON : GpxPoint -> E.Value
gpxPointAsJSON point =
    case point.timestamp of
        Just timestamp ->
            E.object
                [ ( "lon", E.float point.longitude )
                , ( "lat", E.float point.latitude )
                , ( "alt", E.float point.altitude )
                , ( "time", E.int <| Time.posixToMillis timestamp )
                ]

        Nothing ->
            E.object
                [ ( "lon", E.float point.longitude )
                , ( "lat", E.float point.latitude )
                , ( "alt", E.float point.altitude )
                ]
