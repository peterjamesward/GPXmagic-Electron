
# WIP

## Electron PoC

(DONE) Create a file loader Elm app that reads and parses, sends GPX data to server as JSON.

Note the path from Elm to Main Process is (necessarily) not simple:
1. Elm creates some JSON
2. Elm sends JSON through a port with a "cmd" tag
3. In JS a single routine sits at the port and dispatches on the "cmd" tag
4. Call from there to the GPXmagicAPI exposed in preload.js; this is named functions
5. Then it's messaging again up to main, where the event name should be the "cmd" tag
6. In Main process, there's an ".on" method for each event type
7. This will pass into Elm through a port in the server side
8. Elm will pick up the Sub msg
9. Elm logic in the server
10. Route back is the reverse set of ports and messages.

DONE >> Create a server "app" in Elm with no view, only messages in and out.
>> Put the Tree and Indexes here. (Not strictly required for POC.)
>> Interested to know how big a file we can load or if there's a hidden limitation.
> OK with 1M, failed with 3M (300MB GPX file)!

Create a 3D renderer Elm app that receives `List EarthPoint` from server and renders.
Test with variety of file sizes!

Server sends (elided) model to all renderers. (Maybe renderer specified elision when it registers.)
Renderers locally render to WebGL, Canvas, Map as required (specialised, hence simpler).

Traffic is two-way, so Toolbox is also a renderer, sends updates to server, whilst (say) "drag on map" also sends an update.
(Generally, I suspect tools require access to a PeteTree.)

Not sure where click detect happens; needs to be in server if renderers do not have full model but is that an abstraction leak?
(It may not be if we're communicating in terms of (lon, lat) or 3D "rays". 

Couple of funny cases such as requesting altitudes from Map, which at least requires that there is one Map. 
I guess server could spawn an invisible worker if needed, or that tool is only enabled if there is a Map loaded (better).)

Anyway, that's the concept. Then tools and views migrate without baggage (no Actions).
More JS than before but we can keep it clean as renderers are specialised.

## Questions & challenges

Whether WebViews have their own process and are basically "embedded" pages in all respects.
This could make window management a nice extension of v3, having panes but allowing >1 containers.

Want to avoid re-loading map just because user switches views. Maybe just hide them. Maybe not worry.

How best to implement simple view switch. (Depends on what WebView really is?)

Thinking of keeping window management simple, not using WebView. 
Each BrowserWindow to be only one view but with a consistent set of buttons for user to:
* Switch to a different view (which reloads the window with new content)
* Split vertically or horizontally (which clones the active view)
* Close (also by title bar controls)
Window positions and mode to be kept in localStorage like v3.
Central option somewhere to Tile or Cascade all windows onto primary display.

---

# BACKLOG

## Electron

Need code signing to be entered in Windows store.

Display logged in athlete details from Strava.

Revert to Elm OAuth, run in an invisible browser window. Nice.

## Street View renderer

Use Maps Embed API -- https://developers.google.com/maps/documentation/embed/get-started
(Apparently no charge, no rate limit, so we can have a "follow Orange" renderer.)

## Picture button

Add button to images to allow screen capture. Because easy?
But need to make sure ALL canvases are named; currently only Map and Profiles.

## Create nice road book page with export capability

One view that combines Map with Profile, overlaid with route text that we would need to 
embed in the GPX.

Export pandoc-ready data including PNGs of canvasses.

## Test cases for edits.

You could do this you know, just not for the visuals.

## Languages

Awaiting French support.
Possible sign-ups for German, Dutch, Spanish.
Need more work on number formats.

## Technical debt

Tagged types for Point v Line indices to avoid confusion.

Variant of "request from local storage" that takes a wrapped message so that the return value
can be directed to a tool or a view.

Put all Font, Colour etc into a Palette/Style module for ease of change.

## Land use 3D rendering

Experiment proved the idea (of roads partitioning polygons) but implementation was weak.
Roads should divide polygons, but care needed over directionality and crossing points.
It needs doing properly, including the start and finish cases.

## Usability

Drag Curve Former circle directly in Plan View. (Add an SVG "handle" to hit detect.)
Ditto for Move & Stretch, possibly Nudge.

## Tools: old, updated, & new

- Non-customisable keyboard alternatives for Load/Save/Undo/Redo/Fwd/Back/Purple (maybe 1-5 for views)
- Use localised number formatting everywhere (for French use of , and .)

## Loops

- Centroid average to work over S/F on loop
- Bezier smoothing to work over S/F on loop

 
---
