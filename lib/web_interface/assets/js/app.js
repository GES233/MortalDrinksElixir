import "phoenix_html"
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import { hooks as colocatedHooks } from "phoenix-colocated/mord_ex"

/**
 * @type {import("phoenix_live_view").Hook}
 */
let extraHooks = {}
// Add custome hooks that doesn't easy to load via colocatedHooks
import { AnimeRenderer } from "../js/hooks/anime_renderer/index"
extraHooks.AnimeRenderer = AnimeRenderer

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...colocatedHooks, ...extraHooks},
})

liveSocket.connect()

// Used fore debug
window.liveSocket = liveSocket
