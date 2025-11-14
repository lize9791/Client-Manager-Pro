-- ================================================
-- 修复 Users 表的 RLS 策略（解决无限递归问题）
-- ================================================

-- 删除有问题的策略
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can update all users" ON public.users;

-- 创建修复后的策略
-- 方法：不在 users 表的策略中再次查询 users 表

-- 所有认证用户都可以查看所有用户（或者只查看自己）
-- 如果你想让普通用户也能看到其他用户信息（比如在选择负责人时）
CREATE POLICY "Authenticated users can view all users"
  ON public.users FOR SELECT
  TO authenticated
  USING (true);

-- 只有用户本人可以更新自己的资料
-- Admin 的更新权限通过应用层控制，而不是 RLS
CREATE POLICY "Users can update own profile only"
  ON public.users FOR UPDATE
  TO authenticated
  USING (auth.uid() = id);

-- 如果你只想让用户看到自己的信息，使用下面这个策略替代上面的
-- DROP POLICY IF EXISTS "Authenticated users can view all users" ON public.users;
-- CREATE POLICY "Users can only view own profile"
--   ON public.users FOR SELECT
--   TO authenticated
--   USING (auth.uid() = id);

SELECT '✅ Users 表策略修复完成！' AS status;
SELECT '提示：现在所有认证用户都可以查看用户列表，这对于选择负责人等功能是必要的' AS note;
