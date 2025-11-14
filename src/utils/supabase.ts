import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY

if (!supabaseUrl || !supabaseAnonKey) {
  throw new Error('Missing Supabase environment variables')
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
  auth: {
    persistSession: true,
    autoRefreshToken: true,
    detectSessionInUrl: true
  }
})

// 数据库表名常量
export const TABLES = {
  CUSTOMERS: 'customers',
  ORDERS: 'orders',
  FOLLOWUPS: 'followups',
  ATTACHMENTS: 'attachments',
  USERS: 'users'
} as const

// Storage bucket 名称
export const BUCKETS = {
  ATTACHMENTS: 'attachments'
} as const
