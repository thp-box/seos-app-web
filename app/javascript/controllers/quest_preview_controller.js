import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card", "icon", "name", "description"]
  update() {
    const form = this.element.querySelector("form")
    this.nameTarget.textContent = form.elements.name.value || "Votre prochaine quête"
    this.descriptionTarget.textContent = form.elements.description.value || "Expliquez l’objectif en quelques mots."
    this.cardTarget.dataset.accent = form.elements.accent.value
    this.cardTarget.dataset.animated = form.elements.animated.value
    this.iconTargets.forEach(icon => { icon.hidden = icon.dataset.icon !== form.elements.icon.value })
  }
}
