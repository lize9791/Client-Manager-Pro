import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase } from '@/utils/supabase'
import type { DashboardStats } from '@/types'
import type { Followup } from '@/types'
import { useAuthStore } from './auth'

export const useDashboardStore = defineStore('dashboard', () => {
  const stats = ref<DashboardStats>({
    total_customers: 0,
    today_new: 0,
    last_7_days_new: 0,
    last_30_days_followups: 0,
    total_profit: 0,
    by_country: {},
    by_source: {},
    by_status: {}
  })
  const loading = ref(false)
  const recentFollowups = ref<Followup[]>([])
  const pendingReminders = ref<Followup[]>([])

  const authStore = useAuthStore()

  /**
   * 获取统计数据 - 使用优化的 RPC 函数（只需1次请求）
   */
  async function fetchStats(): Promise<void> {
    loading.value = true
    try {
      if (!authStore.user) {
        throw new Error('用户未登录')
      }

      // 调用优化的 RPC 函数，一次请求获取所有数据
      const { data, error } = await supabase.rpc('get_dashboard_stats', {
        user_id_param: authStore.user.id,
        user_role_param: authStore.user.role
      })

      if (error) throw error

      if (data) {
        // 解析返回的 JSON 数据
        stats.value = {
          total_customers: data.total_customers || 0,
          today_new: data.today_new || 0,
          last_7_days_new: data.last_7_days_new || 0,
          last_30_days_followups: data.last_30_days_followups || 0,
          total_profit: data.total_profit || 0,
          by_country: data.by_country || {},
          by_source: data.by_source || {},
          by_status: data.by_status || {}
        }

        // 最近跟进记录
        recentFollowups.value = data.recent_followups || []

        // 待办提醒
        pendingReminders.value = data.pending_reminders || []
      }
    } catch (error) {
      console.error('Failed to fetch stats:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  return {
    stats,
    loading,
    recentFollowups,
    pendingReminders,
    fetchStats
  }
})
