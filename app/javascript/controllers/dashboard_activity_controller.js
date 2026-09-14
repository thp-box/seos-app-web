import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["slider", "summary", "marker", "control"]
  static values = { points: Array }

  connect() {
    this.controlTarget.hidden = false
    this.show(this.pointsValue.length - 1)
  }

  select() { this.show(Number(this.sliderTarget.value)) }

  point(event) {
    const bounds = event.currentTarget.getBoundingClientRect()
    const x = (event.clientX - bounds.left) / bounds.width * 760
    this.show(Math.round((x - 48) / 696 * (this.pointsValue.length - 1)))
  }

  show(index) {
    index = Math.max(0, Math.min(this.pointsValue.length - 1, index))
    if (this.currentIndex === index) return
    this.currentIndex = index
    const row = this.pointsValue[index]
    if (!row) return
    const date = new Intl.DateTimeFormat("fr-FR", { dateStyle: "long", timeZone: "Europe/Paris" }).format(new Date(row.date + "T12:00:00Z"))
    this.summaryTarget.textContent = `${date} · ${row.registrations} inscriptions · ${row.publications} premières publications`
    this.sliderTarget.value = index
    this.sliderTarget.setAttribute("aria-valuetext", date)
    const x = 48 + index * 696 / (this.pointsValue.length - 1)
    this.markerTarget.setAttribute("x1", x)
    this.markerTarget.setAttribute("x2", x)
  }
}
