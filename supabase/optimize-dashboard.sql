-- ================================================
-- Dashboard 性能优化 - 合并多个查询为单个 RPC 函数
-- ================================================

-- 创建或替换获取仪表盘统计数据的函数
CREATE OR REPLACE FUNCTION public.get_dashboard_stats(user_id_param UUID, user_role_param TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
  customer_ids UUID[];
  today_date DATE;
  seven_days_ago_date DATE;
  thirty_days_ago_date DATE;
BEGIN
  -- 计算日期
  today_date := CURRENT_DATE;
  seven_days_ago_date := CURRENT_DATE - INTERVAL '7 days';
  thirty_days_ago_date := CURRENT_DATE - INTERVAL '30 days';

  -- 如果是 Sales 用户，获取其客户 ID 列表
  IF user_role_param = 'sales' THEN
    SELECT ARRAY_AGG(id) INTO customer_ids
    FROM public.customers
    WHERE owner_id = user_id_param;

    -- 如果没有客户，返回空统计
    IF customer_ids IS NULL THEN
      customer_ids := ARRAY[]::UUID[];
    END IF;
  END IF;

  -- 构建统计结果（一次查询完成所有统计）
  SELECT json_build_object(
    'total_customers', (
      SELECT COUNT(*)
      FROM public.customers
      WHERE (user_role_param = 'admin' OR owner_id = user_id_param)
    ),
    'today_new', (
      SELECT COUNT(*)
      FROM public.customers
      WHERE (user_role_param = 'admin' OR owner_id = user_id_param)
        AND created_at >= today_date
    ),
    'last_7_days_new', (
      SELECT COUNT(*)
      FROM public.customers
      WHERE (user_role_param = 'admin' OR owner_id = user_id_param)
        AND created_at >= seven_days_ago_date
    ),
    'last_30_days_followups', (
      SELECT COUNT(*)
      FROM public.followups f
      WHERE (user_role_param = 'admin' OR
             (user_role_param = 'sales' AND f.customer_id = ANY(customer_ids)))
        AND f.follow_date >= thirty_days_ago_date
    ),
    'total_profit', (
      SELECT COALESCE(SUM(profit), 0)
      FROM public.orders o
      WHERE (user_role_param = 'admin' OR
             (user_role_param = 'sales' AND o.customer_id = ANY(customer_ids)))
    ),
    'by_country', (
      SELECT json_object_agg(country, count)
      FROM (
        SELECT
          COALESCE(country, '未知') as country,
          COUNT(*) as count
        FROM public.customers
        WHERE (user_role_param = 'admin' OR owner_id = user_id_param)
        GROUP BY country
      ) country_stats
    ),
    'by_source', (
      SELECT json_object_agg(source, count)
      FROM (
        SELECT
          COALESCE(source, '未知') as source,
          COUNT(*) as count
        FROM public.customers
        WHERE (user_role_param = 'admin' OR owner_id = user_id_param)
        GROUP BY source
      ) source_stats
    ),
    'by_status', (
      SELECT json_object_agg(status, count)
      FROM (
        SELECT
          status,
          COUNT(*) as count
        FROM public.customers
        WHERE (user_role_param = 'admin' OR owner_id = user_id_param)
        GROUP BY status
      ) status_stats
    ),
    'recent_followups', (
      SELECT COALESCE(json_agg(followup_data), '[]'::json)
      FROM (
        SELECT json_build_object(
          'id', f.id,
          'follow_date', f.follow_date,
          'method', f.method,
          'content', f.content,
          'customer', json_build_object(
            'id', c.id,
            'code', c.code,
            'company', c.company
          ),
          'follower', json_build_object(
            'id', u.id,
            'name', u.name
          )
        ) as followup_data
        FROM public.followups f
        LEFT JOIN public.customers c ON f.customer_id = c.id
        LEFT JOIN public.users u ON f.follower_id = u.id
        WHERE (user_role_param = 'admin' OR
               (user_role_param = 'sales' AND f.customer_id = ANY(customer_ids)))
        ORDER BY f.follow_date DESC
        LIMIT 5
      ) recent
    ),
    'pending_reminders', (
      SELECT COALESCE(json_agg(reminder_data), '[]'::json)
      FROM (
        SELECT json_build_object(
          'id', f.id,
          'remind_at', f.remind_at,
          'next_plan', f.next_plan,
          'customer', json_build_object(
            'id', c.id,
            'code', c.code,
            'company', c.company
          )
        ) as reminder_data
        FROM public.followups f
        LEFT JOIN public.customers c ON f.customer_id = c.id
        WHERE (user_role_param = 'admin' OR
               (user_role_param = 'sales' AND f.customer_id = ANY(customer_ids)))
          AND f.remind_at IS NOT NULL
          AND f.remind_at >= CURRENT_DATE
        ORDER BY f.remind_at ASC
        LIMIT 10
      ) reminders
    )
  ) INTO result;

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 授予执行权限
GRANT EXECUTE ON FUNCTION public.get_dashboard_stats(UUID, TEXT) TO authenticated;

-- ================================================
-- 优化索引 - 提升查询性能
-- ================================================

-- 客户表索引
CREATE INDEX IF NOT EXISTS idx_customers_owner_created
  ON public.customers(owner_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_customers_status
  ON public.customers(status);

CREATE INDEX IF NOT EXISTS idx_customers_country
  ON public.customers(country);

CREATE INDEX IF NOT EXISTS idx_customers_source
  ON public.customers(source);

-- 跟进记录索引
CREATE INDEX IF NOT EXISTS idx_followups_customer_date
  ON public.followups(customer_id, follow_date DESC);

CREATE INDEX IF NOT EXISTS idx_followups_remind_at
  ON public.followups(remind_at) WHERE remind_at IS NOT NULL;

-- 订单索引
CREATE INDEX IF NOT EXISTS idx_orders_customer
  ON public.orders(customer_id);

SELECT '✅ Dashboard 优化完成！' AS status;
SELECT '提示：现在首页只需 1 次 RPC 调用即可获取所有数据' AS note;
