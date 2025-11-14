import { defineStore } from 'pinia'
import { ref } from 'vue'
import { supabase, TABLES } from '@/utils/supabase'
import type { Order, Pagination } from '@/types'

interface OrderFilter {
  keyword?: string
  status?: string | null
  customer_id?: string | null
  date_from?: string
  date_to?: string
}

export const useOrderStore = defineStore('order', () => {
  const orders = ref<Order[]>([])
  const currentOrder = ref<Order | null>(null)
  const loading = ref(false)
  const pagination = ref<Pagination>({
    page: 1,
    pageSize: 20,
    total: 0
  })

  /**
   * 获取订单列表（支持筛选）
   */
  async function fetchOrders(filters?: OrderFilter): Promise<void> {
    loading.value = true
    try {
      let query = supabase
        .from(TABLES.ORDERS)
        .select('*, customer:customers(id, code, company, contact)', { count: 'exact' })

      // 应用筛选条件
      if (filters) {
        // 关键词搜索（订单号或产品）
        if (filters.keyword) {
          query = query.or(`order_no.ilike.%${filters.keyword}%,product.ilike.%${filters.keyword}%`)
        }

        // 订单状态筛选
        if (filters.status) {
          query = query.eq('status', filters.status)
        }

        // 客户筛选
        if (filters.customer_id) {
          query = query.eq('customer_id', filters.customer_id)
        }

        // 日期范围筛选
        if (filters.date_from) {
          query = query.gte('create_date', filters.date_from)
        }
        if (filters.date_to) {
          query = query.lte('create_date', filters.date_to)
        }
      }

      const from = (pagination.value.page - 1) * pagination.value.pageSize
      const to = from + pagination.value.pageSize - 1

      const { data, error, count } = await query
        .order('create_date', { ascending: false })
        .range(from, to)

      if (error) throw error

      orders.value = data || []
      pagination.value.total = count || 0
    } catch (error) {
      console.error('Failed to fetch orders:', error)
      throw error
    } finally {
      loading.value = false
    }
  }

  /**
   * 获取客户的订单列表
   */
  async function fetchOrdersByCustomer(customerId: string): Promise<Order[]> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.ORDERS)
        .select('*, customer:customers(id, code, company, contact)')
        .eq('customer_id', customerId)
        .order('create_date', { ascending: false })

      if (error) throw error

      return data || []
    } catch (error) {
      console.error('Failed to fetch customer orders:', error)
      return []
    } finally {
      loading.value = false
    }
  }

  /**
   * 获取单个订单
   */
  async function fetchOrderById(id: string): Promise<Order | null> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.ORDERS)
        .select('*, customer:customers(id, code, company, contact)')
        .eq('id', id)
        .single()

      if (error) throw error

      currentOrder.value = data
      return data
    } catch (error) {
      console.error('Failed to fetch order:', error)
      return null
    } finally {
      loading.value = false
    }
  }

  /**
   * 创建订单
   */
  async function createOrder(order: Partial<Order>): Promise<any> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.ORDERS)
        .insert(order)
        .select('*, customer:customers(id, code, company, contact)')
        .single()

      if (error) return error

      if (data) {
        orders.value.unshift(data)
        pagination.value.total++
      }

      return null
    } catch (error) {
      console.error('Failed to create order:', error)
      return error
    } finally {
      loading.value = false
    }
  }

  /**
   * 更新订单
   */
  async function updateOrder(id: string, updates: Partial<Order>): Promise<any> {
    loading.value = true
    try {
      const { data, error } = await supabase
        .from(TABLES.ORDERS)
        .update(updates)
        .eq('id', id)
        .select('*, customer:customers(id, code, company, contact)')
        .single()

      if (error) return error

      if (data) {
        const index = orders.value.findIndex(o => o.id === id)
        if (index !== -1) {
          orders.value[index] = data
        }

        if (currentOrder.value?.id === id) {
          currentOrder.value = { ...currentOrder.value, ...data }
        }
      }

      return null
    } catch (error) {
      console.error('Failed to update order:', error)
      return error
    } finally {
      loading.value = false
    }
  }

  /**
   * 删除订单
   */
  async function deleteOrder(id: string): Promise<any> {
    loading.value = true
    try {
      const { error } = await supabase.from(TABLES.ORDERS).delete().eq('id', id)

      if (error) return error

      orders.value = orders.value.filter(o => o.id !== id)
      pagination.value.total--

      if (currentOrder.value?.id === id) {
        currentOrder.value = null
      }

      return null
    } catch (error) {
      console.error('Failed to delete order:', error)
      return error
    } finally {
      loading.value = false
    }
  }

  return {
    orders,
    currentOrder,
    loading,
    pagination,
    fetchOrders,
    fetchOrdersByCustomer,
    fetchOrderById,
    createOrder,
    updateOrder,
    deleteOrder
  }
})
