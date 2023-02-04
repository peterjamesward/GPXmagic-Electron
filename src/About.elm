module About exposing (aboutText)


aboutText =
    """
# GPXmagic App v4 pre-release

## 4

This is an installable application using the cross-platform Electron toolset.

For now, it's basically the same as the web version but the Strava login is moved to the Strava tool
(and logging in won't lose a loaded route).

## Acknowledgements

* Thanks to all those who've provided support, comments, bug reports, and help along the way.

* Thanks to RGT for the Magic Roads concept and an excellent indoor cycling platform.

## Legal guff

Compatible with Strava, for the purpose of loading route and segment data.

GPXmagicV4 is open source at https://github.com/boxingpepperjumpy/GPXmagicV4

Contains numerous libraries under various licence terms, all of which are available in source
form via https://package.elm-lang.org.

Map component provided by MapBox.com.

Land use data courtesy of Open Street Map via the Overpass API.

Icons from www.flaticon.com/free-icons/.

    """
