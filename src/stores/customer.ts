import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase, TABLES } from '@/utils/supabase'
import type { Customer, CustomerFilter, Pagination, PaginatedResponse } from '@/types'
import { useAuthStore } from './auth'

export const useCustomerStore = defineStore('customer', () => {
  const customers = ref<Customer[]>([])
  const currentCustomer = ref<Customer | null>(null)
  const loading = ref(false)
  const pagination = ref<Pagination>({
    page: 1,
    pageSize: 20,
    total: 0
  })

  const authStore = useAuthStore()

  /**
   * 获取客户列表
   */
  async function fetchCustomers(
    filter?: CustomerFilter,
    page: number = 1,
    pageSize: number = 20
  ): Promise<void> {
    loading.value = true
    try {
      let query = supabase
        .from(TABLES.CUSTOMERS)
        .select('*, owner:users!owner_id(id, email, name)', { count: 'exact' })

      // 权限过滤：Sales 只能看自己的数据
      if (authStore.isSales && authStore.user) {
        query = query.eq('owner_id', authStore.user.id)
      }

      // 应用筛选条件
      if (filter) {
        if (filter.keyword) {
          query = query.or(
            `company.ilike.%${filter.keyword}%,contact.ilike.%${filter.keyword}%,email.ilike.%${filter.keyword}%,phone.ilike.%${filter.keyword}%,code.ilike.%${filter.keyword}%`
          )
        }
        if (filter.country) query = query.eq('country', filter.country)
        if (filter.status) query = query.eq('status', filter.status)
        if (filter.is_entered !== undefined) query = query.eq('is_entered', filter.is_entered)
        if (filter.owner_id) query = query.eq('owner_id', filter.owner_id)
        if (filter.source) query = query.eq('source', filter.source)
        if (filter.date_from) query = query.gte('inquiry_date', filter.date_from)
        if (filter.date_to) query = query.lte('inquiry_date', filter.date_to)
      }

      // 分页
      const from = (page - 1) * pageSize
      const to = from + pageSize - 1

      const { data, error, count } = await query
        .order('created_at', { ascending: false })
        .range(from, to)

      if (error) throw error

      customers.value = data || []
      pagination.value = {
        page,
        pageSize,
        total: count || 0
      }
    } catch (error) {
      console.error('Failed to fetch customers:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 获取单个客户详情（包含订单和跟进记录）
   */
  async function fetchCustomerById(id: string): Promise<Customer | null> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.CUSTOMERS)
        .select(
          `
          *,
          owner:users!owner_id(id, email, name),
          orders(*),
          followups(*, follower:users!follower_id(id, email, name))
        `
        )
        .eq('id', id)
        .single()

      if (error) throw error

      currentCustomer.value = data
      return data
    } catch (error) {
      console.error('Failed to fetch customer:', error)
      return null
    } finally {
      loading.value = false
    }
  }

  /**
   * 创建客户
   */
  async function createCustomer(customer: Partial<Customer>): Promise<Customer | null> {
    loading.value = true
    try {
      // 自动设置 owner_id 为当前用户
      const newCustomer = {
        ...customer,
        owner_id: customer.owner_id || authStore.user?.id
      }

      const { data, error } = await supabase
        .from(TABLES.CUSTOMERS)
        .insert(newCustomer)
        .select('*, owner:users!owner_id(id, email, name)')
        .single()

      if (error) throw error

      // 添加到列表
      customers.value.unshift(data)
      pagination.value.total++

      return data
    } catch (error) {
      console.error('Failed to create customer:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 更新客户
   */
  async function updateCustomer(id: string, updates: Partial<Customer>): Promise<boolean> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.CUSTOMERS)
        .update(updates)
        .eq('id', id)
        .select('*, owner:users!owner_id(id, email, name)')
        .single()

      if (error) throw error

      // 更新列表中的数据
      const index = customers.value.findIndex(c => c.id === id)
      if (index !== -1) {
        customers.value[index] = data
      }

      // 更新当前客户
      if (currentCustomer.value?.id === id) {
        currentCustomer.value = { ...currentCustomer.value, ...data }
      }

      return true
    } catch (error) {
      console.error('Failed to update customer:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 删除客户
   */
  async function deleteCustomer(id: string): Promise<boolean> {
    loading.value = true
    try {
      const { error } = await supabase.from(TABLES.CUSTOMERS).delete().eq('id', id)

      if (error) throw error

      // 从列表中移除
      customers.value = customers.value.filter(c => c.id !== id)
      pagination.value.total--

      if (currentCustomer.value?.id === id) {
        currentCustomer.value = null
      }

      return true
    } catch (error) {
      console.error('Failed to delete customer:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 批量导入客户
   */
  async function importCustomers(customers: Partial<Customer>[]): Promise<{
    success: number
    failed: number
    errors: Array<{ index: number; error: string }>
  }> {
    const results = {
      success: 0,
      failed: 0,
      errors: [] as Array<{ index: number; error: string }>
    }

    for (let i = 0; i < customers.length; i++) {
      try {
        await createCustomer(customers[i])
        results.success++
      } catch (error) {
        results.failed++
        results.errors.push({
          index: i,
          error: error instanceof Error ? error.message : '未知错误'
        })
      }
    }

    return results
  }

  return {
    customers,
    currentCustomer,
    loading,
    pagination,
    fetchCustomers,
    fetchCustomerById,
    createCustomer,
    updateCustomer,
    deleteCustomer,
    importCustomers
  }
})
