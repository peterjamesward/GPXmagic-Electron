# GPXmagic V4

GPXmagic version 4

Version 4 has two themes:

1. Explore the potential for restructuring using Electron.
2. Possible removal of the Actions approach, going back to JFDI.

Let's break these down somewhat.

## Electron

1. Obviously, it's for native apps; no longer a web deployment.
2. Multiple windows, work on multiple monitors.
3. There is still a 4GB memory limit on renderers, but...
4. We could have specialised renderers (Map, 3D, Chart, Route, Plan),
6. Pass elided model down to each renderer (renderer chooses level of detail),
7. If (at worst) each renderer has full model, can just pass deltas (like Redo).

## Code clean-up

The Actions approach worked quite well, but it's equally clear that it's probably unnecessarily complicated.

It mainly came about to solve the problem of mutual tool interaction and import cycles.
I have somewhat more experience now dealing with that challenge.

* Generally, tools should focus on updating their part of the model.
* Instructions for Map and Chart updates can be derived by comparing old and new Track.
* All error cases and timeouts should be handled with appropriate internal states.
* Having separate renderers possibly makes this all more important and easier.


