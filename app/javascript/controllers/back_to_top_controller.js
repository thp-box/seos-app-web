import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.update = () => { this.element.hidden = window.scrollY < 400 }
    window.addEventListener("scroll", this.update, { passive: true })
    this.update()
  }
  disconnect() { window.removeEventListener("scroll", this.update) }
  scroll() {
    document.querySelector("#main-content")?.focus({ preventScroll: true })
    window.scrollTo({ top: 0, behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth" })
  }
}
