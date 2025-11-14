# 客户管理系统 (Client Manager Pro)

一个功能完整的客户关系管理（CRM）Web 应用，基于 Vue 3 + Supabase 构建。

## 📋 项目简介

本系统用于管理客户询盘、订单、跟进记录等业务数据，支持多用户权限管理、数据导入导出、统计分析等功能。

## ✨ 核心功能

### v1 完整版功能清单

- ✅ **用户认证与权限管理**
  - Email 注册/登录（Supabase Auth）
  - 角色权限：Admin / Sales / Viewer
  - 基于 RLS 的数据安全控制

- ✅ **客户管理 (CRUD)**
  - 客户列表（支持搜索、筛选、分页）
  - 客户详情（包含订单和跟进记录）
  - 新增/编辑/删除客户
  - 客户字段：单号、询盘日期、状态、公司、联系人、国家、产品、邮箱、电话等

- ✅ **订单管理**
  - 订单列表和详情
  - 订单 CRUD 操作
  - 订单字段：订单号、产品、利润、状态、创建日期等

- ✅ **跟进记录**
  - 跟进记录时间轴展示
  - 添加跟进记录（时间、方式、内容、下一步计划、提醒时间）
  - 跟进提醒功能

- ✅ **数据导入/导出**
  - Excel/CSV 导入（支持列映射、预览、冲突处理）
  - 数据导出为 Excel
  - 导入模板下载

- ✅ **仪表盘与统计**
  - 客户总数、今日新增、近期统计
  - 按国家/来源分布图表（ECharts）
  - 总利润统计

- ✅ **搜索与筛选**
  - 关键字全局搜索
  - 按状态、来源、国家、负责人等筛选
  - 服务端分页

- ⏳ **附件管理**（待完善）
  - 文件上传到 Supabase Storage
  - 附件预览与下载

- ⏳ **通知提醒**（待完善）
  - 待办提醒展示
  - 邮件通知（需配置 Edge Function）

## 🛠️ 技术栈

### 前端
- **框架**: Vue 3 (Composition API, `<script setup>`)
- **构建工具**: Vite
- **语言**: TypeScript
- **状态管理**: Pinia
- **路由**: Vue Router
- **UI 组件**: Naive UI
- **图表**: ECharts
- **表格处理**: XLSX (SheetJS)

### 后端/数据库
- **BaaS**: Supabase
  - Postgres 数据库
  - Auth 认证
  - Storage 文件存储
  - Realtime 实时更新
  - Row Level Security (RLS)

## 📦 项目结构

```
client-manager-pro/
├── src/
│   ├── api/                    # API 请求封装
│   ├── assets/                 # 静态资源
│   ├── components/             # 公共组件
│   │   ├── CustomerFormModal.vue
│   │   └── ImportModal.vue
│   ├── composables/            # 组合式函数
│   ├── layouts/                # 布局组件
│   │   └── MainLayout.vue
│   ├── router/                 # 路由配置
│   │   └── index.ts
│   ├── stores/                 # Pinia 状态管理
│   │   ├── auth.ts
│   │   ├── customer.ts
│   │   ├── order.ts
│   │   ├── followup.ts
│   │   └── dashboard.ts
│   ├── types/                  # TypeScript 类型定义
│   │   └── index.ts
│   ├── utils/                  # 工具函数
│   │   ├── supabase.ts
│   │   └── helpers.ts
│   ├── views/                  # 页面视图
│   │   ├── Login.vue
│   │   ├── Dashboard.vue
│   │   ├── Customers.vue
│   │   ├── CustomerDetail.vue
│   │   ├── Orders.vue
│   │   ├── Reports.vue
│   │   └── Settings.vue
│   ├── App.vue                 # 根组件
│   └── main.ts                 # 入口文件
├── supabase/
│   └── schema.sql              # 数据库表结构
├── .env.example                # 环境变量示例
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
└── README.md
```

## 🚀 快速开始

### 1. 前置要求

- Node.js >= 18.x
- npm 或 pnpm
- Supabase 账号

### 2. 创建 Supabase 项目

