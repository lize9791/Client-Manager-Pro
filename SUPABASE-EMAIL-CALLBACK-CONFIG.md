# 📧 Supabase 邮件回调地址配置指南

## 配置位置

Supabase 注册确认邮件的回调地址需要在 **Supabase Dashboard** 中配置。

---

## 🔧 配置步骤

### 1. 登录 Supabase Dashboard

访问：https://app.supabase.com/

选择你的项目。

### 2. 进入 Authentication 设置

1. 在左侧菜单中点击 **Authentication**
2. 点击 **URL Configuration**（URL 配置）

### 3. 配置 Site URL（站点 URL）

这是用户点击邮件确认链接后跳转的主站点地址。

**开发环境**:
```
http://localhost:3000
```

**生产环境（GitHub Pages）**:
```
https://lize9791.github.io/Client-Manager-Pro/
```

⚠️ **注意**: GitHub Pages 使用的是 Hash 路由模式，所以配置时：
- 如果使用 Hash 模式，直接配置主域名即可
- Supabase 会自动处理 `#` 后的路由

### 4. 配置 Redirect URLs（重定向 URL）

添加允许的重定向地址列表（每行一个）：

**开发环境和生产环境都添加**:
```
http://localhost:3000/**
https://lize9791.github.io/Client-Manager-Pro/**
```

`/**` 表示允许该域名下的所有路径。

---

## 📝 完整配置示例

### Site URL
```
https://lize9791.github.io/Client-Manager-Pro/
```

### Redirect URLs
```
http://localhost:3000/**
https://lize9791.github.io/Client-Manager-Pro/**
```

### Additional Redirect URLs (可选)
如果你还有其他域名或测试环境，也可以添加：
```
http://127.0.0.1:3000/**
```

---

## 🎨 自定义邮件模板（可选）

### 位置
1. **Authentication** > **Email Templates**

### 可自定义的邮件类型

1. **Confirm signup** - 注册确认邮件
2. **Invite user** - 邀请用户邮件
3. **Magic Link** - 魔术链接邮件
4. **Change Email Address** - 更改邮箱邮件
5. **Reset Password** - 重置密码邮件

### 邮件模板变量

在邮件模板中可以使用以下变量：

```html
{{ .ConfirmationURL }}  <!-- 确认链接 -->
{{ .Token }}            <!-- 令牌 -->
{{ .TokenHash }}        <!-- 令牌哈希 -->
{{ .SiteURL }}          <!-- 站点 URL -->
{{ .Email }}            <!-- 用户邮箱 -->
```

### 默认确认邮件模板示例

```html
<h2>确认您的注册</h2>

<p>请点击下面的链接确认您的邮箱地址：</p>

<p><a href="{{ .ConfirmationURL }}">确认邮箱</a></p>

<p>如果您没有注册此账户，请忽略此邮件。</p>
```

### 自定义中文模板

```html
<h2>欢迎注册客户管理系统</h2>

<p>感谢您注册 Client Manager Pro！</p>

<p>请点击下面的按钮完成邮箱验证：</p>

<p>
  <a href="{{ .ConfirmationURL }}"
     style="background-color: #667eea; color: white; padding: 12px 24px;
            text-decoration: none; border-radius: 4px; display: inline-block;">
    确认邮箱地址
  </a>
</p>

<p>或者复制以下链接到浏览器：</p>
<p>{{ .ConfirmationURL }}</p>

<p style="color: #666; font-size: 12px; margin-top: 20px;">
  如果您没有注册此账户，请忽略此邮件。
</p>
```

---

## 🔐 Email 确认流程

### 1. 用户注册
```typescript
const { data, error } = await supabase.auth.signUp({
  email: 'user@example.com',
  password: 'password123',
  options: {
    emailRedirectTo: 'https://lize9791.github.io/Client-Manager-Pro/'
  }
})
```

### 2. Supabase 发送确认邮件
邮件包含确认链接，格式类似：
```
https://your-project.supabase.co/auth/v1/verify
  ?token=xxx
  &type=signup
  &redirect_to=https://lize9791.github.io/Client-Manager-Pro/
```

