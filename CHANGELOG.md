# 变更日志 (CHANGELOG)

所有重要的项目变更都会记录在此文件中。

---

## [2.0.0] - 2024-11-27

### 🎯 重大重构

#### 移除的系统
- **科技树系统** (`entities/tech_tree.lua`)
  - 原因: 玩家无法看到，增加复杂度
  - 影响: 简化了 AI 决策逻辑，移除了科技加成计算
  
- **士气系统** (贯穿 `entities/agent.lua`)
  - 原因: 影响不明显，计算复杂
  - 影响: 移除了士气条显示、士气影响的伤害加成和视觉效果
  
- **兵营系统** (`entities/barracks.lua`)
  - 原因: 已与特殊建筑系统合并
  - 影响: 统一使用 `UniversalFactory` 综合工厂生产单位

#### 建筑系统简化
- **从 24 种减少到 12 种建筑**
  - 删除的建筑:
    - 科研类: ResearchLab, TechCenter
    - 资源类: Refinery
    - 防御类: ShieldGenerator, Barricade
    - 支援类: RepairBay, PowerPlant
    - 生产类: InfantryFactory, TankFactory, SniperPost, GunnerArmory, ScoutCamp, FieldHospital, DemolitionWorkshop, RangerStation
  
  - 新增的建筑:
    - **UniversalFactory**: 综合工厂，替代所有专精生产建筑
  
  - 保留的建筑 (12 种):
    - 资源类 (3): ResourceDepot, GoldMine, TradingPost
    - 防御类 (3): Fortress, Bunker, Watchtower
    - 军事类 (3): Arsenal, TrainingGround, CommandCenter
    - 生产类 (1): UniversalFactory
    - 支援类 (2): MedicalStation, SupplyDepot

#### 单位参数优化
- **体积缩小** (~35%)
  - Miner: 18 → 12
  - Soldier: 20 → 13
  - Sniper: 19 → 13
  - Gunner: 22 → 15
  - Tank: 28 → 18
  - Scout: 16 → 11
  - Healer: 16 → 11
  - Demolisher: 20 → 14
  - Ranger: 17 → 12
  - 原因: 减少单位拥挤，提高移动灵活性

- **攻击范围增加** (~50%)
  - Soldier: 80-130 → 120-195
  - Sniper: 180-220 → 270-330
  - Gunner: 110-140 → 165-210
  - Tank: 70-90 → 105-135
  - Scout: 100-130 → 150-195
  - Healer: 80-100 → 120-150
  - Demolisher: 60-80 → 90-120
  - Ranger: 220-280 → 330-420
  - 原因: 增强战斗灵活性，减少近战拥挤

#### 文件整理
- **删除的文件**:
  - `entities/tech_tree.lua`
  - `entities/barracks.lua`
  
- **新增的目录结构**:
  ```
  docs/                    # 所有开发文档
  ├── AI_IMPROVEMENTS.md
  ├── ANTI_CROWDING_SYSTEM.md
  ├── BUILDING_CHANGES.md
  ├── BUILDING_IMPROVEMENTS_2024_11_26.md
  ├── BUILDING_SYSTEM_UNIFICATION.md
  ├── DEBUG_BUILDINGS.md
  ├── GITHUB_UPLOAD_GUIDE.md
  ├── README_OLD.md        # 旧版 README 备份
  └── UPDATE_2024_11_26.md
  ```

- **新增的文档**:
  - `ARCHITECTURE.md`: 详细的项目架构说明
  - `CHANGELOG.md`: 本文件
  - `README.md`: 全新的简洁 README

#### 代码质量改进
- ✅ 移除了约 120 行未使用的代码
- ✅ 简化了建筑决策逻辑
- ✅ 更新了 AI 建造优先级系统
- ✅ 所有文件通过语法检查
- ✅ 更清晰的代码结构

---

## [1.5.0] - 2024-11-26

### ✨ 新增功能

#### 防拥挤系统
- **智能碰撞推力**
  - 盟友推力: 1.2x (防止聚堆)
  - 敌人推力: 0.8x (保持战斗距离)
  
- **智能避障**
  - 检测前方 50px 范围内的 3+ 盟友
  - 自动混合 60% 目标方向 + 40% 避障方向
  
- **卡住检测**
  - 每 0.5s 检测一次位置
  - 连续 3 次未移动 (1.5s) 判定为卡住
  - 自动切换目标解决卡住
  
