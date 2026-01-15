import { DreamMath } from "../math_core.js"

// TODO
// Make it more `vaporwave`
export class CyberFlow {
  constructor() {
    this.objects = [];
    this.speed = 1;
    for(let i=0; i<45; i++){this.spawnBlock()};
  }

  spawnBlock() {
    this.objects.push({
      x: (Math.random() - 0.5) * 800,
      y: 100, // 地面
      z: 500 + Math.random() * 2000,
      size: 10 + Math.random() * 30,
      active: true
    });
  }

  update() {
    this.objects.forEach(obj => {
      obj.z -= (5 * this.speed);
      if (obj.z < -10) { // 飞过相机，重置到远处
        obj.z = 2000;
        obj.x = (Math.random() - 0.5) * 800;
      }
    });
  }

  draw(ctx, width, height, tick) {
    // 1. Clear screen
    ctx.fillStyle = this.clearScreen(ctx, width, height);

    // 2. 绘制地平线网格
    ctx.strokeStyle = "#00FF41"; // Matrix Green
    ctx.lineWidth = 1;

    // 3. 绘制物体
    this.objects.forEach(obj => {
      // 简单投影
      const p = DreamMath.project3D(obj.x, obj.y, obj.z, width, height);
      if (!p.visible) return;

      const s = obj.size * p.scale;

      ctx.beginPath();
      ctx.moveTo(p.x, p.y - s); // 顶
      ctx.lineTo(p.x - s, p.y + s); // 左底
      ctx.lineTo(p.x + s, p.y + s); // 右底
      ctx.closePath();
      ctx.stroke();

      if (obj.z >= 500) {
        // ctx.globalAlpha = 0.5;
        ctx.fillRect(p.x - s / 2, p.y, s, s / 2);
        // ctx.globalAlpha = 1.0;
      }
    });

    ctx.restore(); // 恢复坐标系

    if (this.t % 2 === 0) {
      ctx.fillStyle = "rgba(0, 0, 0, 0.1)";
      for (let y = 0; y < h; y += 2) {
        ctx.fillRect(0, y, w, 1);
      }
    }

    // 4. UI 装饰文字
    if (tick % 60 < 30) {
      ctx.fillStyle = "#00FF41";
      ctx.font = "10px monospace";
      ctx.fillText("SYS.KERNEL_PANIC // MONITORING", 10, 20);
    }
  }

  clearScreen(ctx, width, height) {
    const oldColor = ctx.fillStyle;

    ctx.fillStyle = "rgba(0, 5, 0, 0.3)";
    ctx.fillRect(0, 0, width, height);

    oldColor;
  }

  handleInput(_opPayload) {
    // ...
  }
}