### 3. 用户点击链接
- Supabase 验证 token
- 自动重定向到配置的 `redirect_to` URL
- 同时在 URL 中附带 `access_token` 和 `refresh_token`

### 4. 前端处理回调
```typescript
// 在 router 或 App.vue 中监听
supabase.auth.onAuthStateChange((event, session) => {
  if (event === 'SIGNED_IN') {
    // 用户已确认并登录
    router.push('/dashboard')
  }
})
```

---

## 🌐 Hash 路由模式的特殊处理

由于你的项目使用 Hash 路由（`#/`），Supabase 回调时的 URL 格式为：

```
https://lize9791.github.io/Client-Manager-Pro/#access_token=xxx&refresh_token=yyy
```

### 自动登录处理

修改 `src/router/index.ts` 或 `src/App.vue`，添加自动处理：

```typescript
// src/App.vue 或 main.ts
import { supabase } from '@/lib/supabase'

// 检查 URL 中的 auth tokens
const hashParams = new URLSearchParams(window.location.hash.substring(1))
const accessToken = hashParams.get('access_token')
const refreshToken = hashParams.get('refresh_token')

if (accessToken && refreshToken) {
  // 自动设置 session
  supabase.auth.setSession({
    access_token: accessToken,
    refresh_token: refreshToken
  }).then(() => {
    // 清除 URL 中的 token 参数
    window.location.hash = '#/'
  })
}
```

---

## ✅ 验证配置

### 测试步骤

1. **本地测试**:
   ```bash
   npm run dev
   ```
   访问 http://localhost:3000，注册新用户

2. **检查邮件**:
   查收注册邮件，点击确认链接

3. **验证重定向**:
   确认是否正确跳转到你的网站

4. **检查登录状态**:
   ```typescript
   const { data: { user } } = await supabase.auth.getUser()
   console.log(user)  // 应该有用户信息
   ```

---

## 🐛 常见问题

### 问题 1: 点击邮件链接后 404

**原因**: Site URL 配置不正确

**解决**: 确保 Site URL 完全匹配你的网站地址，包括尾部斜杠

### 问题 2: 重定向被拦截

**错误**: "Invalid Redirect URL"

**原因**: 重定向地址不在 Redirect URLs 白名单中

**解决**: 在 Redirect URLs 中添加允许的地址

### 问题 3: 确认后没有自动登录

**原因**: 前端没有处理 auth token

**解决**: 添加上面提到的自动登录处理代码

### 问题 4: 开发环境和生产环境切换问题

**解决**: 使用环境变量动态配置：

```typescript
// .env.development
VITE_SITE_URL=http://localhost:3000

// .env.production
VITE_SITE_URL=https://lize9791.github.io/Client-Manager-Pro/

// 代码中使用
const { data, error } = await supabase.auth.signUp({
  email: email,
  password: password,
  options: {
    emailRedirectTo: import.meta.env.VITE_SITE_URL
  }
})
```

---

## 📱 配置截图位置

在 Supabase Dashboard 中：

```
Project Dashboard
  └── Authentication
       ├── URL Configuration  ← 在这里配置
       │   ├── Site URL
       │   └── Redirect URLs
       │
       └── Email Templates    ← 自定义邮件模板
           ├── Confirm signup
           ├── Reset Password
           └── ...
```

---

## 🔗 相关链接

- Supabase Auth 文档: https://supabase.com/docs/guides/auth
- Email Templates: https://supabase.com/docs/guides/auth/auth-email-templates
- URL Configuration: https://supabase.com/docs/guides/auth/redirect-urls

---

## ✅ 配置检查清单

- [ ] 登录 Supabase Dashboard
- [ ] 进入 Authentication > URL Configuration
- [ ] 配置 Site URL: `https://lize9791.github.io/Client-Manager-Pro/`
- [ ] 添加 Redirect URLs:
  - [ ] `http://localhost:3000/**`
  - [ ] `https://lize9791.github.io/Client-Manager-Pro/**`
- [ ] 点击 **Save** 保存配置
- [ ] (可选) 自定义邮件模板
- [ ] 测试注册和确认流程

---

**配置完成后，用户注册时收到的确认邮件链接将会正确跳转到你的网站！** ✅
