// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"
import maplibregl from "maplibre-gl"

let Hooks = {}

Hooks.MapLibre = {
  mounted() {
    const geojsonUrl = this.el.dataset.geojsonUrl
    const boundaryUrl = this.el.dataset.boundaryUrl

    Promise.all([
      fetch(geojsonUrl).then(r => r.json()),
      fetch(boundaryUrl).then(r => r.json())
    ]).then(([geojson, boundary]) => {
      const bounds = new maplibregl.LngLatBounds()
      geojson.features.forEach(f => bounds.extend(f.geometry.coordinates))

      const map = new maplibregl.Map({
        container: this.el,
        style: "https://basemaps.cartocdn.com/gl/positron-gl-style/style.json",
        bounds: bounds,
        fitBoundsOptions: { padding: 40, maxZoom: 14 }
      })

      map.on("load", () => {
        map.addSource("boundary", { type: "geojson", data: boundary })
        map.addLayer({
          id: "boundary-line",
          type: "line",
          source: "boundary",
          paint: {
            "line-color": "#333",
            "line-width": 2,
            "line-opacity": 0.5
          }
        })

        map.addSource("properties", { type: "geojson", data: geojson })
        map.addLayer({
          id: "properties-circle",
          type: "circle",
          source: "properties",
          paint: {
            "circle-radius": [
              "interpolate", ["linear"], ["min", ["get", "units"], 50],
              1, 4,
              50, 20
            ],
            "circle-color": "#ee4100",
            "circle-stroke-width": 1,
            "circle-opacity": 0.7,
            "circle-stroke-color": "#fff"
          }
        })

        const popup = new maplibregl.Popup({ closeButton: false, closeOnClick: false })

        map.on("mouseenter", "properties-circle", (e) => {
          map.getCanvas().style.cursor = "pointer"
          const props = e.features[0].properties
          popup.setLngLat(e.features[0].geometry.coordinates)
            .setHTML(`<strong>${props.address}</strong><br>${props.units} unit(s)`)
            .addTo(map)
        })

        map.on("mouseleave", "properties-circle", () => {
          map.getCanvas().style.cursor = ""
          popup.remove()
        })

      })
    })
  }
}

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}, hooks: Hooks})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

