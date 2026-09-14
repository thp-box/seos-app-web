import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["controls", "button"]
  connect() { this.controlsTargets.forEach(control => { control.hidden = false }); this.apply("grid") }
  change(event) { this.apply(event.currentTarget.dataset.mode) }
  apply(mode) {
    this.element.dataset.display = mode
    this.buttonTargets.forEach(button => button.setAttribute("aria-pressed", String(button.dataset.mode === mode)))
  }
}
