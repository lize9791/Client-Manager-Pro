-- ================================================
-- 客户管理系统 - 演示数据脚本
-- 与最新的表结构匹配
-- ================================================
--
-- 使用说明：
-- 1. 请先确保你已经创建了管理员账号并登录过一次
-- 2. 将下面所有的 'YOUR_USER_ID_HERE' 替换为你的用户 UUID
-- 3. 执行此脚本
--
-- 获取你的用户 UUID 的方法：
-- SELECT id, email, role FROM public.users WHERE email = 'your-email@example.com';
-- 或者在前端登录后，在浏览器控制台输入：
-- console.log(authStore.user.id)
-- ================================================

-- ================================================
-- 第 1 步：获取并验证用户 ID
-- ================================================

-- 显示所有用户（用于复制 ID）
SELECT
  id,
  email,
  role,
  '👆 复制上面的 ID，替换下面脚本中的 3ec7f746-1232-4d51-8ebd-b48b178af15f' as instruction
FROM public.users
ORDER BY created_at DESC;

-- ================================================
-- 第 2 步：插入 30 条客户数据
-- ================================================

-- 注意：将所有 'YOUR_USER_ID_HERE' 替换为你的实际用户 UUID

INSERT INTO public.customers (
  code,
  inquiry_date,
  status,
  is_entered,
  country,
  contact,
  company,
  product,
  email,
  phone,
  source,
  remark,
  owner_id
) VALUES
  -- 客户 1-5
  ('CUS20240101001', '2024-01-05', 'new', false, '美国', 'John Smith', 'ABC Corporation', 'LED 灯具', 'john.smith@abc-corp.com', '+1-234-567-8900', 'website', '通过官网咨询，对 LED 系列产品感兴趣', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101002', '2024-01-08', 'contacted', false, '英国', 'Emma Wilson', 'XYZ Limited', '太阳能板', 'emma.wilson@xyz-ltd.co.uk', '+44-20-1234-5678', 'email', '已发送产品目录和报价单', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101003', '2024-01-10', 'quoted', true, '德国', 'Hans Mueller', 'DEF GmbH', '工业开关', 'hans.mueller@def-gmbh.de', '+49-30-12345678', 'exhibition', '慕尼黑展会客户，需要定制方案', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101004', '2024-01-12', 'negotiating', true, '法国', 'Marie Dubois', 'GHI SA', '电缆组件', 'marie.dubois@ghi-sa.fr', '+33-1-23-45-67-89', 'referral', '老客户 ABC Corp 推荐，谈判中', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101005', '2024-01-15', 'won', true, '日本', 'Tanaka Ichiro', 'JKL Industries', '传感器模块', 'tanaka@jkl-industries.jp', '+81-3-1234-5678', 'cold_call', '电话营销成功，已签订合同', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),

  -- 客户 6-10
  ('CUS20240101006', '2024-01-18', 'new', false, '加拿大', 'Robert Brown', 'MNO Corp', '连接器', 'robert.brown@mno-corp.ca', '+1-416-555-1234', 'social_media', 'LinkedIn 联系，询问批发价格', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101007', '2024-01-20', 'contacted', false, '澳大利亚', 'Sarah Johnson', 'PQR Pty Ltd', '电源适配器', 'sarah.johnson@pqr.com.au', '+61-2-9876-5432', 'website', '已回复邮件，等待客户反馈', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101008', '2024-01-22', 'quoted', true, '韩国', 'Kim Min-jun', 'STU Company', '控制面板', 'kim.minjun@stu-co.kr', '+82-2-1234-5678', 'exhibition', '首尔展会客户，已报价 $15,000', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101009', '2024-01-25', 'lost', false, '意大利', 'Giuseppe Rossi', 'VWX SpA', '断路器', 'giuseppe.rossi@vwx-spa.it', '+39-06-12345678', 'email', '价格谈不拢，客户选择了竞争对手', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240101010', '2024-01-28', 'new', false, '西班牙', 'Carlos Garcia', 'YZA SL', '配电箱', 'carlos.garcia@yza.es', '+34-91-123-4567', 'website', '索要详细技术参数和报价', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),

  -- 客户 11-15
  ('CUS20240201001', '2024-02-01', 'contacted', false, '巴西', 'Ana Silva', 'BCD Ltda', '变压器', 'ana.silva@bcd.com.br', '+55-11-98765-4321', 'referral', '合作伙伴推荐，已建立初步联系', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201002', '2024-02-05', 'negotiating', true, '印度', 'Raj Kumar', 'EFG Pvt Ltd', '电机', 'raj.kumar@efg.in', '+91-11-2345-6789', 'cold_call', '正在商讨合同细节，预计本月签约', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201003', '2024-02-08', 'won', true, '墨西哥', 'Maria Lopez', 'HIJ SA de CV', 'PLC 控制器', 'maria.lopez@hij.mx', '+52-55-1234-5678', 'exhibition', '墨西哥城展会成交，订单金额 $28,000', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201004', '2024-02-10', 'new', false, '荷兰', 'Jan van der Berg', 'KLM BV', '继电器', 'jan@klm.nl', '+31-20-123-4567', 'social_media', 'Twitter 咨询产品信息', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201005', '2024-02-12', 'contacted', false, '瑞士', 'Hans Schneider', 'NOP AG', '工业插座', 'hans.schneider@nop.ch', '+41-44-123-4567', 'website', '已发送技术资料，等待回复', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),

  -- 客户 16-20
  ('CUS20240201006', '2024-02-15', 'quoted', true, '瑞典', 'Erik Andersson', 'QRS AB', '接线端子', 'erik.andersson@qrs.se', '+46-8-123-4567', 'email', '已发送正式报价，等待客户决定', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201007', '2024-02-18', 'negotiating', true, '挪威', 'Lars Hansen', 'TUV AS', '电缆桥架', 'lars.hansen@tuv.no', '+47-22-12-34-56', 'exhibition', '奥斯陆展会客户，正在谈判付款方式', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201008', '2024-02-20', 'lost', false, '丹麦', 'Mette Nielsen', 'WXY A/S', '配线槽', 'mette.nielsen@wxy.dk', '+45-33-12-34-56', 'referral', '客户最终选择本地供应商', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201009', '2024-02-22', 'new', false, '芬兰', 'Ville Virtanen', 'ZAB Oy', '开关电源', 'ville.virtanen@zab.fi', '+358-9-123-4567', 'cold_call', '初步接触，客户表示有兴趣', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240201010', '2024-02-25', 'contacted', false, '比利时', 'Pierre Dupont', 'CDE SPRL', '指示灯', 'pierre.dupont@cde.be', '+32-2-123-4567', 'website', '已回复询盘，发送产品手册', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),

  -- 客户 21-25
  ('CUS20240301001', '2024-03-01', 'quoted', true, '奥地利', 'Wolfgang Schmidt', 'FGH GmbH', '接触器', 'wolfgang.schmidt@fgh.at', '+43-1-123-4567', 'social_media', 'Facebook 询盘，已提供报价 $8,500', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301002', '2024-03-05', 'won', true, '新加坡', 'Lee Wei Ming', 'IJK Pte Ltd', '智能开关', 'lee.weiming@ijk.sg', '+65-6123-4567', 'exhibition', '新加坡展会成交，订单 $35,000', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301003', '2024-03-08', 'new', false, '马来西亚', 'Ahmad Abdullah', 'LMN Sdn Bhd', '电表箱', 'ahmad.abdullah@lmn.my', '+60-3-1234-5678', 'email', '邮件询价，咨询交货期', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301004', '2024-03-10', 'contacted', false, '泰国', 'Somchai Wong', 'OPQ Ltd', '电缆附件', 'somchai.wong@opq.co.th', '+66-2-123-4567', 'website', '已回复并提供初步方案', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301005', '2024-03-12', 'negotiating', true, '印度尼西亚', 'Budi Santoso', 'RST PT', '配电设备', 'budi.santoso@rst.co.id', '+62-21-1234-5678', 'referral', '合作洽谈中，讨论长期供货协议', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),

  -- 客户 26-30
  ('CUS20240301006', '2024-03-15', 'quoted', true, '菲律宾', 'Jose Reyes', 'UVW Inc', '电线电缆', 'jose.reyes@uvw.ph', '+63-2-123-4567', 'cold_call', '电话营销，已发送报价单', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301007', '2024-03-18', 'lost', false, '越南', 'Nguyen Van A', 'XYZ JSC', '配电柜', 'nguyen.vana@xyz.vn', '+84-24-1234-5678', 'exhibition', '预算不足，项目暂停', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301008', '2024-03-20', 'new', false, '波兰', 'Jan Kowalski', 'ABC Sp. z o.o.', '自动化设备', 'jan.kowalski@abc.pl', '+48-22-123-4567', 'social_media', 'LinkedIn 咨询，刚建立联系', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301009', '2024-03-22', 'contacted', false, '捷克', 'Pavel Novak', 'DEF s.r.o.', '控制系统', 'pavel.novak@def.cz', '+420-2-1234-5678', 'website', '已回复技术问题，等待进一步沟通', '3ec7f746-1232-4d51-8ebd-b48b178af15f'),
  ('CUS20240301010', '2024-03-25', 'won', true, '匈牙利', 'Gabor Nagy', 'GHI Kft', '工业自动化', 'gabor.nagy@ghi.hu', '+36-1-123-4567', 'exhibition', '布达佩斯展会成交，大客户，订单 $52,000', '3ec7f746-1232-4d51-8ebd-b48b178af15f');

SELECT '✅ 第 2 步完成：已插入 30 条客户数据' AS status;

-- ================================================
-- 第 3 步：为已成交的客户创建订单
-- ================================================

INSERT INTO public.orders (customer_id, order_no, profit, product, status, create_date, remark)
SELECT
  c.id,
  'ORD' || TO_CHAR(c.inquiry_date, 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 1000)::TEXT, 3, '0'),
  CASE
    WHEN c.company LIKE '%JKL%' THEN 3500.00
    WHEN c.company LIKE '%HIJ%' THEN 5600.00
    WHEN c.company LIKE '%IJK%' THEN 7000.00
    WHEN c.company LIKE '%GHI%' THEN 10400.00
    ELSE (RANDOM() * 8000 + 2000)::NUMERIC(12, 2)
  END,
  c.product,
  CASE
    WHEN RANDOM() < 0.2 THEN 'completed'
    WHEN RANDOM() < 0.5 THEN 'production'
    WHEN RANDOM() < 0.7 THEN 'shipped'
    ELSE 'confirmed'
  END,
  c.inquiry_date + (RANDOM() * 15 + 5)::INTEGER,
  CASE
    WHEN RANDOM() < 0.5 THEN '正常订单，按时交货'
    ELSE '重要客户，优先处理'
  END
