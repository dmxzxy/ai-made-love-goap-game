# 特殊建筑物调试指南

## 问题诊断

您说"根本没有出现过特殊的建筑物"，我已经添加了详细的调试输出来帮助找出问题。

## 已添加的调试信息

### 1. 建筑物创建时
当AI尝试建造特殊建筑时，会输出：
```
★★★ [RED] SPECIAL BUILDING CREATED: Gold Mine at (1234, 567) for $200 - BuildTime: 8.0s, Size: 50 ★★★
    Total special buildings now: 1
```

### 2. 建筑物完成时
当建筑物完成建造后，会输出：
```
★★★ [RED] Gold Mine COMPLETED! Category: RESOURCE, Size: 50, Color: (1.00,0.95,0.10) ★★★
```

### 3. AI决策时
当AI决定建造某种建筑时，会输出：
```
[RED] Attempting to build: GoldMine (Resources: $250, Time: 25.0s, Mode: ECONOMY)
```

### 4. 资源不足时
如果资源不够，会输出：
```
[RED] Not enough resources for Gold Mine! Need $200, have $150
```

## 如何测试

1. **完全重启游戏**
   - 关闭当前运行的游戏
   - 重新运行: `love .`

2. **观察控制台输出**
   - 游戏开始后20秒左右，应该看到AI尝试建造金矿
   - 如果看到"★★★ SPECIAL BUILDING CREATED"消息，说明建筑已创建
   - 等待建造时间（8秒），应该看到"★★★ COMPLETED"消息
   - 如果看到"Not enough resources"，说明资源被用在其他地方了

3. **在游戏中查找建筑**
   - 建筑物会出现在基地周围100-150像素的位置
   - 建造中显示：黑色矩形 + 进度条 + 建筑名称
   - 建造完成后显示：
     * 大尺寸彩色形状（45-50像素）
     * 双边框
     * 类别标签（[RESOURCE]等）
     * 大图标
     * 实时状态显示

## 可能的问题

### 问题1: 建筑从未创建
**症状**: 控制台没有"★★★ SPECIAL BUILDING CREATED"消息
**原因**: 
- AI资源总是不够（被用于生产单位）
- AI模式不对（某些建筑只在特定模式下建造）
- 时间未到（需要游戏开始20秒后）

**解决方案**: 检查控制台的"Not enough resources"或"Attempting to build"消息

### 问题2: 建筑创建但看不见
**症状**: 看到"CREATED"消息但屏幕上没有建筑
**原因**:
- 建筑在屏幕外（摄像机没看到）
- 绘制代码有问题

**解决方案**: 
- 缩小镜头（鼠标滚轮）
- 拖动镜头查看基地周围
- 检查"Total special buildings now"数量

### 问题3: 建筑创建但不完成
**症状**: 看到"CREATED"但没有"COMPLETED"
**原因**: 建筑在建造中被摧毁或代码错误

**解决方案**: 等待足够时间，查看进度条

## 预期行为

正常情况下，游戏开始后30秒内应该看到：

1. **RED队** (经济模式):
   - 尝试建造 Gold Mine
   - 可能建造 Trading Post
   - 可能建造 Resource Depot

2. **BLUE队** (防御模式):
   - 尝试建造 Bunker
   - 尝试建造 Watchtower
   - 可能建造 Medical Station

3. **GREEN队** (进攻模式):
   - 尝试建造 Arsenal
   - 尝试建造 War Factory
   - 可能建造 Training Ground

4. **YELLOW队** (随机模式):
   - 根据情况建造不同建筑

## 建筑物外观特征

### 资源类（金色边框，圆角矩形）
- **Gold Mine**: 最大（50px），亮金色，显示"+8$/s"
- **Trading Post**: 42px，黄绿色，显示"+60% miner speed"
- **Resource Depot**: 45px，金橙色，显示"+500 capacity"
- **Refinery**: 44px，金褐色，显示"Resource boost"

### 防御类（灰色边框，八边形）
- **Bunker**: 46px，深灰，显示"200 DMG/s"
- **Watchtower**: 40px，浅灰，显示"Detection 600"
- **Shield Generator**: 48px，青色，显示"50% Shield"
- **Barricade**: 45px，棕色，显示"500 Armor"
- **Fortress**: 50px，深灰，显示"500 DMG/s"

### 军事类（红色边框，钻石形）
- **Arsenal**: 46px，红橙色，显示"+35% DMG"
- **War Factory**: 48px，深红色，显示"Heavy unit 50%"
- **Command Center**: 50px，深红色，显示"Global +20% DMG"
- **Training Ground**: 42px，橙色，显示"+25% Speed"

### 研究类（紫色边框，六边形）
- **Research Lab**: 44px，紫色，显示"+15% Tech"
- **Tech Center**: 50px，亮紫色，显示"+30% Tech"

### 支援类（绿色边框，圆形）
- **Medical Station**: 44px，亮绿色，显示"+8 HP/s"
- **Repair Bay**: 42px，青绿色，显示"Repair 12/s"
- **Supply Depot**: 40px，黄绿色，显示"+20 Units"
- **Power Plant**: 46px，黄色，显示"+20% Speed"

## 如果还是看不到

请将控制台的输出完整复制给我，特别是：
1. 游戏开始后30秒内的所有输出
2. 任何包含"SPECIAL BUILDING"的消息
3. 任何包含"Attempting to build"的消息
4. 任何错误消息

这样我可以精确定位问题所在。
