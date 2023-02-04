module GpxParser exposing
    ( asRegex
    , parseSegments
    , parseTrackName
    )

import ElmEscapeHtml
import GpxPoint exposing (GpxPoint)
import Iso8601
import List.Extra
import Maybe.Extra
import Regex


asRegex t =
    -- Helper to make a regex pattern.
    Maybe.withDefault Regex.never <| Regex.fromString t


parseTrackName xml =
    case Regex.find (asRegex "<trk>[.|\\s]*<name>(.*)<\\/name>") xml of
        [] ->
            Nothing

        x :: _ ->
            case x.submatches of
                [] ->
                    Nothing

                n :: _ ->
                    Maybe.map ElmEscapeHtml.unescape n


parseSegments : String -> ( List GpxPoint, List ( String, Int, Int ) )
parseSegments xml =
    -- Return available segment names with the range of included track point indices.
    let
        trackPoints =
            parseGPXPoints xml

        trackSegmentStarts =
            Regex.find (asRegex "<trkseg>") xml
                |> List.map .index

        namedSegments =
            Regex.find (asRegex "namedSegment>(.*)<\\/.*:namedSegment") xml

        segmentExtent : Regex.Match -> ( String, Int, Int )
        segmentExtent match =
            -- 1. Which segment contains this name?
            -- 2. Which track points does that segment contain?
            -- Controversially returns whole track in should-not-occur condition.
            let
                segmentIndex =
                    List.Extra.findIndex
                        (\segStart -> segStart > match.index)
                        trackSegmentStarts
                        |> Maybe.withDefault (List.length trackSegmentStarts)
                        |> (+) -1

                segmentStartOffset =
                    List.Extra.getAt segmentIndex trackSegmentStarts
                        |> Maybe.withDefault 0

                segmentEndOffset =
                    List.Extra.getAt (1 + segmentIndex) trackSegmentStarts
                        |> Maybe.withDefault (String.length xml - 1)

                firstContainedPoint =
                    -- First track point that appears later in the file than the trkseg.
                    List.Extra.findIndex
                        (\( _, tpOffset ) ->
                            tpOffset > segmentStartOffset
                        )
                        trackPoints
                        |> Maybe.withDefault 0

                lastContainedPoint =
                    -- Last track point preceding the next trkseg.
                    List.Extra.findIndex
                        (\( _, tpOffset ) ->
                            tpOffset > segmentEndOffset
                        )
                        trackPoints
                        |> Maybe.withDefault (List.length trackPoints)
                        |> (+) -1
            in
            ( case match.submatches of
                (Just sub1) :: _ ->
                    ElmEscapeHtml.unescape sub1

                _ ->
                    ""
            , firstContainedPoint
            , lastContainedPoint
            )
    in
    ( List.map Tuple.first trackPoints
    , List.map segmentExtent namedSegments
    )


parseGPXPoints : String -> List ( GpxPoint, Int )
parseGPXPoints xml =
    -- Returning the file offset will allow us to correlate segment names!
    let
        trkpts =
            Regex.find (asRegex "(<trkpt(.|\\s)*?)(trkpt>|\\/>)") xml

        latitude trkpt =
            Regex.find (asRegex "lat=\\\"([\\d\\.-]*)\\\"") trkpt |> matches

        longitude trkpt =
            Regex.find (asRegex "lon=\\\"([\\d\\.-]*)\\\"") trkpt |> matches

        elevation trkpt =
            case
                Regex.find (asRegex "<ele>([\\d\\.-]*)<\\/ele>") trkpt |> matches
            of
                (Just alt) :: _ ->
                    alt

                _ ->
                    0

        timestamp trkpt =
            trkpt
                |> Regex.find (asRegex "<time>(.*)<\\/time>")
                |> List.head
                |> Maybe.map .submatches
                |> Maybe.andThen List.head
                |> Maybe.Extra.join
                |> Maybe.andThen (Iso8601.toTime >> Result.toMaybe)

        earthVector : Regex.Match -> Maybe ( GpxPoint, Int )
        earthVector trkpt =
            -- This just to remove anything with a weird combination of values.
            let
                trkptString =
                    trkpt.match
            in
            case ( latitude trkptString, longitude trkptString ) of
                ( (Just lat) :: _, (Just lon) :: _ ) ->
                    Just <|
                        ( GpxPoint
                            lon
                            lat
                            (elevation trkptString)
                            (timestamp trkptString)
                        , trkpt.index
                        )

                _ ->
                    Nothing

        matches xs =
            List.map value xs

        value x =
            case x.submatches of
                (Just val) :: _ ->
                    String.toFloat val

                _ ->
                    Nothing

        sameLocation ( a, _ ) ( b, _ ) =
            a.latitude == b.latitude && a.longitude == b.longitude
    in
    trkpts
        |> List.filterMap earthVector
        |> deDupe sameLocation


deDupe : (a -> a -> Bool) -> List a -> List a
deDupe areSame inputList =
    -- Simply removing stationary points fixes many problems.
    let
        helper inputs outputs =
            -- Conses non-stationary points on to outputs.
            -- Note that outputs therefore also has last point at its head.
            case ( inputs, outputs ) of
                ( [], _ ) ->
                    outputs

                ( firstInput :: moreInputs, [] ) ->
                    helper moreInputs [ firstInput ]

                ( finalInput :: [], previousOutput :: _ ) ->
                    if areSame finalInput previousOutput then
                        outputs

                    else
                        finalInput :: outputs

                ( someInput :: moreInputs, previousOutput :: _ ) ->
                    if areSame someInput previousOutput then
                        helper moreInputs outputs

                    else
                        helper moreInputs (someInput :: outputs)
    in
    List.reverse <| helper inputList []
