import { CyberFlow } from "./scenes/cyber_flow";
import { LucidDream } from "./scenes/lucid_dream";
import { VaporWave } from "./scenes/vaper_wave";

/**
 * Used to render scenes easily in elixir.
 **/
export const AnimeRenderer = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext("2d");

    this.tick = 0;
    this.scenes = {
      "CyberFlow": new CyberFlow(),
      "LucidDream": new LucidDream(),
      "VaporWave": new VaporWave()
    };

    this.currentScene = this.scenes["VaporWave"];

    this.loop = this.loop.bind(this);
    this.frameId = requestAnimationFrame(this.loop);

    this.handleEvent("visual-op", (op) => this.handleOp(op));
  },

  handleOp(op) {
    if (op.type === "switch_scene") {
      // 加一些转场特效逻辑
      // if op.trans  ??
      // 比如闪白屏： this.flashWhite = true;
      if (this.scenes[op.target]) {
        console.log(`[Visual] Switching cortex to: ${op.target}`);
        this.currentScene = this.scenes[op.target];
      }
    } else if (op.type === "special") {
      this.currentScene.handleInput(op.payload);
    }
  },

  loop() {
    const { ctx, canvas } = this;
    const w = canvas.width;
    const h = canvas.height;

    if (this.currentScene) {
      this.currentScene.draw(ctx, w, h, this.tick);
      // if has filter/context append
      // refractoring to here and explicitly invoke
      this.currentScene.update(this.tick);
    }

    this.tick++;

    this.frameId = requestAnimationFrame(this.loop);
  },
};
