-- ================================================
-- 一键修复所有问题
-- 包含：RLS 循环引用 + 用户同步 + 自动触发器
-- ================================================

-- ================================================
-- 1. 修复 Users 表的 RLS 策略（解决无限递归）
-- ================================================

-- 删除有问题的策略
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update all users" ON public.users;

-- 创建修复后的策略
CREATE POLICY "Authenticated users can view all users"
  ON public.users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Users can update own profile only"
  ON public.users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

SELECT '✅ 步骤 1/3: RLS 策略修复完成' AS status;

-- ================================================
-- 2. 同步现有的 auth 用户到 public.users
-- ================================================

INSERT INTO public.users (id, email, name, role)
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1)),
  'sales'
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
WHERE u.id IS NULL
ON CONFLICT (id) DO NOTHING;

SELECT '✅ 步骤 2/3: 用户记录同步完成' AS status;

-- ================================================
-- 3. 创建自动触发器（新用户自动创建记录）
-- ================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', SPLIT_PART(NEW.email, '@', 1)),
    'sales'
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

SELECT '✅ 步骤 3/3: 自动触发器创建完成' AS status;

-- ================================================
-- 验证修复结果
-- ================================================

-- 检查所有用户是否都有对应记录
SELECT
  '用户同步检查' as check_type,
  COUNT(*) FILTER (WHERE u.id IS NOT NULL) as synced_users,
  COUNT(*) FILTER (WHERE u.id IS NULL) as missing_users,
  COUNT(*) as total_auth_users
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id;

-- 检查 RLS 策略
SELECT
  'RLS 策略检查' as check_type,
  COUNT(*) as policy_count
FROM pg_policies
WHERE tablename = 'users' AND schemaname = 'public';

-- 检查触发器
SELECT
  '触发器检查' as check_type,
  COUNT(*) as trigger_count
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';

-- 最终状态
SELECT
  '🎉 所有修复完成！' as status,
  '请刷新前端页面并重新登录' as next_step;
