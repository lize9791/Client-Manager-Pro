-- ================================================
-- 完整执行脚本 - 一次性执行所有步骤
-- ================================================
-- 使用方法：
-- 1. 如果是首次设置，或需要重新开始，请先执行下面的清理部分
-- 2. 然后执行创建部分
-- ================================================

-- ================================================
-- 第 0 步：清理（如果需要）
-- 取消下面的注释以执行清理
-- ================================================

-- 删除所有 RLS 策略
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || r.policyname || '" ON ' || r.schemaname || '.' || r.tablename;
    END LOOP;
END $$;

-- 删除触发器
DROP TRIGGER IF EXISTS update_users_updated_at ON public.users;
DROP TRIGGER IF EXISTS update_customers_updated_at ON public.customers;
DROP TRIGGER IF EXISTS update_orders_updated_at ON public.orders;
DROP TRIGGER IF EXISTS update_followups_updated_at ON public.followups;

-- 删除函数
DROP FUNCTION IF EXISTS update_updated_at_column();
DROP FUNCTION IF EXISTS generate_customer_code();

-- 删除表
DROP TABLE IF EXISTS public.attachments CASCADE;
DROP TABLE IF EXISTS public.followups CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- ================================================
-- 开始创建数据库结构
-- ================================================

-- 启用 UUID 扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. 用户表
CREATE TABLE IF NOT EXISTS public.users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT NOT NULL UNIQUE,
  name TEXT,
  role TEXT NOT NULL DEFAULT 'sales' CHECK (role IN ('admin', 'sales', 'viewer')),
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- 2. 客户表
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

-- 3. 订单表
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

-- 4. 跟进记录表
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

-- 5. 附件表
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

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_customers_owner_id ON public.customers(owner_id);
CREATE INDEX IF NOT EXISTS idx_customers_status ON public.customers(status);
CREATE INDEX IF NOT EXISTS idx_customers_country ON public.customers(country);
CREATE INDEX IF NOT EXISTS idx_customers_inquiry_date ON public.customers(inquiry_date);
CREATE INDEX IF NOT EXISTS idx_customers_code ON public.customers(code);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON public.orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_create_date ON public.orders(create_date);

CREATE INDEX IF NOT EXISTS idx_followups_customer_id ON public.followups(customer_id);
CREATE INDEX IF NOT EXISTS idx_followups_follower_id ON public.followups(follower_id);
CREATE INDEX IF NOT EXISTS idx_followups_remind_at ON public.followups(remind_at);
CREATE INDEX IF NOT EXISTS idx_followups_follow_date ON public.followups(follow_date);

CREATE INDEX IF NOT EXISTS idx_attachments_customer_id ON public.attachments(customer_id);
CREATE INDEX IF NOT EXISTS idx_attachments_order_id ON public.attachments(order_id);

-- 创建触发器函数
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
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

-- 创建辅助函数
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

-- 启用 RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.followups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.attachments ENABLE ROW LEVEL SECURITY;

-- Users 表策略
CREATE POLICY "Users can view own profile" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can view all users" ON public.users FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Admins can update all users" ON public.users FOR UPDATE USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Customers 表策略
CREATE POLICY "Admins can view all customers" ON public.customers FOR SELECT USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Sales can view own customers" ON public.customers FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Viewers can view own customers" ON public.customers FOR SELECT USING (owner_id = auth.uid());
CREATE POLICY "Admins can insert customers" ON public.customers FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Sales can insert own customers" ON public.customers FOR INSERT WITH CHECK (owner_id = auth.uid() AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('sales', 'admin')));
CREATE POLICY "Admins can update all customers" ON public.customers FOR UPDATE USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Sales can update own customers" ON public.customers FOR UPDATE USING (owner_id = auth.uid() AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'sales'));
CREATE POLICY "Admins can delete customers" ON public.customers FOR DELETE USING (EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Sales can delete own customers" ON public.customers FOR DELETE USING (owner_id = auth.uid() AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'sales'));

-- Orders 表策略
CREATE POLICY "Users can view orders of own customers" ON public.orders FOR SELECT USING (EXISTS (SELECT 1 FROM public.customers WHERE customers.id = orders.customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))));
CREATE POLICY "Users can insert orders for own customers" ON public.orders FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.customers WHERE customers.id = customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))));
CREATE POLICY "Users can update orders of own customers" ON public.orders FOR UPDATE USING (EXISTS (SELECT 1 FROM public.customers WHERE customers.id = orders.customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))));
CREATE POLICY "Users can delete orders of own customers" ON public.orders FOR DELETE USING (EXISTS (SELECT 1 FROM public.customers WHERE customers.id = orders.customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))));

-- Followups 表策略
CREATE POLICY "Users can view followups of own customers" ON public.followups FOR SELECT USING (EXISTS (SELECT 1 FROM public.customers WHERE customers.id = followups.customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))));
CREATE POLICY "Users can insert followups for own customers" ON public.followups FOR INSERT WITH CHECK (EXISTS (SELECT 1 FROM public.customers WHERE customers.id = customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))));
CREATE POLICY "Users can update own followups" ON public.followups FOR UPDATE USING (follower_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));
CREATE POLICY "Users can delete own followups" ON public.followups FOR DELETE USING (follower_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- Attachments 表策略
CREATE POLICY "Users can view attachments of own customers" ON public.attachments FOR SELECT USING ((customer_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.customers WHERE customers.id = attachments.customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')))) OR (order_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.orders JOIN public.customers ON customers.id = orders.customer_id WHERE orders.id = attachments.order_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')))));
CREATE POLICY "Users can insert attachments" ON public.attachments FOR INSERT WITH CHECK (uploaded_by = auth.uid() AND ((customer_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.customers WHERE customers.id = customer_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin')))) OR (order_id IS NOT NULL AND EXISTS (SELECT 1 FROM public.orders JOIN public.customers ON customers.id = orders.customer_id WHERE orders.id = order_id AND (customers.owner_id = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'))))));
CREATE POLICY "Users can delete own attachments" ON public.attachments FOR DELETE USING (uploaded_by = auth.uid() OR EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'));

-- 完成
SELECT '🎉 数据库设置完成！' AS status;
SELECT '下一步：在 Storage 中创建 attachments 存储桶' AS next_step;
