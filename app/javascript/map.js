import L from "leaflet"
import "leaflet/dist/leaflet.css"
import "./stylesheets/components/map.css"

function initializeMaps() {
  document.querySelectorAll("[data-public-map]").forEach(element => {
    if (element.seosMap) return
    element.replaceChildren()
    const reduced = matchMedia("(prefers-reduced-motion: reduce)").matches
    const map = L.map(element, { scrollWheelZoom: false, zoomAnimation: !reduced, fadeAnimation: !reduced, markerZoomAnimation: !reduced }).setView([46.6, 2.5], 5)
    element.seosMap = map
    const template = element.dataset.tiles
    if (template && template.startsWith("https://")) L.tileLayer(template, { maxZoom: 12, attribution: 'Données © <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>' }).addTo(map)
    const markers = JSON.parse(element.dataset.markers)
    markers.forEach(marker => {
      const link = document.createElement("a")
      link.href = marker.url
      link.textContent = marker.title
      L.circleMarker(marker.coordinates, { radius: 9, color: "#004961", fillColor: "#CDAE4F", fillOpacity: 1 }).bindPopup(link).addTo(map)
    })
    if (markers.length) map.fitBounds(markers.map(marker => marker.coordinates), { maxZoom: 10, padding: [30, 30], animate: false })
    if (!template) {
      const note = L.control({ position: "bottomleft" })
      note.onAdd = () => {
        const text = document.createElement("p")
        text.className = "map-notice"
        text.textContent = "Fond de carte indisponible. Retrouvez les communes dans la liste."
        return text
      }
      note.addTo(map)
    }
  })
}
initializeMaps()
document.addEventListener("turbo:load", initializeMaps)
document.addEventListener("turbo:frame-load", initializeMaps)
document.addEventListener("turbo:before-cache", () => document.querySelectorAll("[data-public-map]").forEach(element => { element.seosMap?.remove(); delete element.seosMap }))
