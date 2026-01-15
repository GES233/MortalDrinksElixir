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
  rgba(r, g, b, a=1) { return `rgba(${r|0}, ${g|0}, ${b|0}, ${a})`; }
};