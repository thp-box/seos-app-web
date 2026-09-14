import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel"]
  connect() {
    this.restore = () => {
      const url = new URL(location.href)
      const key = url.hash.replace("#legal-", "") || url.searchParams.get("onglet")
      const panel = this.panelTargets.find(panel => panel.dataset.tab === key)
      if (panel) panel.scrollIntoView({ block: "start" })
      this.highlight()
    }
    this.highlight = () => {
      cancelAnimationFrame(this.frame)
      this.frame = requestAnimationFrame(() => {
        const current = [...this.panelTargets].reverse().find(panel => panel.getBoundingClientRect().top <= 180) || this.panelTargets[0]
        this.tabTargets.forEach(tab => {
          if (tab.dataset.tab === current?.dataset.tab) tab.setAttribute("aria-current", "location")
          else tab.removeAttribute("aria-current")
        })
      })
    }
    window.addEventListener("scroll", this.highlight, { passive: true })
    window.addEventListener("popstate", this.restore)
    window.addEventListener("hashchange", this.restore)
    this.restore()
  }
  disconnect() {
    cancelAnimationFrame(this.frame)
    window.removeEventListener("scroll", this.highlight)
    window.removeEventListener("popstate", this.restore)
    window.removeEventListener("hashchange", this.restore)
  }
  open(event) {
    if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button > 0) return
    event.preventDefault()
    const panel = this.panelTargets.find(panel => panel.dataset.tab === event.currentTarget.dataset.tab)
    const url = new URL(location.href)
    url.searchParams.delete("onglet")
    url.hash = panel.id
    history.pushState({}, "", url)
    panel.scrollIntoView({ block: "start", behavior: matchMedia("(prefers-reduced-motion: reduce)").matches ? "instant" : "smooth" })
    panel.focus({ preventScroll: true })
  }
}
