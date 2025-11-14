-- ================================================
-- 更新客户状态枚举 - 支持新的11种状态（修复版）
-- ================================================

-- 第一步：删除旧的 CHECK 约束
ALTER TABLE public.customers
DROP CONSTRAINT IF EXISTS customers_status_check;

-- 第二步：先迁移现有数据到新状态
-- 这一步很重要，必须在添加新约束之前完成
UPDATE public.customers
SET status = CASE
  WHEN status = 'new' THEN 'potential'
  WHEN status = 'contacted' THEN 'negotiating'
  WHEN status = 'quoted' THEN 'negotiating'
  WHEN status = 'won' THEN 'completed'
  WHEN status = 'lost' THEN 'won_by_others'
  WHEN status = 'negotiating' THEN 'negotiating'  -- 保持不变
  ELSE 'potential'  -- 其他未知状态默认为潜在客户
END
WHERE status IN ('new', 'contacted', 'quoted', 'won', 'lost')
   OR status NOT IN (
     'sample_won', 'negotiating', 'in_production', 'completed',
     'new_round', 'won_by_others', 'potential', 'high_value',
     'no_response', 'not_executable', 'low_priority'
   );

-- 第三步：添加新的 CHECK 约束，支持新的11种状态
ALTER TABLE public.customers
ADD CONSTRAINT customers_status_check
CHECK (status IN (
  'sample_won',       -- 样品已成交
  'negotiating',      -- 洽谈中
  'in_production',    -- 排产中
  'completed',        -- 已完成
  'new_round',        -- 新一轮洽谈
  'won_by_others',    -- 已被他人成交
  'potential',        -- 潜在客户
  'high_value',       -- 高价值客户
  'no_response',      -- 无回复
  'not_executable',   -- 不可执行
  'low_priority'      -- 低优先级
));

-- 验证数据迁移结果
SELECT
  status,
  COUNT(*) as count,
  CASE status
    WHEN 'sample_won' THEN '样品已成交'
    WHEN 'negotiating' THEN '洽谈中'
    WHEN 'in_production' THEN '排产中'
    WHEN 'completed' THEN '已完成'
    WHEN 'new_round' THEN '新一轮洽谈'
    WHEN 'won_by_others' THEN '已被他人成交'
    WHEN 'potential' THEN '潜在客户'
    WHEN 'high_value' THEN '高价值客户'
    WHEN 'no_response' THEN '无回复'
    WHEN 'not_executable' THEN '不可执行'
    WHEN 'low_priority' THEN '低优先级'
    ELSE '未知状态'
  END as status_label
FROM public.customers
GROUP BY status
ORDER BY count DESC;

SELECT '✅ 客户状态枚举更新完成！' AS status;
SELECT '新状态包括：样品已成交、洽谈中、排产中、已完成、新一轮洽谈、已被他人成交、潜在客户、高价值客户、无回复、不可执行、低优先级' AS note;
SELECT '数据迁移映射：new→potential, contacted/quoted→negotiating, won→completed, lost→won_by_others' AS migration;
