import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "status"]

  async copy() {
    try {
      await navigator.clipboard.writeText(this.inputTarget.value)
      this.statusTarget.textContent = "Lien copié ! Vous pouvez le partager."
    } catch {
      this.inputTarget.focus()
      this.inputTarget.select()
      this.statusTarget.textContent = "Lien sélectionné. Utilisez Copier dans le menu de votre appareil, ou Ctrl+C."
    }
  }
}
