/**
 * Used to render scenes easily in elixir.
**/
export const AnimeRenderer = {
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext("2d");

    // Register views exist dynamically

    // TODO:
    // Solve Oprator and Options

    // Register Phoenix LiveView Linster

    this.loop = this.loop.bind(this);
    this.frameId = requestAnimationFrame(this.loop);
  },

  loop() {
    const { ctx, canvas } = this;
    const w = canvas.width;
    const h = canvas.height;

    // Invoke current worker/renderer

    this.frameId = requestAnimationFrame(this.loop);
  },
};
