// 用户角色
export type UserRole = 'admin' | 'sales' | 'viewer'

// 客户状态
export type CustomerStatus =
  | 'sample_won'        // 样品已成交
  | 'negotiating'       // 洽谈中
  | 'in_production'     // 排产中
  | 'completed'         // 已完成
  | 'new_round'         // 新一轮洽谈
  | 'won_by_others'     // 已被他人成交
  | 'potential'         // 潜在客户
  | 'high_value'        // 高价值客户
  | 'no_response'       // 无回复
  | 'not_executable'    // 不可执行
  | 'low_priority'      // 低优先级

// 订单状态
export type OrderStatus = 'pending' | 'confirmed' | 'production' | 'shipped' | 'completed' | 'cancelled'

// 跟进方式
export type FollowMethod = 'email' | 'phone' | 'whatsapp' | 'wechat' | 'meeting' | 'other'

// 客户来源
export type CustomerSource = 'website' | 'email' | 'exhibition' | 'referral' | 'cold_call' | 'social_media' | 'other'

// 用户接口
export interface User {
  id: string
  email: string
  role: UserRole
  name?: string
  avatar_url?: string
  created_at: string
  updated_at: string
}

// 客户接口
export interface Customer {
  id: string
  code: string
  inquiry_date: string
  status: CustomerStatus
  is_entered: boolean
  country: string
  contact: string
  company: string
  product: string
  email?: string
  phone?: string
  source: CustomerSource
  follow_method?: FollowMethod
  remark?: string
  last_follow_date?: string
  owner_id: string
  owner?: User
  created_at: string
  updated_at: string
  orders?: Order[]
  followups?: Followup[]
}

// 订单接口
export interface Order {
  id: string
  customer_id: string
  order_no: string
  profit?: number
  product: string
  status: OrderStatus
  create_date: string
  remark?: string
  created_at: string
  updated_at: string
  customer?: Customer
}

// 跟进记录接口
export interface Followup {
  id: string
  customer_id: string
  follow_date: string
  method: FollowMethod
  content: string
  next_plan?: string
  remind_at?: string
  follower_id: string
  follower?: User
  created_at: string
  updated_at: string
  customer?: Customer
}

// 附件接口
export interface Attachment {
  id: string
  customer_id?: string
  order_id?: string
  file_name: string
  file_path: string
  file_size: number
  file_type: string
  uploaded_by: string
  created_at: string
}

// 分页接口
export interface Pagination {
  page: number
  pageSize: number
  total: number
}

// 分页响应
export interface PaginatedResponse<T> {
  data: T[]
  pagination: Pagination
}

// 筛选条件
export interface CustomerFilter {
  keyword?: string
  country?: string
  status?: CustomerStatus
  is_entered?: boolean
  owner_id?: string
  source?: CustomerSource
  date_from?: string
  date_to?: string
}

// 统计数据
export interface DashboardStats {
  total_customers: number
  today_new: number
  last_7_days_new: number
  last_30_days_followups: number
  total_profit: number
  by_country: Record<string, number>
  by_source: Record<string, number>
  by_status: Record<string, number>
}

// 导入映射
export interface ImportMapping {
  [key: string]: string // Excel列名 -> 数据库字段名
}

// 导入预览数据
export interface ImportPreviewRow {
  index: number
  data: Partial<Customer>
  errors: string[]
  action: 'create' | 'update' | 'skip'
}
