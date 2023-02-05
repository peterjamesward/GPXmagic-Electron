module GpxPoint exposing (..)

import Json.Decode as D
import Json.Encode as E
import Time


type alias GpxPoint =
    -- This is a raw GPX as read by parser and convenient for JSON encoding.
    -- Internally, we use geometric units.
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


gpxDecoder =
    D.map4 GpxPoint
        (D.field "lon" D.float)
        (D.field "lat" D.float)
        (D.field "alt" D.float)
        (D.maybe <|
            D.map Time.millisToPosix <|
                D.field "time" D.int
        )
