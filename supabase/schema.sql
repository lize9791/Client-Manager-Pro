-- ================================================
-- 客户管理系统 - Supabase 数据库结构
-- ================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ================================================
-- 1. 用户表 (扩展 auth.users)
-- ================================================
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'sales' CHECK (role IN ('admin', 'sales', 'viewer')),
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- ================================================
-- 2. 客户表
-- ================================================
CREATE TABLE IF NOT EXISTS public.customers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT NOT NULL UNIQUE,
  inquiry_date DATE NOT NULL,
  status TEXT NOT NULL DEFAULT 'new' CHECK (status IN ('new', 'contacted', 'quoted', 'negotiating', 'won', 'lost')),
  is_entered BOOLEAN DEFAULT FALSE,
  country TEXT NOT NULL,
  contact TEXT NOT NULL,
  company TEXT NOT NULL,
  product TEXT NOT NULL,
  email TEXT,
  phone TEXT,
  source TEXT NOT NULL DEFAULT 'other' CHECK (source IN ('website', 'email', 'exhibition', 'referral', 'cold_call', 'social_media', 'other')),
  follow_method TEXT CHECK (follow_method IN ('email', 'phone', 'whatsapp', 'wechat', 'meeting', 'other')),
  remark TEXT,
  last_follow_date DATE,
  owner_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 为常用查询字段创建索引
CREATE INDEX IF NOT EXISTS idx_customers_owner_id ON public.customers(owner_id);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_country ON public.customers(country);
CREATE INDEX IF NOT EXISTS idx_customers_inquiry_date ON public.customers(inquiry_date);
CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(code);

-- ================================================
-- 3. 订单表
-- ================================================
CREATE TABLE IF NOT EXISTS public.orders (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  order_no TEXT NOT NULL UNIQUE,
  profit NUMERIC(12, 2),
  product TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'production', 'shipped', 'completed', 'cancelled')),
  create_date DATE NOT NULL,
  remark TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_create_date ON public.orders(create_date);

-- ================================================
-- 4. 跟进记录表
-- ================================================
CREATE TABLE IF NOT EXISTS public.followups (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
  follow_date DATE NOT NULL,
  method TEXT NOT NULL CHECK (method IN ('email', 'phone', 'whatsapp', 'wechat', 'meeting', 'other')),
  content TEXT NOT NULL,
  next_plan TEXT,
  remind_at DATE,
  follower_id UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

CREATE INDEX IF NOT EXISTS idx_followups_customer_id ON public.followups(customer_id);
CREATE INDEX IF NOT EXISTS idx_followups_follower_id ON public.followups(follower_id);
CREATE INDEX IF NOT EXISTS idx_followups_remind_at ON public.followups(remind_at);
CREATE INDEX IF NOT EXISTS idx_followups_follow_date ON public.followups(follow_date);

-- ================================================
-- 5. 附件表
-- ================================================
CREATE TABLE IF NOT EXISTS public.attachments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  customer_id UUID REFERENCES public.customers(id) ON DELETE CASCADE,
  order_id UUID REFERENCES public.orders(id) ON DELETE CASCADE,
  file_name TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  file_type TEXT NOT NULL,
  uploaded_by UUID NOT NULL REFERENCES public.users(id) ON DELETE RESTRICT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),

  CONSTRAINT attachment_reference CHECK (
    (customer_id IS NOT NULL AND order_id IS NULL) OR
    (customer_id IS NULL AND order_id IS NOT NULL)
  )
);

CREATE INDEX IF NOT EXISTS idx_attachments_customer_id ON public.attachments(customer_id);
CREATE INDEX IF NOT EXISTS idx_attachments_order_id ON public.attachments(order_id);

-- ================================================
-- 触发器：自动更新 updated_at 字段
-- ================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 为所有表创建 updated_at 触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
CREATE TRIGGER update_customers_updated_at
  BEFORE UPDATE ON public.customers
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
CREATE TRIGGER update_orders_updated_at
  BEFORE UPDATE ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_followups_updated_at ON public.followups;
CREATE TRIGGER update_followups_updated_at
  BEFORE UPDATE ON public.followups
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- ================================================
-- RLS (Row Level Security) 策略
-- ================================================

-- 启用 RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

-- ================================================
-- Users 表策略
-- ================================================

-- 用户可以查看自己的资料
CREATE POLICY "Users can view own profile"
  ON public.users FOR SELECT
  USING (auth.uid() = id);

-- 用户可以更新自己的资料
CREATE POLICY "Users can update own profile"
  ON public.users FOR UPDATE
  USING (auth.uid() = id);

-- Admin 可以查看所有用户
CREATE POLICY "Admins can view all users"
  ON public.users FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Admin 可以更新所有用户
CREATE POLICY "Admins can update all users"
  ON public.users FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- ================================================
