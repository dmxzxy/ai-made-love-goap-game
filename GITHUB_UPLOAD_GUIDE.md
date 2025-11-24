# GitHub 上传指南

## 方法 1: 使用 GitHub 网页界面（最简单）

1. 访问 [GitHub](https://github.com) 并登录
2. 点击右上角的 "+" 按钮，选择 "New repository"
3. 填写仓库信息：
   - Repository name: `love-goap`
   - Description: "GOAP AI Strategy Game built with Love2D"
   - 选择 Public 或 Private
   - ✅ 勾选 "Add a README file"（或稍后上传我们的 README.md）
4. 点击 "Create repository"
5. 在新创建的仓库页面，点击 "uploading an existing file"
6. 拖拽以下文件/文件夹到上传区域：
   - `main.lua`
   - `conf.lua`
   - `test_goap.lua`
   - `actions/` 文件夹
   - `entities/` 文件夹
   - `goap/` 文件夹
   - `README.md`
   - `.gitignore`
7. 写一个提交信息，如 "Initial commit: GOAP Battle Game"
8. 点击 "Commit changes"

## 方法 2: 使用 Git 命令行

在项目目录下运行以下命令：

```powershell
# 初始化 Git 仓库
cd H:\learnspace\love-goap
git init

# 添加所有文件
git add .

# 创建第一次提交
git commit -m "Initial commit: GOAP Battle Game with resource system"

# 在 GitHub 创建仓库后，连接远程仓库
# 将 YOUR_USERNAME 替换为你的 GitHub 用户名
git remote add origin https://github.com/YOUR_USERNAME/love-goap.git

# 推送到 GitHub
git branch -M main
git push -u origin main
```

## 方法 3: 使用 GitHub Desktop（推荐新手）

1. 下载并安装 [GitHub Desktop](https://desktop.github.com/)
2. 登录你的 GitHub 账号
3. 点击 "File" -> "Add Local Repository"
4. 选择 `H:\learnspace\love-goap` 文件夹
5. 如果提示不是 Git 仓库，点击 "Create a repository"
6. 填写信息后点击 "Create Repository"
7. 点击 "Publish repository" 按钮
8. 选择是否设为 Private，然后点击 "Publish Repository"

## 推荐的仓库设置

### Topics（标签）
在 GitHub 仓库页面添加以下标签方便别人发现：
- `love2d`
- `lua`
- `game-development`
- `goap`
- `ai`
- `strategy-game`
- `game-ai`

### About 描述
```
🎮 Real-time strategy game featuring GOAP (Goal-Oriented Action Planning) AI system, resource management, and 4 unique unit classes. Built with Love2D and Lua.
```

### 可选：添加演示 GIF
1. 录制游戏运行视频
2. 转换为 GIF（使用 [ScreenToGif](https://www.screentogif.com/) 或其他工具）
3. 上传到 GitHub Issues 获取链接
4. 在 README.md 中添加：
```markdown
## Gameplay Demo
![Gameplay](your-gif-url.gif)
```

## 文件清单

确保以下文件都在仓库中：

```
✅ main.lua
✅ conf.lua
✅ test_goap.lua
✅ README.md
✅ .gitignore
✅ actions/
   ✅ attack_base.lua
   ✅ attack_enemy.lua
   ✅ find_target.lua
   ✅ idle.lua
   ✅ move_to_base.lua
   ✅ move_to_enemy.lua
   ✅ retreat.lua
✅ entities/
   ✅ agent.lua
   ✅ base.lua
   ✅ resource.lua
✅ goap/
   ✅ action.lua
   ✅ planner.lua
```

## 后续维护

### 添加更新
```powershell
git add .
git commit -m "描述你的更改"
git push
```

### 创建发行版本
1. 在 GitHub 仓库页面点击 "Releases"
2. 点击 "Create a new release"
3. 设置标签如 `v1.0.0`
4. 填写发行说明
5. 可以附加 `.love` 文件供用户直接下载

## 打包 .love 文件（可选）

```powershell
# 在项目目录下
cd H:\learnspace\love-goap
7z a -tzip love-goap.love *.lua actions entities goap conf.lua

# 然后将 love-goap.love 上传到 GitHub Release
```

---

需要帮助？在仓库中创建 Issue 或查看 [GitHub 文档](https://docs.github.com/)
