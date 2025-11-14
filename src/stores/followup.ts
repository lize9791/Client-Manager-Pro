import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase, TABLES } from '@/utils/supabase'
import type { Followup } from '@/types'
import { useAuthStore } from './auth'

export const useFollowupStore = defineStore('followup', () => {
  const followups = ref<Followup[]>([])
  const loading = ref(false)

  const authStore = useAuthStore()

  /**
   * 获取跟进记录列表
   */
  async function fetchFollowups(customerId?: string): Promise<void> {
    loading.value = true
    try {
      let query = supabase
        .from(TABLES.FOLLOWUPS)
        .select('*, follower:users!follower_id(id, email, name), customer:customers(id, code, company)')

      if (customerId) {
        query = query.eq('customer_id', customerId)
      }

      const { data, error } = await query.order('follow_date', { ascending: false })

      if (error) throw error

      followups.value = data || []
    } catch (error) {
      console.error('Failed to fetch followups:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 创建跟进记录
   */
  async function createFollowup(followup: Partial<Followup>): Promise<Followup | null> {
    loading.value = true
    try {
      // 自动设置跟进人为当前用户
      const newFollowup = {
        ...followup,
        follower_id: followup.follower_id || authStore.user?.id
      }

      const { data, error } = await supabase
        .from(TABLES.FOLLOWUPS)
        .insert(newFollowup)
        .select('*, follower:users!follower_id(id, email, name), customer:customers(id, code, company)')
        .single()

      if (error) throw error

      followups.value.unshift(data)

      // 更新客户的最后跟进日期
      if (followup.customer_id) {
        await supabase
          .from(TABLES.CUSTOMERS)
          .update({ last_follow_date: followup.follow_date })
          .eq('id', followup.customer_id)
      }

      return data
    } catch (error) {
      console.error('Failed to create followup:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 更新跟进记录
   */
  async function updateFollowup(id: string, updates: Partial<Followup>): Promise<boolean> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.FOLLOWUPS)
        .update(updates)
        .eq('id', id)
        .select('*, follower:users!follower_id(id, email, name), customer:customers(id, code, company)')
        .single()

      if (error) throw error

      const index = followups.value.findIndex(f => f.id === id)
      if (index !== -1) {
        followups.value[index] = data
      }

      return true
    } catch (error) {
      console.error('Failed to update followup:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 删除跟进记录
   */
  async function deleteFollowup(id: string): Promise<boolean> {
    loading.value = true
    try {
      const { error } = await supabase.from(TABLES.FOLLOWUPS).delete().eq('id', id)

      if (error) throw error

      followups.value = followups.value.filter(f => f.id !== id)

      return true
    } catch (error) {
      console.error('Failed to delete followup:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 获取需要提醒的跟进记录
   */
  async function fetchPendingReminders(): Promise<Followup[]> {
    try {
      const today = new Date().toISOString().split('T')[0]

      const { data, error } = await supabase
        .from(TABLES.FOLLOWUPS)
        .select('*, follower:users!follower_id(id, email, name), customer:customers(id, code, company)')
        .lte('remind_at', today)
        .not('remind_at', 'is', null)
        .order('remind_at', { ascending: true })

      if (error) throw error

      return data || []
    } catch (error) {
      console.error('Failed to fetch pending reminders:', error)
      return []
    }
  }

  return {
    followups,
    loading,
    fetchFollowups,
    createFollowup,
    updateFollowup,
    deleteFollowup,
    fetchPendingReminders
  }
})
