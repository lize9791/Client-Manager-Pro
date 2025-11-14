-- ================================================
-- 第 5 步：Attachments 表 RLS 策略
-- 在第 4 步成功后执行
-- ================================================

CREATE POLICY "Users can view attachments of own customers"
  ON public.attachments FOR SELECT
  USING (
    (customer_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = attachments.customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )) OR
    (order_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.orders
      JOIN public.customers ON customers.id = orders.customer_id
      WHERE orders.id = attachments.order_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    ))
  );

CREATE POLICY "Users can insert attachments"
  ON public.attachments FOR INSERT
  WITH CHECK (
    uploaded_by = auth.uid() AND
    ((customer_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.customers
      WHERE customers.id = customer_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )) OR
    (order_id IS NOT NULL AND EXISTS (
      SELECT 1 FROM public.orders
      JOIN public.customers ON customers.id = orders.customer_id
      WHERE orders.id = order_id
      AND (customers.owner_id = auth.uid() OR
           EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))
    )))
  );

CREATE POLICY "Users can delete own attachments"
  ON public.attachments FOR DELETE
  USING (
    uploaded_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

SELECT '✅ 第 5 步完成：Attachments 策略创建成功' AS status;
SELECT '🎉 所有步骤完成！数据库设置成功！' AS final_status;
