// js/hooks/anime_renderer/scenes/vapor_wave.js
import { DreamMath } from "../math_core.js"

export class VaporWave {
  constructor() {
    this.sunY = 150;
  }

  update(tick) {}

  draw(ctx, width, height, tick) {
    // 1. 背景：深紫渐变
    const bgGrad = ctx.createLinearGradient(0, 0, 0, height);
    bgGrad.addColorStop(0, "#0b0033"); // 深蓝紫
    bgGrad.addColorStop(1, "#2a0033"); // 深紫
    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, width, height);

    const cx = width / 2;
    const cy = height / 2;

    // 2. 复古落日 (Retro Sun)
    const sunSize = 80;
    const sunGrad = ctx.createLinearGradient(cx, cy - sunSize, cx, cy + sunSize);
    sunGrad.addColorStop(0, "#ffd700"); // 黄
    sunGrad.addColorStop(0.5, "#ff007f"); // 粉红
    sunGrad.addColorStop(1, "#800080"); // 紫
    
    ctx.save();
    ctx.fillStyle = sunGrad;
    ctx.beginPath();
    ctx.arc(cx, this.sunY, sunSize, 0, Math.PI * 2);
    ctx.fill();

    // 2.1 切割太阳的横条纹 (百叶窗效果)
    ctx.fillStyle = "#2a0033"; // 和背景底部颜色一致
    for (let y = this.sunY - 20; y < this.sunY + sunSize; y += 8) {
      // 越往下条纹越粗
      let h = (y - (this.sunY - 20)) / 10; 
      if (h < 1) h = 1;
      ctx.fillRect(cx - sunSize, y, sunSize * 2, h);
    }
    ctx.restore();

    // 3. 霓虹网格
    // 强制透视地面
    ctx.save();
    ctx.beginPath();
    ctx.rect(0, cy, width, height / 2);
    ctx.clip(); // 只在下半部分画网格
    
    // 使用 Math Core 里的通用网格绘制
    DreamMath.drawPerspectiveGrid(ctx, width, height, tick, "#00f0ff"); // 青色网格
    
    // 地面发光
    ctx.fillStyle = "rgba(0, 240, 255, 0.1)";
    ctx.fillRect(0, cy, width, height/2);
    ctx.restore();
    
    // 4. 文字
    ctx.font = "italic 20px serif";
    ctx.fillStyle = "#ff007f";
    ctx.textAlign = "center";
    ctx.fillText("M E M O R Y", cx, height - 30);
  }

  handleInput() {}
}