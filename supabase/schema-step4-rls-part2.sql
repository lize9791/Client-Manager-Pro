-- ================================================
-- 第 4 步：Orders 和 Followups 表 RLS 策略
-- 在第 3 步成功后执行
-- ================================================

-- ================================================
-- Orders 表策略
-- ================================================

CREATE POLICY "Users can view orders of own customers"
  ON public.orders FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = orders.customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
  );

CREATE POLICY "Users can insert orders for own customers"
  ON public.orders FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
  );

CREATE POLICY "Users can update orders of own customers"
  ON public.orders FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = orders.customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
  );

CREATE POLICY "Users can delete orders of own customers"
  ON public.orders FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = orders.customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
  );

-- ================================================
-- Followups 表策略
-- ================================================

CREATE POLICY "Users can view followups of own customers"
  ON public.followups FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = followups.customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
  );

CREATE POLICY "Users can insert followups for own customers"
  ON public.followups FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )
  );

CREATE POLICY "Users can update own followups"
  ON public.followups FOR UPDATE
  USING (
    follower_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "Users can delete own followups"
  ON public.followups FOR DELETE
  USING (
    follower_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

SELECT '✅ 第 4 步完成：Orders 和 Followups 策略创建成功' AS status;
