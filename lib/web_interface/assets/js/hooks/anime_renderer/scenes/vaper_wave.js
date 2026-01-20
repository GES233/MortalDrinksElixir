import { DreamMath } from "../math_core.js"

export class VaporWave {
  constructor() {
    this.grid = [];
    this.time = 0;
    this.sunLoc = {
      // It retured `udefined`
      x: (width) => {return width / 2},
      y: (height) => {return height / 2 + 8}
    };
  }

  update(tick) {
    this.time = tick * 0.01;
  }

  draw(ctx, width, height, tick) {
    // 背景渐变 - 蒸汽波标志性的紫粉蓝色调
    const bgGrad = this.drawBackground(ctx, width, height);

    // 绘制太阳/月亮
    this.drawSun(ctx, this.sunLoc.x(width), this.sunLoc.y(height), bgGrad);

    // 一个网格
    this.drawWorldGrid(ctx, height, width, tick);

    // 绘制网格效果
    this.drawGrid(ctx, width, height);

    // 绘制扫描线效果
    this.drawScanlines(ctx, width, height);

    this.drawText(ctx, "MEMORY", width / 2, height - 30);
  }

  drawBackground(ctx, width, height) {
    const bgGrad = ctx.createLinearGradient(0, 0, 0, height);
    bgGrad.addColorStop(0, "#0a0e27");
    bgGrad.addColorStop(0.5, "#1a0a3e");
    bgGrad.addColorStop(1, "#2d1b4e");

    ctx.fillStyle = bgGrad;
    ctx.fillRect(0, 0, width, height);

    return bgGrad;
  }

  drawSun(ctx, sunX, sunY, bgGrad) {
    const sunSize = 65;

    // 太阳光晕
    const haloGrad = ctx.createRadialGradient(sunX, sunY, 0, sunX, sunY, 80);
    haloGrad.addColorStop(0, "hsla(40, 100%, 60%, 0.4)");
    haloGrad.addColorStop(1, "hsla(280, 100%, 50%, 0)");
    ctx.fillStyle = haloGrad;
    ctx.fillRect(sunX - 80, sunY - 80, 160, 160);

    // 太阳主体
    const sunGrad = ctx.createLinearGradient(sunX, sunY - sunSize, sunX, sunY + sunSize);
    sunGrad.addColorStop(0, "#ffd700"); // 黄
    sunGrad.addColorStop(0.5, "#ff007f"); // 粉红
    sunGrad.addColorStop(1, "#800080"); // 紫
    ctx.fillStyle = sunGrad;
    ctx.beginPath();
    ctx.arc(sunX, sunY, sunSize, 0, Math.PI * 2);
    ctx.fill();

    ctx.fillStyle = bgGrad;
    for (let y = sunY - 20; y < sunY + sunSize; y += 8) {
      // 越往下条纹越粗
      let h = (y - (sunY - 20)) / 10; 
      if (h < 1) h = 1;
      ctx.fillRect(sunX - sunSize, y, sunSize * 2, h);
    }
    ctx.restore();
  }

  drawWorldGrid(ctx, height, width, tick) {
    ctx.save();
    ctx.beginPath();
    ctx.rect(0, height / 2, width, height / 2);
    ctx.clip(); // 只在下半部分画网格
    DreamMath.drawPerspectiveGrid(ctx, width, height, tick, "#00f0ff");
    ctx.fillStyle = "rgba(0, 240, 255, 0.1)";
    ctx.fillRect(0, height / 2 + 20, width, height/2);
    ctx.restore();
  }

  drawGrid(ctx, width, height) {
    ctx.strokeStyle = "hsla(280, 80%, 50%, 0.15)";
    ctx.lineWidth = 1;

    const gridSize = 30;
    const offsetX = (this.time * 10) % gridSize;

    // 垂直线
    for (let x = -offsetX; x < width; x += gridSize) {
      ctx.beginPath();
      ctx.moveTo(x, 0);
      ctx.lineTo(x, height);
      ctx.stroke();
    }

    // 水平线
    for (let y = 0; y < height; y += gridSize) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }
  }

  drawScanlines(ctx, width, height) {
    ctx.strokeStyle = "rgba(0, 0, 0, 0.1)";
    ctx.lineWidth = 1;

    for (let y = 0; y < height; y += 2) {
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }
  }

  drawText(ctx, content, locX, locY) {
    ctx.font = "italic 20px serif";
    ctx.fillStyle = "#ff007f";
    ctx.textAlign = "center";
    ctx.fillText(content.split("").join(" "), locX, locY);
  }

  handleInput(payload) {
    // 可以在这里处理输入事件
    console.log("VaporWave input:", payload);
  }
}
