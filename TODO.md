
# WIP

## Electron PoC

Create a server "app" in Elm with no view, only messages in and out.
Put the Tree and Indexes here. (Not strictly required for POC.)

Create a file loader Elm app that reads and parses, sends GPX data to server as JSON.
Create a 3D renderer Elm app that receives elided model from server and renders.

Server sends elided model to all renderers. (Maybe renderer specified eilsion when it registers.)
Renderers locally render to WebGL, Canvas, Map as required (specialised).

Traffic is two-way, so Toolbox is also a renderer, sends updates to server, whilst (say) "drag on map" also sends an update.

Not sure where click detect happens; needs to be in server if renderers do not have full model but is that an abstraction leak?
(It may not be if we're communicating in terms of (lon, lat) or 3D "rays". 
But couple of funny cases such as requesting elevatiom from Map, which at least requires that there is one Map. 
I guess server could spawn an invisible worker if needed, or that tool is only enabled if there is a Map loaded (better).)

Anyway, that's the concept. Then tools and views migrate without baggage (no Actions).
More JS than before but we can keep it clean as renderers are specialised.

---

# BACKLOG

## Electron

Need code signing to be entered in Windows store.

Display logged in athlete details from Strava.

Non-deprecated OAuth, I suppose (but secret's in the app today).

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
