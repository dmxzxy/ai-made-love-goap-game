# 项目架构文档

## 📁 项目结构

```
love-goap/
├── main.lua                    # 游戏主入口，游戏循环和场景管理
├── conf.lua                    # LÖVE2D 配置文件
├── test_goap.lua              # GOAP 系统单元测试
├── README.md                  # 项目说明
│
├── actions/                   # GOAP 行动模块
│   ├── attack_base.lua        # 攻击敌方基地
│   ├── attack_enemy.lua       # 攻击敌方单位
│   ├── find_target.lua        # 寻找目标
│   ├── idle.lua              # 空闲状态
│   ├── move_to_base.lua      # 移动到敌方基地
│   ├── move_to_enemy.lua     # 移动到敌方单位
│   └── retreat.lua           # 撤退
│
├── entities/                  # 游戏实体
│   ├── agent.lua             # 智能体（单位）- 8种兵种
│   ├── base.lua              # 基地 - AI 决策中心
│   ├── resource.lua          # 资源点
│   ├── special_building.lua  # 特殊建筑 - 12种建筑
│   └── tower.lua             # 防御塔
│
├── goap/                      # GOAP 规划系统
│   ├── action.lua            # 行动基类
│   └── planner.lua           # A* 规划器
│
├── systems/                   # 游戏系统
│   ├── commander.lua         # 指挥官系统（未使用）
│   └── unit_counter.lua      # 单位计数器
│
├── ui/                        # 用户界面
│   ├── battle_notifications.lua  # 战斗通知
│   ├── minimap.lua              # 小地图
│   └── start_menu.lua           # 开始菜单
│
├── effects/                   # 视觉效果
│   ├── damage_numbers.lua    # 伤害数字
│   └── particles.lua         # 粒子效果
│
└── docs/                      # 开发文档
    ├── AI_IMPROVEMENTS.md
    ├── ANTI_CROWDING_SYSTEM.md
    ├── BUILDING_CHANGES.md
    ├── BUILDING_IMPROVEMENTS_2024_11_26.md
    ├── BUILDING_SYSTEM_UNIFICATION.md
    ├── DEBUG_BUILDINGS.md
    ├── GITHUB_UPLOAD_GUIDE.md
    └── UPDATE_2024_11_26.md
```

---

## 🎮 核心系统

### 1. GOAP 系统 (Goal-Oriented Action Planning)
- **位置**: `goap/`
- **功能**: 基于目标的行动规划，使用 A* 算法
- **组件**:
  - `Action`: 行动基类，定义前置条件和效果
  - `Planner`: A* 规划器，生成行动序列

### 2. 实体系统
- **位置**: `entities/`
- **核心实体**:
  - **Agent** (智能体): 8种兵种
    - Soldier (士兵)
    - Miner (矿工)
    - Sniper (狙击手)
    - Gunner (机枪手)
    - Tank (坦克)
    - Scout (侦察兵)
    - Healer (医疗兵)
    - Demolisher (爆破兵)
    - Ranger (游侠)
  
  - **Base** (基地): AI 决策中心
    - 资源管理
    - 单位生产
    - 建筑建造
    - 战术策略 (经济/防御/进攻/绝境)
  
  - **SpecialBuilding** (特殊建筑): 12种建筑
    - **资源类 (3)**: ResourceDepot, GoldMine, TradingPost
    - **防御类 (3)**: Fortress, Bunker, Watchtower
    - **军事类 (3)**: Arsenal, TrainingGround, CommandCenter
    - **生产类 (1)**: UniversalFactory
    - **支援类 (2)**: MedicalStation, SupplyDepot
  
  - **Tower** (防御塔): 自动攻击防御
  - **Resource** (资源点): 金矿资源

### 3. 行动系统
- **位置**: `actions/`
- **7种 GOAP 行动**:
  - `AttackEnemy`: 攻击敌方单位
  - `AttackBase`: 攻击敌方基地
  - `MoveToEnemy`: 移动到敌方单位
  - `MoveToBase`: 移动到敌方基地
  - `FindTarget`: 寻找目标
  - `Retreat`: 撤退
  - `Idle`: 空闲

