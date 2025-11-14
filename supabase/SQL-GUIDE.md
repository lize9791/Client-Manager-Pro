# SQL 执行指南

如果执行完整的 `schema.sql` 遇到错误，请按以下步骤分步执行：

## ⚠️ 重要：首次执行前先清理

如果你之前尝试过创建表，**必须先执行第 0 步清理旧数据**！

### 步骤 0: 清理旧表（首次执行必须）

在 Supabase SQL Editor 中执行：

```sql
-- 复制并执行 schema-step0-cleanup.sql 的内容
```

**警告**: 这会删除所有现有的表和数据！仅在首次设置或需要重新开始时使用。

**验证**: 看到 "✅ 清理完成！" 即可继续

---

## 📝 分步执行步骤

### 步骤 1: 创建表结构

在 Supabase SQL Editor 中执行：

```sql
-- 复制并执行 schema-step1-tables.sql 的内容
```

**验证**: 查看左侧 Database > Tables，应该看到 5 个表：
- users
- customers
- orders
- followups
- attachments

---

### 步骤 2: 创建索引和触发器

执行：

```sql
-- 复制并执行 schema-step2-indexes.sql 的内容
```

**验证**: 没有错误提示即为成功

---

### 步骤 3: 创建 Users 和 Customers RLS 策略

执行：

```sql
-- 复制并执行 schema-step3-rls-part1.sql 的内容
```

**验证**: 在表的 Policies 标签中应该看到策略

---

### 步骤 4: 创建 Orders 和 Followups RLS 策略

执行：

```sql
-- 复制并执行 schema-step4-rls-part2.sql 的内容
```

---

### 步骤 5: 创建 Attachments RLS 策略

执行：

```sql
-- 复制并执行 schema-step5-rls-part3.sql 的内容
```

看到 "🎉 所有步骤完成！" 即表示数据库设置成功！

---

## 🐛 常见错误排查

### 错误: "column customer_id does not exist"

**原因**: 在 RLS 策略中引用列时出错

**解决方案**:
1. 先删除所有已创建的策略
2. 按照上述 5 个步骤重新执行
3. 每步执行后确认成功再执行下一步

### 删除所有策略的 SQL:

```sql
-- 删除所有 RLS 策略（如果需要重来）
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update all users" ON public.users;

DROP POLICY IF EXISTS "Admins can view all customers" ON public.customers;
DROP POLICY IF EXISTS "Sales can view own customers" ON public.customers;
DROP POLICY IF EXISTS "Viewers can view own customers" ON public.customers;
DROP POLICY IF EXISTS "Admins can insert customers" ON public.customers;
DROP POLICY IF EXISTS "Sales can insert own customers" ON public.customers;
DROP POLICY IF EXISTS "Admins can update all customers" ON public.customers;
DROP POLICY IF EXISTS "Sales can update own customers" ON public.customers;
DROP POLICY IF EXISTS "Admins can delete customers" ON public.customers;
DROP POLICY IF EXISTS "Sales can delete own customers" ON public.customers;

DROP POLICY IF EXISTS "Users can view orders of own customers" ON public.orders;
DROP POLICY IF EXISTS "Users can insert orders for own customers" ON public.orders;
DROP POLICY IF EXISTS "Users can update orders of own customers" ON public.orders;
DROP POLICY IF EXISTS "Users can delete orders of own customers" ON public.orders;

DROP POLICY IF EXISTS "Users can view followups of own customers" ON public.followups;
DROP POLICY IF EXISTS "Users can insert followups for own customers" ON public.followups;
DROP POLICY IF EXISTS "Users can update own followups" ON public.followups;
DROP POLICY IF EXISTS "Users can delete own followups" ON public.followups;

DROP POLICY IF EXISTS "Users can view attachments of own customers" ON public.attachments;
DROP POLICY IF EXISTS "Users can insert attachments" ON public.attachments;
DROP POLICY IF EXISTS "Users can delete own attachments" ON public.attachments;
```

---

## ✅ 验证数据库设置

执行以下查询检查:

```sql
-- 1. 检查所有表
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. 检查 RLS 是否启用
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';

-- 3. 检查策略数量
SELECT schemaname, tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;
```

预期结果：
- 5 个表
- 所有表的 rowsecurity 都是 `true`
- users: 4 个策略
- customers: 9 个策略
- orders: 4 个策略
- followups: 4 个策略
- attachments: 3 个策略

---

## 🎯 下一步

数据库设置完成后：

1. 创建 Storage 桶 `attachments`
2. 注册第一个用户
3. 将用户设为 admin:
   ```sql
   UPDATE public.users
   SET role = 'admin'
   WHERE email = 'your-email@example.com';
   ```
4. 启动前端应用开始使用！