FROM public.customers c
WHERE c.status = 'won';

SELECT '✅ 第 3 步完成：已为成交客户创建订单' AS status;

-- ================================================
-- 第 4 步：创建跟进记录
-- ================================================

-- 为部分客户添加跟进记录（随机选择 20 条）
INSERT INTO public.followups (customer_id, follow_date, method, content, next_plan, remind_at, follower_id)
SELECT
  c.id,
  c.inquiry_date + (RANDOM() * 10)::INTEGER,
  CASE (RANDOM() * 5)::INTEGER
    WHEN 0 THEN 'email'
    WHEN 1 THEN 'phone'
    WHEN 2 THEN 'whatsapp'
    WHEN 3 THEN 'wechat'
    ELSE 'meeting'
  END,
  CASE (RANDOM() * 5)::INTEGER
    WHEN 0 THEN '首次联系客户，了解基本需求和采购计划'
    WHEN 1 THEN '发送产品目录和价格表，客户表示需要时间评估'
    WHEN 2 THEN '讨论技术规格和定制要求，客户对产品很满意'
    WHEN 3 THEN '跟进报价单，解答客户关于质保和售后的问题'
    ELSE '确认订单细节，讨论付款方式和交货期'
  END,
  CASE (RANDOM() * 3)::INTEGER
    WHEN 0 THEN '下周发送正式报价单'
    WHEN 1 THEN '安排样品寄送，等待客户测试反馈'
    ELSE '准备合同，等待客户确认订单'
  END,
  CASE
    WHEN RANDOM() < 0.6 THEN CURRENT_DATE + (RANDOM() * 14)::INTEGER
    ELSE NULL
  END,
  c.owner_id
