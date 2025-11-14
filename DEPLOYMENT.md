# 部署指南

本文档详细说明如何将客户管理系统部署到生产环境。

## 📋 部署前准备

### 1. 环境要求

- Node.js >= 18.x
- Git
- Supabase 账号
- Vercel 或 Netlify 账号（任选其一）

### 2. Supabase 配置

#### 2.1 创建项目

1. 访问 [https://supabase.com](https://supabase.com)
2. 点击 "New Project"
3. 填写项目信息：
   - Project Name: client-manager-pro
   - Database Password: 设置强密码
   - Region: 选择离用户最近的区域
4. 等待项目创建完成

#### 2.2 执行数据库脚本

1. 进入项目 Dashboard
2. 点击左侧菜单 "SQL Editor"
3. 创建新查询
4. 复制 `supabase/schema.sql` 的全部内容
5. 点击 "Run" 执行
6. 确认所有表和策略创建成功

#### 2.3 创建存储桶

1. 点击左侧菜单 "Storage"
2. 点击 "Create a new bucket"
3. 配置：
   - Name: `attachments`
   - Public bucket: 取消勾选（Private）
4. 点击 "Create bucket"

5. 设置存储桶策略：
   - 进入 `attachments` 桶
   - 点击 "Policies" 标签
   - 添加以下策略（在 SQL Editor 中执行）：

```sql
-- 用户可以上传文件
CREATE POLICY "Authenticated users can upload"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'attachments');

-- 用户可以查看文件
CREATE POLICY "Authenticated users can view"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'attachments');

-- 用户可以删除自己上传的文件
CREATE POLICY "Users can delete own files"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attachments' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

#### 2.4 获取 API 密钥

1. 点击左侧菜单 "Settings" > "API"
2. 复制以下信息：
   - Project URL
   - anon public key

**重要**：保管好这些密钥，不要泄露！

## 🚀 部署到 Vercel

### 方式一：通过 Vercel Dashboard（推荐）

1. 访问 [https://vercel.com](https://vercel.com)
2. 连接 GitHub 账号
3. 点击 "Add New Project"
4. 导入项目仓库
5. 配置项目：
   - Framework Preset: Vite
   - Root Directory: `./`
   - Build Command: `npm run build`
   - Output Directory: `dist`

6. 配置环境变量：
   - 点击 "Environment Variables"
   - 添加：
     ```
     VITE_SUPABASE_URL=your_supabase_project_url
     VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

7. 点击 "Deploy"
8. 等待部署完成

### 方式二：通过 Vercel CLI

```bash
# 安装 Vercel CLI
npm i -g vercel

# 登录
vercel login

# 部署
vercel

# 添加环境变量
vercel env add VITE_SUPABASE_URL
vercel env add VITE_SUPABASE_ANON_KEY

# 生产部署
vercel --prod
```

### 配置自定义域名

1. 在 Vercel Dashboard 中进入项目
2. 点击 "Settings" > "Domains"
3. 添加自定义域名
4. 按照提示配置 DNS 记录

## 🌐 部署到 Netlify

### 方式一：通过 Netlify Dashboard

1. 访问 [https://netlify.com](https://netlify.com)
2. 点击 "Add new site" > "Import an existing project"
3. 连接 GitHub 仓库
4. 配置构建设置：
   - Build command: `npm run build`
   - Publish directory: `dist`

5. 配置环境变量：
   - 点击 "Site settings" > "Build & deploy" > "Environment"
   - 添加：
     ```
     VITE_SUPABASE_URL=your_supabase_project_url
     VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

6. 点击 "Deploy site"

### 方式二：通过 Netlify CLI

```bash
# 安装 Netlify CLI
npm i -g netlify-cli

# 登录
netlify login

# 初始化
netlify init

# 部署
netlify deploy --prod
```

## 👤 创建管理员账号

部署完成后，需要创建第一个管理员账号：

1. 访问部署的网站
2. 点击"注册"创建账号
3. 注册完成后，到 Supabase Dashboard
4. 点击 "Authentication" > "Users"
5. 找到刚注册的用户
6. 复制用户的 ID (UUID)
7. 在 SQL Editor 中执行：

```sql
UPDATE public.users
SET role = 'admin'
WHERE id = 'your-user-uuid';
```

8. 刷新页面，现在该用户具有管理员权限

## 📊 导入演示数据（可选）

如果需要测试数据：

1. 确保已创建管理员账号
2. 在 SQL Editor 中打开 `supabase/demo-data.sql`
3. 将所有 `'admin-user-id'` 替换为实际的管理员 UUID
4. 执行脚本

## 🔒 安全配置

### 1. 启用 Email 确认

在 Supabase Dashboard 中：
1. Authentication > Settings
2. 启用 "Enable email confirmations"

### 2. 配置 SMTP（生产环境必须）

1. Authentication > Settings > SMTP Settings
2. 配置邮件服务器信息（推荐使用 SendGrid, AWS SES 等）

### 3. 设置 RLS 策略

确认 RLS 已启用（schema.sql 中已包含）：

```sql
-- 检查 RLS 状态
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

### 4. 定期备份

在 Supabase Dashboard 中：
1. Database > Backups
2. 启用自动备份
3. 定期导出数据

## 🔧 性能优化

### 1. 启用 CDN

Vercel 和 Netlify 默认启用 CDN，无需额外配置。

### 2. 数据库索引

确认以下索引已创建（schema.sql 中已包含）：

```sql
-- 查看所有索引
SELECT tablename, indexname
FROM pg_indexes
WHERE schemaname = 'public';
```

### 3. 图片优化

如果使用附件功能，建议：
- 限制文件大小（在 Storage 配置中设置）
- 使用图片压缩
- 启用 CDN 缓存

## 📈 监控与日志

### Vercel Analytics

1. 在 Vercel Dashboard 中启用 Analytics
2. 查看访问数据和性能指标

### Supabase Logs

1. 在 Supabase Dashboard 中查看：
   - Database logs
   - API logs
   - Auth logs

### 错误追踪

推荐集成：
- Sentry（前端错误追踪）
- LogRocket（用户行为记录）

## 🔄 CI/CD 配置

### GitHub Actions（可选）

创建 `.github/workflows/deploy.yml`：

```yaml
name: Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test

      - name: Build
        run: npm run build
        env:
          VITE_SUPABASE_URL: ${{ secrets.VITE_SUPABASE_URL }}
          VITE_SUPABASE_ANON_KEY: ${{ secrets.VITE_SUPABASE_ANON_KEY }}

      - name: Deploy to Vercel
        uses: amondnet/vercel-action@v25
        with:
          vercel-token: ${{ secrets.VERCEL_TOKEN }}
          vercel-org-id: ${{ secrets.ORG_ID }}
          vercel-project-id: ${{ secrets.PROJECT_ID }}
```

## 🐛 常见问题

### Q: 部署后页面空白

A: 检查：
1. 环境变量是否正确配置
2. 浏览器控制台是否有错误
3. Supabase URL 和 Key 是否正确

### Q: 登录后提示权限错误

A: 检查：
1. RLS 策略是否正确创建
2. 用户角色是否正确设置
3. 查看 Supabase Logs 中的错误信息

### Q: 文件上传失败

A: 检查：
1. Storage 桶是否创建
2. Storage 策略是否正确
3. 文件大小是否超过限制

### Q: 数据导入失败

A: 检查：
1. Excel 格式是否正确
2. 必填字段是否完整
3. 日期格式是否为 YYYY-MM-DD

## 📞 技术支持

如遇到问题：
1. 查看 GitHub Issues
2. 检查 Supabase 文档
3. 联系技术支持

## 🎯 部署检查清单

- [ ] Supabase 项目已创建
- [ ] 数据库表结构已创建
- [ ] RLS 策略已启用
- [ ] Storage 桶已创建并配置策略
- [ ] 环境变量已配置
- [ ] 前端已部署到 Vercel/Netlify
- [ ] 管理员账号已创建
- [ ] 演示数据已导入（可选）
- [ ] SMTP 已配置（生产环境）
- [ ] 自定义域名已配置（可选）
- [ ] 监控和日志已启用
- [ ] 备份策略已设置

完成以上步骤后，系统即可正常使用！
