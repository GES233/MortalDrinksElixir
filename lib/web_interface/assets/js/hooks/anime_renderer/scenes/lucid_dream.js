import { DreamMath } from "../math_core.js";

export class LucidDream {
  constructor() {
    this.particles = [];
    for (let i = 0; i < 30; i++) {
      this.particles.push({
        x: (Math.random() - 0.5) * 400,
        y: (Math.random() - 0.5) * 400,
        z: Math.random() * 500,
        angle: Math.random() * Math.PI,
        color: Math.random() > 0.5 ? [255, 180, 200] : [255, 220, 150],
      });
    }
  }

  update(tick) {
    this.particles.forEach((p) => {
      p.z -= 0.5;
      p.y += Math.sin(tick * 0.02 + p.x) * 0.5;
      p.angle += 0.01;

      if (p.z < -100) p.z = 500;
    });
  }

  draw(ctx, width, height, tick) {
    ctx.fillStyle = "rgba(20, 10, 30, 0.2)";
    ctx.fillRect(0, 0, width, height);

    // 2. 开启 Canvas 滤镜实现模糊 (低分辨率下性能消耗可控)
    // 注意：部分浏览器可能要加 webkit 前缀，或者手动用贴图实现
    // 这里为了简便直接画圆

    ctx.globalCompositeOperation = "lighter"; // 叠加模式，让光变亮

    this.particles.forEach((p) => {
      const proj = DreamMath.project3D(p.x, p.y, p.z, width, height);
      if (!proj.visible) return;

      const size = 20 * proj.scale;
      const alpha = Math.min(1, proj.scale); // 越近越亮

      // 绘制柔光球 (Gradient)
      const grad = ctx.createRadialGradient(
        proj.x,
        proj.y,
        0,
        proj.x,
        proj.y,
        size
      );
      const [r, g, b] = p.color;
      grad.addColorStop(0, `rgba(${r}, ${g}, ${b}, ${alpha})`);
      grad.addColorStop(1, `rgba(${r}, ${g}, ${b}, 0)`);

      ctx.fillStyle = grad;
      ctx.beginPath();
      ctx.arc(proj.x, proj.y, size, 0, Math.PI * 2);
      ctx.fill();
    });

    ctx.globalCompositeOperation = "source-over"; // 恢复默认

    // 绘制一句漂浮的歌词或思绪
    ctx.fillStyle = "rgba(255, 255, 255, 0.5)";
    ctx.textAlign = "center";
    ctx.fillText("searching for warmth...", width / 2, height - 20);
  }
}