- **随机扩散**
  - 拥挤超过 0.5s 时触发
  - 随机偏转 ±14° 方向
  - 防止多单位长期重叠

#### 建筑碰撞检测
- **完整碰撞检测**
  - 建筑与防御塔不重叠 (+50px 安全距离)
  - 建筑与资源点不重叠 (+70px 安全距离)
  - 建筑之间不重叠 (+30px 安全距离)
  - 建筑与基地保持距离 (70px)
  
- **防御塔碰撞检测**
  - 塔与建筑不重叠 (+50px)
  - 塔与资源点不重叠 (+60px)
  - 塔之间不重叠 (+60px)
  - 塔与基地保持距离 (80px)
  
- **智能放置算法**
  - 50 次随机尝试寻找有效位置
  - 建筑: 基地附近 300px 范围
  - 防御塔: 基地附近 250px 范围
  - 失败时不扣除资源，显示提示信息

#### 支援建筑限制
- 每队最多建造 2 个支援建筑 (MedicalStation, SupplyDepot)
- 防止无限堆叠 buff 建筑
- 平衡游戏性

#### 移动中攻击
- 单位在移动到目标过程中可以攻击范围内的敌人
- 不需要停下来即可攻击
- 条件: `attackCooldown <= 0` 且敌人在攻击范围内
- 包含完整的战斗效果 (伤害、粒子、仇恨)

#### 动态游戏结束界面
- **支持 2-4 队伍**
  - 面板高度自适应: `400 + TEAM_COUNT * 80`
  - 列宽度自适应: `(1100 - 350) / TEAM_COUNT`
  
- **显示所有队伍统计**
  - Units Produced (生产单位数)
  - Kills (击杀数)
  - Tower Kills (摧毁防御塔数)
  - Gold Spent (花费金币)
  - Buildings Built (建造建筑数)
  
- **自动检测胜利者**
  - 遍历所有队伍，找到存活基地
  - 显示胜利队伍颜色和名称

### 🐛 修复的问题
- 修复了 `attackCooldown` 为 `nil` 导致的崩溃
- 使用 `(agent.attackCooldown or 0)` 确保安全访问
- 修复了单位大量聚集时的性能问题
- 修复了建筑和防御塔重叠的问题

---

## [1.0.0] - 2024-11 (初始版本)

### ✨ 核心功能

#### GOAP AI 系统
- 基于目标的行动规划 (Goal-Oriented Action Planning)
- A* 算法寻找最优行动序列
- 7 种 GOAP 行动
- 动态重新规划

#### 多队伍对战
- 支持 2-4 个队伍同时对战
- 可配置的队伍数量
- 每队独立的 AI 决策
- 动态的战场局势

#### 8 种兵种
- Soldier (士兵): 均衡型
- Miner (矿工): 采集资源
- Sniper (狙击手): 超远射程
- Gunner (机枪手): 高射速
- Tank (坦克): 高血量高护甲
- Scout (侦察兵): 高速度高闪避
- Healer (医疗兵): 治疗友军
- Demolisher (爆破兵): 对建筑高伤害
- Ranger (游侠): 超远射程，移动射击

#### 24 种建筑 (v1.0)
包括资源类、防御类、军事类、科研类、生产类、支援类

#### AI 战术系统
- **Economy**: 经济模式
- **Defensive**: 防御模式
- **Offensive**: 进攻模式
- **Desperate**: 绝境模式

#### UI 系统
- 开始菜单
- 小地图
- 战斗通知
- 游戏结束界面

#### 视觉效果
- 伤害数字 (暴击、闪避、护甲)
- 粒子效果
- 单位动画
- 建筑建造动画

---

## 版本号说明

本项目遵循 [语义化版本 2.0.0](https://semver.org/lang/zh-CN/) 规范。

- **主版本号 (MAJOR)**: 不兼容的 API 修改
- **次版本号 (MINOR)**: 向下兼容的功能性新增
- **修订号 (PATCH)**: 向下兼容的问题修正

---

## 贡献指南

发现 Bug 或有新功能建议？欢迎：
1. 提交 [Issue](https://github.com/dmxzxy/ai-made-love-goap-game/issues)
2. 创建 [Pull Request](https://github.com/dmxzxy/ai-made-love-goap-game/pulls)

---

**更多信息请查看** [README.md](README.md) 和 [ARCHITECTURE.md](ARCHITECTURE.md)