FROM public.customers c
WHERE RANDOM() < 0.65
ORDER BY RANDOM()
LIMIT 20;

-- 为已成交客户添加更多跟进记录
INSERT INTO public.followups (customer_id, follow_date, method, content, next_plan, remind_at, follower_id)
SELECT
  c.id,
  c.inquiry_date + (RANDOM() * 20 + 10)::INTEGER,
  'email',
  '客户已确认订单，感谢合作！订单进入生产阶段',
  '跟踪生产进度，确保按时交货',
  NULL,
  c.owner_id
FROM public.customers c
WHERE c.status = 'won';

SELECT '✅ 第 4 步完成：已创建跟进记录' AS status;

-- ================================================
-- 验证数据
-- ================================================

-- 统计概览
SELECT
  '📊 数据统计' as info,
  (SELECT COUNT(*) FROM public.customers) as total_customers,
  (SELECT COUNT(*) FROM public.orders) as total_orders,
  (SELECT COUNT(*) FROM public.followups) as total_followups,
  (SELECT COUNT(*) FROM public.customers WHERE status = 'won') as won_customers,
  (SELECT SUM(profit) FROM public.orders) as total_profit;

-- 按状态分组
SELECT
  status,
  COUNT(*) as count,
  '客户' as type
FROM public.customers
GROUP BY status
ORDER BY count DESC;

-- 显示部分客户
SELECT
  code,
  company,
  country,
  status,
  inquiry_date
FROM public.customers
ORDER BY inquiry_date DESC
LIMIT 10;

SELECT '🎉 演示数据导入完成！' AS final_status;
SELECT '提示：现在可以在前端应用中查看这些数据了' AS note;

-- ================================================
-- 重要提醒
-- ================================================
/*
⚠️ 重要：
1. 请确保已将所有 'YOUR_USER_ID_HERE' 替换为你的实际用户 UUID
2. 如果不确定你的 UUID，执行：
   SELECT id, email FROM public.users WHERE role = 'admin';
3. 可以使用查找替换功能：
   - 查找：YOUR_USER_ID_HERE
   - 替换为：你的实际 UUID（如：a1b2c3d4-e5f6-7890-abcd-ef1234567890）
4. 替换完成后再执行此脚本

如果需要删除演示数据：
DELETE FROM public.followups WHERE customer_id IN (SELECT id FROM public.customers WHERE code LIKE 'CUS202%');
DELETE FROM public.orders WHERE order_no LIKE 'ORD202%';
DELETE FROM public.customers WHERE code LIKE 'CUS202%';
*/
