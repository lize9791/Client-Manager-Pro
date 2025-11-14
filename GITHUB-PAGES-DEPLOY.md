# 🚀 GitHub Pages 部署指南

## ✅ 已完成的配置

我已经为你配置好了 GitHub Pages 部署，包括：

### 1. 路由模式改为 Hash
- ✅ 修改了 `src/router/index.ts`
- ✅ 使用 `createWebHashHistory()` 代替 `createWebHistory()`
- ✅ 这样可以避免 GitHub Pages 的路由问题

### 2. Vite 配置
- ✅ 在 `vite.config.ts` 中设置 `base: '/Client-Manager-Pro/'`
- ✅ 这是你的 GitHub 仓库名称

### 3. 部署脚本
- ✅ 添加了 `gh-pages` 依赖
- ✅ 添加了部署命令：`npm run deploy`
- ✅ 构建时自动创建 `.nojekyll` 文件

---

## 📋 部署步骤

### 步骤 1: 安装依赖

```bash
npm install
```

这会安装 `gh-pages` 包。

### 步骤 2: 初始化 Git 仓库（如果还没有）

```bash
git init
git remote add origin git@github.com:lize9791/Client-Manager-Pro.git
```

### 步骤 3: 提交代码到 main 分支

```bash
git add .
git commit -m "配置 GitHub Pages 部署"
git branch -M main
git push -u origin main
```

### 步骤 4: 部署到 GitHub Pages

```bash
npm run deploy
```

这个命令会：
1. 自动运行 `npm run build` 构建项目
2. 在 `dist` 目录创建 `.nojekyll` 文件
3. 将 `dist` 目录推送到 `gh-pages` 分支

### 步骤 5: 在 GitHub 上启用 Pages

1. 访问你的 GitHub 仓库：https://github.com/lize9791/Client-Manager-Pro
2. 点击 **Settings** > **Pages**
3. 在 **Source** 下拉框中选择 `gh-pages` 分支
4. 确保选择 `/ (root)` 目录
5. 点击 **Save**

### 步骤 6: 访问你的网站

几分钟后，你的网站将在以下地址可用：

```
https://lize9791.github.io/Client-Manager-Pro/
```

---

## 🔄 后续更新

每次修改代码后，只需要运行：

```bash
# 提交代码
git add .
git commit -m "你的提交信息"
git push

# 部署到 GitHub Pages
npm run deploy
```

---

## 🛠️ 可用的命令

```bash
# 开发模式
npm run dev

# 构建项目（包含创建 .nojekyll）
npm run build

# 预览构建结果
npm run preview

# 部署到 GitHub Pages
npm run deploy
```

---

## ⚙️ 配置说明

### package.json 脚本

```json
{
  "scripts": {
    "dev": "vite",
    "build": "vue-tsc && vite build && node scripts/post-build.mjs",
    "predeploy": "npm run build",
    "deploy": "gh-pages -d dist"
  }
}
```

- **predeploy**: 部署前自动构建
- **deploy**: 将 dist 目录推送到 gh-pages 分支

### vite.config.ts

```typescript
export default defineConfig({
  base: '/Client-Manager-Pro/',  // GitHub 仓库名
  // ...
})
```

### 路由配置

```typescript
const router = createRouter({
  history: createWebHashHistory(),  // Hash 模式
  routes
})
```

---

## 🐛 常见问题

### 问题 1: 页面 404 错误
**原因**: base 路径配置不正确
**解决**: 确保 `vite.config.ts` 中的 `base` 与仓库名一致

### 问题 2: 样式或资源加载失败
**原因**: 资源路径问题
**解决**: 使用 Hash 路由模式已解决此问题

### 问题 3: 刷新页面后 404
**原因**: History 模式在 GitHub Pages 上不支持
**解决**: 已使用 Hash 模式（URL 中有 `#`）

### 问题 4: 部署后看不到 Supabase 数据
**原因**: 环境变量没有配置
**解决**:
1. 在 GitHub 仓库中不要提交 `.env` 文件
2. 直接在代码中配置 Supabase URL 和 Key
3. 或者使用 GitHub Secrets 和 GitHub Actions

---

## 🔒 安全提示

⚠️ **重要**: 不要将 Supabase 的 Secret Key 暴露在前端代码中！

你当前使用的是 `ANON_KEY`，这是安全的，可以公开。但要确保：
- ✅ 在 Supabase 中启用了 RLS（Row Level Security）
- ✅ 不要在前端代码中使用 `SERVICE_ROLE_KEY`
- ✅ 所有敏感操作都通过 RLS 策略控制

---

## 📊 GitHub Actions 自动部署（可选）

如果你想要每次 push 到 main 分支时自动部署，可以创建：

`.github/workflows/deploy.yml`:

```yaml
name: Deploy to GitHub Pages

on:
  push:
    branches: [ main ]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Build
        run: npm run build

      - name: Deploy
        uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

这样每次 push 代码时会自动部署！

---

## ✅ 检查清单

在部署前，确保：

- [x] 已修改路由为 Hash 模式
- [x] 已配置 Vite base 路径
- [x] 已安装 gh-pages 依赖
- [x] 已创建部署脚本
- [x] 已创建 .nojekyll 文件
- [ ] 已执行 `npm install`
- [ ] 已执行 `npm run deploy`
- [ ] 已在 GitHub 启用 Pages

---

**现在你可以开始部署了！** 🎉

运行：
```bash
npm install
npm run deploy
```
