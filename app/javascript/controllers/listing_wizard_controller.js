import { Controller } from "@hotwired/stimulus"
export default class extends Controller {
  static targets = ["points", "files"]
  connect() { this.exchange() }
  exchange() {
    if (!this.hasPointsTarget) return
    const selected = this.element.querySelector('input[name="listing[exchange_mode]"]:checked')?.value === "points"
    this.pointsTarget.hidden = !selected
    this.pointsTarget.querySelector("input").required = selected
  }
  photos(event) {
    this.filesTarget.textContent = Array.from(event.target.files).map(file => file.name).join(" · ")
  }
}
