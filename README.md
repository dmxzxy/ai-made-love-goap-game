# 🎮 GOAP Battle - AI 策略战争游戏

基于 LÖVE2D 和 GOAP (Goal-Oriented Action Planning) AI 系统的实时策略游戏，支持 **2-4 队伍同时对战**。

![Game Screenshot](https://via.placeholder.com/800x400?text=GOAP+Battle+Game)

---

## ✨ 主要特性

### 🤖 智能 AI 系统
- **GOAP 规划**: 基于目标的智能决策
- **4种战术模式**: 经济、防御、进攻、绝境
- **自动资源管理**: 智能采集、生产、建造
- **动态策略切换**: 根据战况自适应调整

### ⚔️ 8种兵种
| 兵种 | 特点 | 适用场景 |
|------|------|---------|
| 👤 Soldier | 均衡型，基础单位 | 主力部队 |
| ⛏️ Miner | 采集资源，高闪避 | 经济发展 |
| 🎯 Sniper | 超远射程，高暴击 | 远程压制 |
| 🔫 Gunner | 高射速，中等护甲 | 持续输出 |
| 🛡️ Tank | 超高血量和护甲 | 前排坦克 |
| 💨 Scout | 超高速度，高闪避 | 侦察骚扰 |
| 💉 Healer | 治疗友军 | 辅助支援 |
| 💣 Demolisher | 对建筑高伤害，范围攻击 | 攻城 |
| 🏹 Ranger | 超远射程，移动射击 | 游击战 |

### 🏗️ 12种建筑

#### 资源类 (3)
- **ResourceDepot** 📦: 资源存储加成 +30%
- **GoldMine** 💰: 被动收入 +3$/s
- **TradingPost** 💱: 被动收入 +2$/s

#### 防御类 (3)
- **Fortress** 🏰: 单位护甲 +25%
- **Bunker** 🛡️: 单位护甲 +15%
- **Watchtower** 👁️: 单位攻击范围 +20%

#### 军事类 (3)
- **Arsenal** ⚔️: 单位攻击力 +20%
- **TrainingGround** 🎖️: 单位移动速度 +25%
- **CommandCenter** 📡: 单位攻击速度 +20%

#### 生产类 (1)
- **UniversalFactory** 🏭: 综合工厂，生产所有兵种

#### 支援类 (2)
- **MedicalStation** ⚕️: 范围内单位恢复 +5 HP/s
- **SupplyDepot** 📮: 单位移动速度 +30%

### 🎯 核心机制
- ✅ **多队伍对战**: 支持 2-4 队同时对战
- ✅ **防拥挤系统**: 智能碰撞推力和避障
- ✅ **移动中攻击**: 单位边移动边战斗
- ✅ **建筑碰撞检测**: 防止重叠建造
- ✅ **动态游戏结束界面**: 支持所有队伍数量
- ✅ **小地图系统**: 实时战况监控
- ✅ **战斗通知**: 重要事件提示

---

## 🚀 快速开始

### 安装
1. 安装 [LÖVE2D](https://love2d.org/) (11.0+)
2. 克隆项目
```bash
git clone https://github.com/dmxzxy/ai-made-love-goap-game.git
cd ai-made-love-goap-game
```

### 运行游戏
```bash
love .
```

或在 Windows 上直接拖动项目文件夹到 `love.exe`

### 修改队伍数量
编辑 `main.lua` 第 8 行：
```lua
local TEAM_COUNT = 4  -- 改为 2, 3, 或 4
```

---

## 🎮 游戏玩法

### 开始游戏
1. 运行游戏后会看到开始菜单
2. 选择队伍数量 (2-4)
3. 点击 "Start Battle" 开始
4. AI 将自动对战，观察战况即可

### 游戏目标
- 消灭所有敌方基地
- 最后存活的队伍获胜

### UI 说明
- **左上角**: 资源和队伍状态
- **右下角**: 小地图
- **中间**: 战斗通知
- **底部**: 单位和建筑图标

### 控制
- **空格**: 暂停/继续
- **鼠标滚轮**: 缩放地图（如果支持）
- **ESC**: 退出游戏

---

## 📁 项目结构

```
love-goap/
├── main.lua              # 游戏主入口
├── conf.lua              # 配置文件
├── ARCHITECTURE.md       # 详细架构文档
├── actions/              # GOAP 行动
├── entities/             # 游戏实体
├── goap/                 # GOAP 规划系统
├── systems/              # 游戏系统
├── ui/                   # 用户界面
├── effects/              # 视觉效果
└── docs/                 # 开发文档
```

详细架构说明请查看 [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 🛠️ 技术栈

- **引擎**: LÖVE2D (Lua 游戏引擎)
- **语言**: Lua 5.1+
- **AI**: GOAP (Goal-Oriented Action Planning)
- **寻路**: A* 算法
- **碰撞检测**: 圆形碰撞

---

## 📊 游戏特色

### AI 智能决策
- 使用 GOAP 系统实现智能行为规划
- A* 算法寻找最优行动序列
- 动态评估游戏状态，切换战术模式

### 战术多样性
- **经济模式**: 发展经济，积累优势
- **防御模式**: 建造防御，稳扎稳打
- **进攻模式**: 快速进攻，一波推进
- **绝境模式**: 生死存亡，背水一战

### 视觉效果
- 伤害数字显示（暴击、闪避、护甲）
- 粒子效果（攻击、死亡）
- 战斗通知系统
- 实时小地图

### 多队伍系统
- 2队: 经典对抗
- 3队: 混乱大战
- 4队: 终极混战

---

## 🔧 开发

### 添加新兵种
编辑 `entities/agent.lua`，在构造函数中添加新的 `elseif` 分支

### 添加新建筑
编辑 `entities/special_building.lua` 的 `types` 表

### 添加新行动
在 `actions/` 目录创建新文件，继承 `Action` 类

详细开发说明请查看 [ARCHITECTURE.md](ARCHITECTURE.md)

---

## 📝 更新日志

### v2.0 (2024-11-27) - 代码重构
- ✅ 移除科技树系统
- ✅ 移除士气系统
- ✅ 移除兵营系统
- ✅ 简化建筑系统 (24 → 12 种)
- ✅ 合并生产建筑为综合工厂
- ✅ 优化单位参数（体积 -35%，射程 +50%）
- ✅ 整理项目文件和文档

### v1.5 (2024-11-26)
- ✅ 防拥挤系统
- ✅ 建筑碰撞检测
- ✅ 移动中攻击
- ✅ 动态游戏结束界面

### v1.0 (2024-11)
- ✅ 多队伍对战系统
- ✅ GOAP AI 系统
- ✅ 8种兵种
- ✅ 12种建筑
- ✅ 小地图和战斗通知

更多历史记录请查看 `docs/` 目录

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

### 贡献指南
1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可

本项目为个人学习项目，仅供学习交流使用。

---

## 🙏 致谢

- [LÖVE2D](https://love2d.org/) - 优秀的 Lua 游戏引擎
- GOAP 理论 - 来自游戏 AI 领域的智能决策算法

---

## 📮 联系方式

- GitHub: [@dmxzxy](https://github.com/dmxzxy)
- Repository: [ai-made-love-goap-game](https://github.com/dmxzxy/ai-made-love-goap-game)

---

**享受游戏！** 🎮✨