-- Customers 表策略
-- ================================================

-- Admin 可以查看所有客户
CREATE POLICY "Admins can view all customers"
  ON public.customers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Sales 只能查看自己的客户
CREATE POLICY "Sales can view own customers"
  ON public.customers FOR SELECT
  USING (owner_id = auth.uid());

-- Viewer 只能查看自己的客户
CREATE POLICY "Viewers can view own customers"
  ON public.customers FOR SELECT
  USING (owner_id = auth.uid());

-- Admin 可以插入客户
CREATE POLICY "Admins can insert customers"
  ON public.customers FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Sales 可以插入客户（自己为 owner）
CREATE POLICY "Sales can insert own customers"
  ON public.customers FOR INSERT
  WITH CHECK (
    owner_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role IN ('sales', 'admin')
    )
  );

-- Admin 可以更新所有客户
CREATE POLICY "Admins can update all customers"
  ON public.customers FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Sales 只能更新自己的客户
CREATE POLICY "Sales can update own customers"
  ON public.customers FOR UPDATE
  USING (
    owner_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'sales'
    )
  );

-- Admin 可以删除客户
CREATE POLICY "Admins can delete customers"
  ON public.customers FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Sales 可以删除自己的客户
CREATE POLICY "Sales can delete own customers"
  ON public.customers FOR DELETE
  USING (
    owner_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM public.users
      WHERE id = auth.uid() AND role = 'sales'
    )
  );

-- ================================================
-- Orders 表策略
-- ================================================

-- 用户可以查看自己客户的订单
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

-- 用户可以为自己的客户创建订单
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

-- 用户可以更新自己客户的订单
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

-- 用户可以删除自己客户的订单
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

-- 用户可以查看自己客户的跟进记录
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

-- 用户可以为自己的客户创建跟进记录
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

-- 用户可以更新自己的跟进记录
CREATE POLICY "Users can update own followups"
  ON public.followups FOR UPDATE
  USING (
    follower_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- 用户可以删除自己的跟进记录
CREATE POLICY "Users can delete own followups"
  ON public.followups FOR DELETE
  USING (
    follower_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- ================================================
-- Attachments 表策略
-- ================================================

-- 用户可以查看自己客户的附件
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

-- 用户可以上传附件
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

-- 用户可以删除自己上传的附件
CREATE POLICY "Users can delete own attachments"
  ON public.attachments FOR DELETE
  USING (
    uploaded_by = auth.uid() OR
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')
  );

-- ================================================
-- Storage 存储桶配置
-- ================================================
-- 需要在 Supabase Dashboard 中手动创建存储桶 'attachments'
-- 并设置以下策略：

-- 1. 创建存储桶 (在 Dashboard 中执行):
--    名称: attachments
--    Public: false
--    File size limit: 50MB
--    Allowed MIME types: */*

-- 2. 存储桶策略 (在 Dashboard Storage Policies 中添加):

-- 用户可以上传文件
-- CREATE POLICY "Users can upload attachments"
-- ON storage.objects FOR INSERT
-- WITH CHECK (
--   bucket_id = 'attachments' AND
--   auth.role() = 'authenticated'
-- );

-- 用户可以查看文件
-- CREATE POLICY "Users can view attachments"
-- ON storage.objects FOR SELECT
-- USING (
--   bucket_id = 'attachments' AND
--   auth.role() = 'authenticated'
-- );

-- 用户可以删除自己上传的文件
-- CREATE POLICY "Users can delete own attachments"
-- ON storage.objects FOR DELETE
-- USING (
--   bucket_id = 'attachments' AND
--   auth.uid()::text = (storage.foldername(name))[1]
-- );

-- ================================================
-- 初始化管理员用户
-- ================================================
-- 注意：需要先在 Supabase Auth 中创建用户，然后运行以下语句更新角色
-- UPDATE public.users SET role = 'admin' WHERE email = 'admin@example.com';

-- ================================================
-- 示例数据（可选）
-- ================================================

-- 插入示例客户代码生成函数
CREATE OR REPLACE FUNCTION generate_customer_code()
RETURNS TEXT AS $$
DECLARE
  code TEXT;
  exists BOOLEAN;
BEGIN
  LOOP
    code := 'CUS' || TO_CHAR(NOW(), 'YYYYMMDD') || LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');

    SELECT EXISTS(SELECT 1 FROM public.customers WHERE customers.code = code) INTO exists;

    IF NOT exists THEN
      RETURN code;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- ================================================
-- 完成
-- ================================================
-- 数据库结构创建完成！
--
-- 下一步：
-- 1. 在 Supabase Dashboard 中创建存储桶 'attachments'
-- 2. 在 Supabase Auth 中注册用户
-- 3. 将首个用户设置为 admin 角色
-- 4. 使用前端应用开始测试
