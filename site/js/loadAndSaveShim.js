// We will have one of these for each renderer.
// It glues the Elm app to JS and tells Elm where to render its HTML.

const app = Elm.Main.init({
    node: document.getElementById("myapp")
});
