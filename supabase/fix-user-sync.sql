-- ================================================
-- 修复：为已存在的 auth 用户创建 users 记录
-- ================================================

-- 查看当前 auth 用户和 public.users 的对应关系
SELECT
  au.id,
  au.email,
  au.created_at as auth_created,
  u.id as user_id,
  u.role
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
ORDER BY au.created_at DESC;

-- 为所有没有 public.users 记录的 auth.users 创建记录
INSERT INTO public.users (id, email, name, role)
SELECT
  au.id,
  au.email,
  COALESCE(au.raw_user_meta_data->>'name', SPLIT_PART(au.email, '@', 1)),
  'sales'  -- 默认角色
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id
WHERE u.id IS NULL
ON CONFLICT (id) DO NOTHING;

-- 验证：再次查看对应关系
SELECT
  au.id,
  au.email,
  u.role,
  CASE WHEN u.id IS NULL THEN '❌ 缺失' ELSE '✅ 正常' END as status
FROM auth.users au
LEFT JOIN public.users u ON u.id = au.id;

SELECT '✅ 用户记录同步完成！' AS status;
