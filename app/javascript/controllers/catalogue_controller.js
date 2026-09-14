import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["city", "locality", "radius", "radiusLabel", "points", "pointsLabel"]
  connect() { this.localityTarget.disabled = false }
  syncCity() { this.localityTarget.value = this.cityTarget.value }
  syncLocality() { this.cityTarget.value = this.localityTarget.value }
  range() {
    this.radiusLabelTarget.textContent = Number(this.radiusTarget.value) ? `${this.radiusTarget.value} km` : "Commune uniquement"
    this.pointsLabelTarget.textContent = Number(this.pointsTarget.value) < 200 ? `${this.pointsTarget.value} PS` : "Sans plafond"
  }
  sort(event) { event.target.form.requestSubmit() }
}
