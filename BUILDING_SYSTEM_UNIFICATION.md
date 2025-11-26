# 建筑系统重大重构 - 统一建筑体系

## 主要改进

### 1. 建筑位置优化 ✅
- **网格布局**: 建筑物在基地周围形成紧凑的4x网格布局
- **固定间距**: 横向间隔70像素，纵向间隔70像素
- **基地周围**: 距离基地80像素开始布局
- **队伍方向**: 红队在基地右侧，其他队伍在基地左侧
- **结果**: 清晰的基地建筑群，不再随机分散

### 2. 移除 Barracks 系统 ✅
- **删除**: `entities/barracks.lua` 不再使用
- **合并**: 所有单位生产功能移至特殊建筑系统
- **统一**: 现在只有一个建筑系统 `SpecialBuilding`

### 3. 新增8种生产建筑 ✅

#### 生产建筑列表
| 建筑名称 | 生产单位 | 成本 | 生产时间 | 单位成本 | 视觉 |
|---------|---------|------|---------|---------|------|
| **Infantry Factory** | Soldier | $120 | 1.5s | $28 | 橙色五边形 |
| **Tank Factory** | Tank | $200 | 3.0s | $55 | 灰色五边形 |
| **Sniper Post** | Sniper | $160 | 2.5s | $42 | 绿色五边形 |
| **Gunner Armory** | Gunner | $150 | 2.0s | $38 | 红色五边形 |
| **Scout Camp** | Scout | $110 | 1.2s | $32 | 蓝色五边形 |
| **Field Hospital** | Healer | $180 | 2.8s | $42 | 白色五边形 |
| **Demolition Workshop** | Demolisher | $190 | 3.0s | $48 | 橙黄色五边形 |
| **Ranger Station** | Ranger | $170 | 2.5s | $45 | 深绿色五边形 |

### 4. 新增建筑类别：PRODUCTION ✅
- **形状**: 五边形（Pentagon）
- **边框**: 粗橙色边框（4px）+ 内部边框（2px）
- **标签**: `[PRODUCTION]` 橙色标签
- **图标**: 单字母或缩写（I, T, Sn, G, Sc, H, D, Rg）

### 5. AI建造优先级更新 ✅

#### 早期（10秒后）
- **最高优先级**: Infantry Factory（步兵工厂）
- **评分**: 150分（高于所有其他建筑）
- **数量**: 最多2个

#### 经济模式
- Gold Mine → Trading Post → Resource Depot → Refinery
- **额外**: Scout Camp（40秒后）

#### 防御模式
- Bunker → Watchtower → Shield Generator → Medical Station → Barricade
- **额外**: Sniper Post（30秒后）

#### 进攻模式
- Arsenal → War Factory → Command Center → Training Ground
- **额外**: Tank Factory（25秒后）+ Gunner Armory（35秒后）

### 6. 单位生产流程 ✅

```lua
-- 生产建筑完成后自动开始生产
building.isProducing = true
building.productionTimer = 0

-- 每帧更新生产计时器
productionTimer = productionTimer + dt

-- 当计时器达到生产时间且资源足够
if productionTimer >= productionTime and resources >= productionCost then
    -- 生产单位
    local x, y = building:getSpawnPosition()
    local agent = Agent.new(x, y, team, color, unitType)
    -- 重置计时器
    productionTimer = 0
end
```

### 7. 代码改动汇总

#### entities/special_building.lua
- **新增**: 8种生产建筑定义（行220-340）
- **新增**: `producesUnit`, `productionTime`, `productionCost` 属性
- **新增**: `productionTimer`, `isProducing` 状态
- **新增**: `checkProduction()` 方法 - 检查是否可以生产单位
- **新增**: `getSpawnPosition()` 方法 - 获取单位生成位置
- **新增**: `drawPentagon()` 方法 - 绘制五边形
- **更新**: `getBuildingCategory()` - 添加"production"类别
- **更新**: `draw()` - 添加生产建筑视觉样式
- **更新**: 图标系统 - 添加生产建筑图标

#### main.lua
- **移除**: `require("entities.barracks")` 
- **移除**: `selectedBarracks` 变量
- **移除**: Barracks 绘制代码
- **移除**: `updateTeam()` 的 Barracks 参数
- **更新**: `tryBuildSpecialBuilding()` - 网格布局算法
- **更新**: 单位生产逻辑 - 从特殊建筑生产
- **更新**: 训练场效果 - 加速生产建筑而非 Barracks

#### entities/base.lua
- **更新**: `shouldBuildSpecialBuilding()` - 添加生产建筑优先级
- **新增**: 早期步兵工厂建造（10秒，150分优先级）
- **新增**: 各模式的生产建筑选择

## 视觉改进对比

### 旧系统
```
[基地] --- 随机散布的小方块（Barracks）
   |       |       |
  [?]    [?]    [?]
   
- 位置混乱
- 无法区分建筑类型
- Barracks 和 SpecialBuilding 两套系统
```

### 新系统
```
[基地] --- 网格化建筑群
   |  
   ├─ [PRODUCTION] Infantry Factory (橙色五边形)
   ├─ [RESOURCE] Gold Mine (金色圆角矩形)
   ├─ [PRODUCTION] Tank Factory (灰色五边形)
   ├─ [DEFENSE] Bunker (灰色八边形)
   └─ [MILITARY] Arsenal (红色菱形)
   
- 紧凑有序的4x网格
- 每个建筑都有独特形状+颜色
- 清晰的类别标签
- 统一的建筑系统
```

## 游戏流程优化

### 开局（0-30秒）
1. **10秒**: AI开始建造 Infantry Factory
2. **15秒**: Infantry Factory 完成，开始生产 Soldier
3. **20秒**: 经济模式建造 Gold Mine

### 中期（30-60秒）
- 经济队：Gold Mine + Scout Camp + Trading Post
- 防御队：Bunker + Sniper Post + Medical Station  
- 进攻队：Tank Factory + Arsenal + Gunner Armory

### 后期（60秒+）
- 多样化生产建筑（Field Hospital, Demolition Workshop, Ranger Station）
- 科技建筑（Research Lab, Tech Center）
- 大规模单位生产

## 用户体验提升

1. **建筑位置**: 不再需要到处寻找建筑，全部在基地附近
2. **建筑识别**: 五边形 = 生产建筑，一目了然
3. **功能清晰**: 每个生产建筑显示生产的单位类型
4. **系统简化**: 不再有两套建筑系统，降低复杂度
5. **AI智能**: 自动优先建造生产建筑，确保持续产兵

## 性能优化

- **减少绘制调用**: 移除 Barracks 独立绘制循环
- **统一更新逻辑**: 所有建筑在一个循环中更新
- **减少代码复杂度**: 单一建筑系统，更易维护

## 如何测试

1. **启动游戏**: `love .`
2. **观察基地周围**: 应该看到紧凑的建筑群
3. **识别生产建筑**: 橙色五边形建筑
4. **查看单位生产**: 生产建筑完成后自动产兵
5. **确认位置**: 建筑呈4x网格排列，不再随机

## 成功标志

✅ 所有建筑在基地周围70像素间隔的网格中
✅ 看到橙色五边形的生产建筑  
✅ 单位从生产建筑生成（不是从基地）
✅ 控制台输出 "★ [RED Infantry Factory] Soldier spawned!"
✅ 不再看到旧的 Barracks 方块
✅ 建筑类别标签包括 [PRODUCTION]

---

**重启游戏以查看所有改进！** 🎮
