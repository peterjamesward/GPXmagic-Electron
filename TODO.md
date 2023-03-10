
# PARKED

Yes, I'm shelving this for now. It looks promising but there's far too much effort going into window shuffling and I don't see much benefit for the users. Maybe there's an easier way of spinning up a second (slave) window. I'm going back to properly packaging v3.10 and then rethink.

## Electron PoC

Couple of funny cases such as requesting altitudes from Map, which at least requires that there is one Map. 
I guess server could spawn an invisible worker if needed, or that tool is only enabled if there is a Map loaded (better).)

Route maker will be odd, as always. At least this keeps the complexity in one process.

## Next

* Send sizes to each pane when window size changes
* Hide-able toolboxes (left, right) replace split panes.
* Change layout with more views.
* Change layout with fewer views (saving the renderer)
* Switch renderer.
* Layout tool to provide drag and drop or likewise to rearrange panes within container, saved named layout.
* Window locations and panes stored.
* Window locations and panes restored.
* Error handling - always display a meaningful message when possible.
* Graceful failure on large tracks (exception handling?)
* Main slider to be distance, not points
* Zoom, pan 3D view.
* Click detect (indexes in main process).
* Display Options at WebWindow/WebView level, with defaults for new views.
* Pointer-only update notification (mainly for map which always has full track)
* Canvas charts (add distance to the broadcast points)
* Map.
* WebGL & SVG chart.
* Change window type (swap with same-place window, ideally without flicker).
* Segments.
* Google Street View (with follow Orange).
* Migrate all Tools, with good code hygiene.
* Tool show/hide by toolbox, stored and restored.
* Menu bar to reset tools, change language, metric/imperial, follow system dark/light.
* File Open, Save As on menu
* Canvas snapshot buttons
* electron-builder or electron-forge for installers.
* If all the preload scripts and ipcStubs are the same, make it the one.

NB: The 3D views differ only in camera placement, so I see that being nicer.

## Questions & challenges

Want to avoid re-loading map just because user switches views. Maybe just hide them. Maybe not worry.

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
