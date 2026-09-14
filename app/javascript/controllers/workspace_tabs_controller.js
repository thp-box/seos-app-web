import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "panel", "navigation"]
  static values = { default: String }
  connect() {
    this.navigationTarget.setAttribute("role", "tablist")
    this.tabTargets.forEach(tab => {
      tab.setAttribute("role", "tab")
      tab.setAttribute("aria-controls", `workspace-${tab.dataset.key}`)
    })
    this.panelTargets.forEach(panel => {
      panel.setAttribute("role", "tabpanel")
      panel.setAttribute("aria-labelledby", `workspace-tab-${panel.dataset.key}`)
    })
    this.restore = () => this.activate(new URL(location.href).searchParams.get("tab") || this.defaultValue)
    window.addEventListener("popstate", this.restore)
    this.restore()
  }
  disconnect() { window.removeEventListener("popstate", this.restore) }
  select(event) {
    const key = event.currentTarget.dataset.key
    this.activate(key)
    const url = new URL(location.href)
    url.searchParams.set("tab", key)
    history.pushState({}, "", url)
    this.tabTargets.find(tab => tab.dataset.key === key)?.focus({ preventScroll: true })
  }
  activate(key) {
    if (!this.tabTargets.some(tab => tab.dataset.key === key)) key = this.tabTargets[0].dataset.key
    this.tabTargets.forEach(tab => {
      const active = tab.dataset.key === key
      tab.setAttribute("aria-selected", String(active))
      tab.tabIndex = active ? 0 : -1
    })
    this.panelTargets.forEach(panel => { panel.hidden = panel.dataset.key !== key })
  }
  keyboard(event) {
    const index = this.tabTargets.indexOf(event.currentTarget)
    let next
    if (event.key === "ArrowRight") next = (index + 1) % this.tabTargets.length
    if (event.key === "ArrowLeft") next = (index - 1 + this.tabTargets.length) % this.tabTargets.length
    if (event.key === "Home") next = 0
    if (event.key === "End") next = this.tabTargets.length - 1
    if (next === undefined) return
    event.preventDefault()
    this.tabTargets[next].click()
  }
}