### 4. AI 系统
- **位置**: `entities/base.lua`
- **策略模式**: 4种战术模式
  - **Economy** (经济): 优先建造资源建筑，发展经济
  - **Defensive** (防御): 优先建造防御建筑，保护基地
  - **Offensive** (进攻): 优先建造军事建筑，快速进攻
  - **Desperate** (绝境): 生命值低时的紧急模式

### 5. UI 系统
- **位置**: `ui/`
- **组件**:
  - **StartMenu**: 开始菜单，队伍数量选择
  - **Minimap**: 小地图，实时战况
  - **BattleNotifications**: 战斗通知系统

### 6. 碰撞与避障系统
- **防拥挤系统**: 
  - 推力系统 (盟友 1.2x, 敌人 0.8x)
  - 智能避障 (3+ 盟友触发)
  - 卡住检测 (1.5s 阈值)
  - 随机扩散 (±14°)

- **建筑碰撞检测**:
  - 建筑不能与塔/资源/其他建筑重叠
  - 50次随机尝试寻找有效位置
  - 支援建筑限制 2 个/队伍

### 7. 战斗系统
- **移动中攻击**: 单位可边移动边攻击
- **暴击系统**: 不同兵种有不同暴击率
- **闪避系统**: 侦察兵等高闪避单位
- **护甲系统**: 坦克等高护甲单位
- **溅射伤害**: 爆破兵范围伤害

---

## 🎯 系统简化 (2024-11-27 重构)

### 移除的系统
1. ❌ **科技树系统** (`tech_tree.lua`)
   - 移除原因: 玩家无法看到，复杂度高
   - 影响: 简化 AI 决策逻辑

2. ❌ **士气系统**
   - 移除原因: 影响不明显，增加复杂度
   - 影响: 移除士气条显示，简化战斗计算

3. ❌ **兵营系统** (`barracks.lua`)
   - 移除原因: 已与特殊建筑系统合并
   - 替代: UniversalFactory 综合工厂

### 简化的系统
- **建筑系统**: 24种 → 12种建筑
- **生产建筑**: 8种专精工厂 → 1个综合工厂

### 优化的参数
- **单位体积**: 减小 ~35% (减少拥挤)
- **攻击范围**: 增加 ~50% (更灵活战斗)

---

## 🔧 技术栈

- **引擎**: LÖVE2D (Lua 游戏引擎)
- **语言**: Lua 5.1+
- **AI**: GOAP (Goal-Oriented Action Planning)
- **寻路**: A* 算法
- **碰撞**: 圆形碰撞检测
- **渲染**: 2D 矢量图形

---

## 📊 游戏特性

### 核心玩法
- **多队伍对战**: 支持 2-4 个队伍同时对战
- **AI 自动对战**: 完全自动化的 AI 决策
- **资源管理**: 采集、存储、消耗资源
- **建筑建造**: 12种功能建筑
- **单位生产**: 8种不同特性兵种
- **战术策略**: 4种 AI 战术模式

### 视觉效果
- **伤害数字**: 暴击、闪避、护甲显示
- **粒子效果**: 攻击、死亡特效
- **战斗通知**: 重要事件提示
- **小地图**: 实时战况监控
- **颜色系统**: 12种队伍颜色

---

## 🚀 快速开始

### 运行游戏
```bash
love .
```

### 测试 GOAP 系统
```lua
love test_goap.lua
```

---

## 📝 开发说明

### 添加新兵种
1. 在 `entities/agent.lua` 中添加兵种配置
2. 定义属性: 血量、速度、伤害、射程等
3. 可选: 添加特殊能力 (治疗、溅射等)

### 添加新建筑
1. 在 `entities/special_building.lua` 的 `types` 表中添加
2. 定义: 名称、成本、效果、颜色、分类
3. 在 `entities/base.lua` 的 `shouldBuildSpecialBuilding()` 中添加建造逻辑

### 添加新行动
1. 在 `actions/` 目录创建新文件
2. 继承 `Action` 类
3. 实现 `checkProceduralPrecondition()` 和 `perform()`
4. 在单位的 `availableActions` 中注册

---

## 🐛 已知问题

参见 `docs/` 目录中的相关文档。

---

## 📄 许可

本项目为个人学习项目。
