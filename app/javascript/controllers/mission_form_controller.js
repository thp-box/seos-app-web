import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel", "tab", "navigation", "controls", "previous", "next"]
  connect() {
    this.index = 0
    this.navigationTarget.hidden = false
    this.controlsTarget.hidden = false
    this.element.noValidate = true
    this.validate = event => {
      const field = [...this.element.elements].find(field => field.willValidate && !field.validity.valid)
      if (!field) return
      event.preventDefault()
      event.stopImmediatePropagation()
      const index = this.panelTargets.findIndex(panel => panel.contains(field))
      if (index >= 0) this.activate(index)
      field.reportValidity()
    }
    this.element.addEventListener("submit", this.validate, true)
    this.activate(0)
  }
  disconnect() { this.element.removeEventListener("submit", this.validate, true); this.element.noValidate = false }
  activate(index) {
    this.index = index
    this.panelTargets.forEach((panel, i) => { panel.hidden = i !== index })
    this.tabTargets.forEach((tab, i) => {
      if (i === index) tab.setAttribute("aria-current", "step")
      else tab.removeAttribute("aria-current")
    })
    this.previousTarget.disabled = index === 0
    this.nextTarget.hidden = index === this.panelTargets.length - 1
  }
  go(event) { this.activate(Number(event.currentTarget.dataset.step)) }
  next() { if ([...this.panelTargets[this.index].querySelectorAll("input,textarea,select")].every(field => field.reportValidity())) this.activate(this.index + 1) }
  previous() { this.activate(Math.max(0, this.index - 1)) }
}
