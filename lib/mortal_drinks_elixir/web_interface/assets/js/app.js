import "phoenix_html"
// 建立 Phoenix Socket 和 LiveView 的配置。
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
// import {hooks as colocatedHooks} from "phoenix-colocated/mord_ex"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
//   hooks: {...colocatedHooks},
})

liveSocket.connect()

// Used fore debug
window.liveSocket = liveSocket