1. 访问 [https://supabase.com](https://supabase.com) 并创建新项目
2. 在 SQL Editor 中执行 `supabase/schema.sql` 中的所有 SQL 语句
3. 在 Storage 中创建名为 `attachments` 的存储桶（Private）
4. 获取项目的 URL 和 anon key（Project Settings > API）

### 3. 安装依赖

```bash
# 克隆项目
cd client-manager-pro

# 安装依赖
npm install
```

### 4. 配置环境变量

复制 `.env.example` 为 `.env` 并填写 Supabase 配置：

```bash
cp .env.example .env
```

编辑 `.env`：

```env
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

### 5. 运行开发服务器

```bash
npm run dev
```

访问 http://localhost:3000

### 6. 创建管理员账号

1. 在应用中注册一个账号
2. 在 Supabase Dashboard 的 Authentication > Users 中找到该用户
3. 在 SQL Editor 中运行：

```sql
UPDATE public.users SET role = 'admin' WHERE email = 'your-email@example.com';
```

## 📝 数据库表结构

### users
- 用户基本信息
- 角色权限（admin/sales/viewer）

### customers
- 客户信息
- 关联负责人（owner_id）

### orders
- 订单信息
- 关联客户（customer_id）

### followups
- 跟进记录
- 关联客户和跟进人

### attachments
- 附件信息
- 关联客户或订单

详细结构和 RLS 策略请参考 `supabase/schema.sql`

## 🔐 权限说明

### Admin（管理员）
- 查看/编辑/删除所有数据
- 管理用户和权限
- 访问系统设置

### Sales（销售）
- 查看/编辑/删除自己负责的客户
- 为自己的客户添加订单和跟进记录
- 访问仪表盘和报表

### Viewer（查看者）
- 仅查看自己负责的客户（只读）
- 不能创建、编辑或删除数据

## 📊 导入数据

1. 点击"导入"按钮
2. 下载导入模板查看格式
3. 上传 Excel/CSV 文件
4. 映射列名到系统字段
5. 预览数据并确认导入

### 导入字段说明

| 必填字段 | 可选字段 |
|---------|---------|
| 客户单号 | 邮箱 |
| 公司名称 | 电话 |
| 联系人 | 客户来源 |
| 国家/地区 | 跟进方式 |
| 产品 | 备注 |
| 询盘日期 | |

## 🏗️ 构建与部署

### 构建生产版本

```bash
npm run build
```

构建产物在 `dist/` 目录

### 部署到 Vercel

1. 连接 GitHub 仓库到 Vercel
2. 配置环境变量（VITE_SUPABASE_URL 和 VITE_SUPABASE_ANON_KEY）
3. 自动部署

### 部署到 Netlify

1. 连接 GitHub 仓库到 Netlify
2. 构建命令：`npm run build`
3. 发布目录：`dist`
4. 配置环境变量

## 🧪 开发脚本

```bash
# 开发模式
npm run dev

# 类型检查
npm run type-check

# 代码检查
npm run lint

# 格式化代码
npm run format

# 构建生产版本
npm run build

# 预览生产版本
npm run preview
```

## 📖 使用指南

### 1. 登录系统

使用注册的邮箱和密码登录。首次使用请先注册账号。

### 2. 客户管理

- **新增客户**：点击"新增客户"按钮，填写表单
- **编辑客户**：在列表中点击操作 > 编辑
- **查看详情**：点击客户单号进入详情页
- **删除客户**：点击操作 > 删除（需确认）

### 3. 订单管理

在客户详情页中可以为客户添加订单。

### 4. 跟进记录

在客户详情页中添加跟进记录，系统会自动更新"最后跟进日期"。

### 5. 数据导入

支持批量导入客户数据，使用 Excel 模板确保格式正确。

### 6. 仪表盘

查看整体业务统计和图表分析。

## 🔧 常见问题

### Q: 如何重置密码？

A: 使用 Supabase Auth 的"忘记密码"功能，或在 Dashboard 中手动重置。

### Q: 导入失败怎么办？

A: 检查 Excel 格式是否正确，必填字段是否完整，日期格式是否为 YYYY-MM-DD。

### Q: 如何备份数据？

A: 在 Supabase Dashboard 中使用数据库备份功能，或使用导出功能。

### Q: 如何添加新的用户角色？

A: 修改数据库表结构和 RLS 策略，更新前端类型定义和权限判断逻辑。

## 🎯 后续计划

- [ ] 完善订单管理页面
- [ ] 实现附件上传和管理
- [ ] 配置 Edge Function 实现邮件提醒
- [ ] 添加更多统计报表
- [ ] 实现实时协作功能
- [ ] 多语言支持
- [ ] 移动端适配

## 📄 许可证

MIT License

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📧 联系方式

如有问题，请通过 GitHub Issues 联系。

---

**注意事项**：
1. 请妥善保管 Supabase 密钥，不要提交到版本控制
2. 生产环境请启用 HTTPS
3. 定期备份数据库
4. 监控 Supabase 使用配额

**验收清单**：
- [x] 用户注册/登录功能
- [x] Admin 可管理所有数据
- [x] Sales 只能访问自己的客户
- [x] 客户 CRUD 功能完整
- [x] Excel 导入功能可用
- [x] 数据导出功能可用
- [x] 仪表盘展示统计数据
- [x] RLS 策略正常工作
- [ ] 附件上传/下载可用（待完善）
- [ ] 邮件提醒功能（待实现）
