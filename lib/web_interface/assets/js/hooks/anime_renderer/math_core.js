export const DreamMath = {
  // 3D 投影：将 x,y,z 转换为屏幕上的 x,y, scale
  project3D(x, y, z, width, height, cameraZ = -100, fov = 200) {
    // 简单的透视除法
    const scale = fov / (fov + z + cameraZ); 
    const x2d = (x * scale) + (width / 2);
    const y2d = (y * scale) + (height / 2);
    return { x: x2d, y: y2d, scale: scale, visible: scale > 0 };
  },

  // 旋转矩阵
  rotate(v, r) {
    // 简化版：只做 X 和 Y 轴旋转，Z轴用的少
    const cosX = Math.cos(r.x), sinX = Math.sin(r.x);
    const cosY = Math.cos(r.y), sinY = Math.sin(r.y);

    let y = v.y * cosX - v.z * sinX;
    let z = v.y * sinX + v.z * cosX;
    let x = v.x * cosY - z * sinY;
    z = v.x * sinY + z * cosY;

    return { x, y, z };
  },

  // 颜色生成
  rgba(r, g, b, a=1) { return `rgba(${r|0}, ${g|0}, ${b|0}, ${a})`; },

  drawPerspectiveGrid(ctx, width, height, tick, color) {
    const horizon = height / 2;
    const speed = (tick * 2) % 40; // 移动速度
    
    ctx.strokeStyle = color;
    ctx.lineWidth = 1;
    ctx.beginPath();

    // 纵向线 (汇聚到一点)
    for (let i = -1000; i < 1000; i += 100) {
      // 这里的逻辑是简化的，实际应该是从灭点放射出来
      // 简单模拟：底部的线宽一些，上面的窄汇聚
      ctx.moveTo(width/2 + i * 4, height); 
      ctx.lineTo(width/2 + i * 0.1, horizon);
    }
    
    // 横向线 (随时间下移)
    for (let i = 0; i < 300; i+= 20) {
      let z = i + speed; // 模拟前进
      // 越远越密：简单的透视模拟 y = horizon + (C / z)
      // 这里直接用指数或倒数模拟
      let y = height - (20000 / (z + 100)); 
      if (y < horizon) continue;
      
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
    }
    ctx.stroke();
  }
};