/**
 * Used to render scenes easily in elixir.
 **/
export const AnimeRenderer = {
  /* 
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
  }, */
  mounted() {
    this.canvas = this.el;
    this.ctx = this.canvas.getContext("2d");

    // === 游戏状态 ===
    this.state = {
      t: 0, // 时间/帧数
      speed: 1, // 推进速度
      glitch: 0, // 故障强度
      objects: [], // 场景物体
      camera: { x: 0, y: 0, z: 0 },
      theme: { r: 0, g: 255, b: 100 }, // 默认黑客绿
    };

    // === 初始化场景 ===
    this.initScene();

    // === 启动循环 ===
    this.loop = this.loop.bind(this);
    this.frameId = requestAnimationFrame(this.loop);

    // === 监听后端 OP 指令 ===
    // 在 LiveView 中调用 push_event(socket, "visual-op", %{type: "boost"})
    this.handleEvent("visual-op", (payload) => this.handleOp(payload));
  },

  updated() {
    // 如果 props 更新了，可以在这里处理
  },

  destroyed() {
    cancelAnimationFrame(this.frameId);
  },

  // === 处理后端指令 ===
  handleOp(op) {
    console.log("Visual Op:", op);
    switch (op.type) {
      case "boost":
        this.state.speed = 5;
        setTimeout(() => (this.state.speed = 1), 500); // 短暂加速
        break;
      case "glitch":
        this.state.glitch = 20; // 强烈的故障效果
        break;
      case "color_shift":
        this.state.theme = { r: 255, g: 0, b: 100 }; // 变色
        break;
      case "spawn":
        this.spawnObject();
        break;
    }
  },

  // === 场景生成 ===
  initScene() {
    // 生成一些伪地形线
    for (let i = 0; i < 50; i++) {
      this.state.objects.push({
        x: (Math.random() - 0.5) * 800,
        y: 100, // 地面高度
        z: Math.random() * 2000,
        w: Math.random() * 50,
      });
    }
  },

  spawnObject() {
    this.state.objects.push({
      x: (Math.random() - 0.5) * 400,
      y: (Math.random() - 0.5) * 400,
      z: 2000, // 远处
      w: 20,
    });
  },

  // === 核心渲染循环 (JS1k Vibe) ===
  loop() {
    const { ctx, canvas, state } = this;
    const w = canvas.width;
    const h = canvas.height;

    state.t += 1;

    // 1. 拖影效果 (不完全清除上一帧，形成残影)
    // 如果故障值高，随机清除颜色
    ctx.fillStyle = `rgba(${state.glitch > 0 ? 50 : 0}, 0, 0, 0.2)`;
    ctx.fillRect(0, 0, w, h);

    // 2. 故障震动
    let shakeX = 0;
    let shakeY = 0;
    if (state.glitch > 0) {
      shakeX = (Math.random() - 0.5) * state.glitch;
      shakeY = (Math.random() - 0.5) * state.glitch;
      state.glitch *= 0.95; // 故障衰减
      if (state.glitch < 0.5) state.glitch = 0;
    }

    ctx.save();
    ctx.translate(w / 2 + shakeX, h / 2 + shakeY); // 原点移到中心

    // 3. 颜色设置
    const color = `rgb(${state.theme.r}, ${state.theme.g}, ${state.theme.b})`;
    ctx.strokeStyle = color;
    ctx.fillStyle = color;
    ctx.lineWidth = 1;

    // 4. 更新与绘制物体 (低面数/线框风格)
    state.objects.forEach((obj) => {
      // 移动 Z 轴
      obj.z -= 5 * state.speed;

      // 循环利用：如果物体跑到相机后面，把它扔回远处
      if (obj.z < 10) {
        obj.z = 2000;
        obj.x = (Math.random() - 0.5) * 1000;
      }

      // === 3D 投影公式 (Perspective Projection) ===
      // scale = fov / (z + camera_z)
      const fov = 200;
      const scale = fov / obj.z;

      const sx = obj.x * scale;
      const sy = obj.y * scale;
      const size = obj.w * scale;

      // 绘制线框 (比如一个简单的倒三角形或矩形)
      ctx.beginPath();
      ctx.moveTo(sx, sy);
      ctx.lineTo(sx - size, sy + size);
      ctx.lineTo(sx + size, sy + size);
      ctx.closePath();

      // 根据距离决定是填充还是描边（产生雾效感）
      if (obj.z < 500) {
        ctx.stroke();
      } else {
        ctx.globalAlpha = 0.5;
        ctx.fillRect(sx - size / 2, sy, size, size / 2);
        ctx.globalAlpha = 1.0;
      }
    });

    // 5. 绘制扫描线 (Scanlines)
    ctx.restore(); // 恢复坐标系

    if (state.t % 2 === 0) {
      ctx.fillStyle = "rgba(0, 0, 0, 0.1)";
      for (let y = 0; y < h; y += 2) {
        ctx.fillRect(0, y, w, 1);
      }
    }

    this.frameId = requestAnimationFrame(this.loop);
  },
};
