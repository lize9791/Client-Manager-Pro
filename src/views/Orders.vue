<template>
  <div class="orders-view">
    <n-card title="订单管理" :bordered="false">
      <!-- 搜索和筛选 -->
      <template #header-extra>
        <n-space>
          <n-button type="primary" @click="handleAdd">
            <template #icon>
              <n-icon><AddOutline /></n-icon>
            </template>
            新增订单
          </n-button>
          <n-button @click="handleRefresh">
            <template #icon>
              <n-icon><RefreshOutline /></n-icon>
            </template>
            刷新
          </n-button>
        </n-space>
      </template>

      <!-- 筛选条件 -->
      <n-space vertical size="large">
        <n-space>
          <n-input
            v-model:value="filters.keyword"
            placeholder="搜索订单号、产品"
            style="width: 250px;"
            clearable
            @update:value="handleSearch"
          >
            <template #prefix>
              <n-icon><SearchOutline /></n-icon>
            </template>
          </n-input>

          <n-select
            v-model:value="filters.status"
            placeholder="订单状态"
            style="width: 150px;"
            clearable
            :options="statusOptions"
            @update:value="handleSearch"
          />

          <n-select
            v-model:value="filters.customer_id"
            placeholder="客户筛选"
            style="width: 200px;"
            clearable
            filterable
            :options="customerOptions"
            @update:value="handleSearch"
          />

          <n-date-picker
            v-model:value="dateRange"
            type="daterange"
            clearable
            placeholder="创建日期范围"
            @update:value="handleDateChange"
          />
        </n-space>

        <!-- 统计卡片 -->
        <n-grid :cols="4" :x-gap="16">
          <n-gi>
            <n-statistic label="订单总数" :value="orderStore.pagination.total">
              <template #prefix>
                <n-icon size="20" color="#18a058"><DocumentTextOutline /></n-icon>
              </template>
            </n-statistic>
          </n-gi>
          <n-gi>
            <n-statistic label="已完成" :value="getStatusCount('completed')">
              <template #prefix>
                <n-icon size="20" color="#2080f0"><CheckmarkCircleOutline /></n-icon>
              </template>
            </n-statistic>
          </n-gi>
          <n-gi>
            <n-statistic label="生产中" :value="getStatusCount('production')">
              <template #prefix>
                <n-icon size="20" color="#f0a020"><TimeOutline /></n-icon>
              </template>
            </n-statistic>
          </n-gi>
          <n-gi>
            <n-statistic
              label="总利润 (USD)"
              :value="getTotalProfit()"
              :precision="2"
            >
              <template #prefix>
                <n-icon size="20" color="#d03050"><CashOutline /></n-icon>
              </template>
            </n-statistic>
          </n-gi>
        </n-grid>

        <!-- 订单列表 -->
        <n-data-table
          :columns="columns"
          :data="orderStore.orders"
          :loading="orderStore.loading"
          :pagination="pagination"
          :row-key="(row: Order) => row.id"
          :bordered="false"
          striped
        />
      </n-space>
    </n-card>

    <!-- 订单表单弹窗 -->
    <OrderFormModal
      v-model:visible="showFormModal"
      :order="selectedOrder"
      @success="handleSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, h } from 'vue'
import {
  NCard,
  NSpace,
  NButton,
  NIcon,
  NInput,
  NSelect,
  NDatePicker,
  NDataTable,
  NTag,
  NStatistic,
  NGrid,
  NGi,
  NDropdown,
  useMessage,
  useDialog,
  type DataTableColumns,
  type PaginationProps
} from 'naive-ui'
import {
  AddOutline,
  SearchOutline,
  RefreshOutline,
  DocumentTextOutline,
  CheckmarkCircleOutline,
  TimeOutline,
  CashOutline,
  EllipsisHorizontalOutline,
  CreateOutline,
  TrashOutline
} from '@vicons/ionicons5'
import type { Order, Customer } from '@/types'
import { useOrderStore } from '@/stores/order'
import { useCustomerStore } from '@/stores/customer'
import OrderFormModal from '@/components/OrderFormModal.vue'
import { formatDate, getOrderStatusLabel, getOrderStatusType } from '@/utils/helpers'
import { debounce } from '@/utils/helpers'

const message = useMessage()
const dialog = useDialog()
const orderStore = useOrderStore()
const customerStore = useCustomerStore()

const showFormModal = ref(false)
const selectedOrder = ref<Order | null>(null)
const dateRange = ref<[number, number] | null>(null)

const filters = ref({
  keyword: '',
  status: null as string | null,
  customer_id: null as string | null,
  date_from: '',
  date_to: ''
})

// 客户选项
const customerOptions = computed(() => {
  return customerStore.customers.map((customer: Customer) => ({
    label: `${customer.code} - ${customer.company}`,
    value: customer.id
  }))
})

// 订单状态选项
const statusOptions = [
  { label: getOrderStatusLabel('pending'), value: 'pending' },
  { label: getOrderStatusLabel('confirmed'), value: 'confirmed' },
  { label: getOrderStatusLabel('production'), value: 'production' },
  { label: getOrderStatusLabel('shipped'), value: 'shipped' },
  { label: getOrderStatusLabel('completed'), value: 'completed' },
  { label: getOrderStatusLabel('cancelled'), value: 'cancelled' }
]

// 分页配置
const pagination = computed<PaginationProps>(() => ({
  page: orderStore.pagination.page,
  pageSize: orderStore.pagination.pageSize,
  pageCount: Math.ceil(orderStore.pagination.total / orderStore.pagination.pageSize),
  itemCount: orderStore.pagination.total,
  showSizePicker: true,
  pageSizes: [10, 20, 50, 100],
  onChange: (page: number) => {
    orderStore.pagination.page = page
    loadOrders()
  },
  onUpdatePageSize: (pageSize: number) => {
    orderStore.pagination.pageSize = pageSize
    orderStore.pagination.page = 1
    loadOrders()
  }
}))

// 表格列定义
const columns = computed<DataTableColumns<Order>>(() => [
  {
    title: '订单号',
    key: 'order_no',
    width: 150,
    ellipsis: { tooltip: true }
  },
  {
    title: '客户',
    key: 'customer',
    width: 180,
    ellipsis: { tooltip: true },
    render: (row: Order) => row.customer?.company || '-'
  },
  {
    title: '产品',
    key: 'product',
    ellipsis: { tooltip: true },
    render: (row: Order) => row.product || '-'
  },
  {
    title: '利润 (USD)',
    key: 'profit',
    width: 120,
    align: 'right',
    render: (row: Order) => row.profit ? `$${row.profit.toFixed(2)}` : '-'
  },
  {
    title: '状态',
    key: 'status',
    width: 100,
    render: (row: Order) => h(
      NTag,
      { type: getOrderStatusType(row.status), size: 'small' },
      { default: () => getOrderStatusLabel(row.status) }
    )
  },
  {
    title: '创建日期',
    key: 'create_date',
    width: 120,
    render: (row: Order) => formatDate(row.create_date)
  },
  {
    title: '操作',
    key: 'actions',
    width: 80,
    align: 'center',
    render: (row: Order) => h(
      NDropdown,
      {
        trigger: 'click',
        options: [
          {
            label: '编辑',
            key: 'edit',
            icon: () => h(NIcon, null, { default: () => h(CreateOutline) })
          },
          {
            label: '删除',
            key: 'delete',
            icon: () => h(NIcon, null, { default: () => h(TrashOutline) })
          }
        ],
        onSelect: (key: string) => handleAction(key, row)
      },
      {
        default: () => h(
          NButton,
          { text: true, size: 'small' },
          { icon: () => h(NIcon, { size: 20 }, { default: () => h(EllipsisHorizontalOutline) }) }
        )
      }
    )
  }
])

// 获取各状态订单数量
function getStatusCount(status: string): number {
  return orderStore.orders.filter((order: Order) => order.status === status).length
}

// 获取总利润
function getTotalProfit(): number {
  return orderStore.orders.reduce((sum: number, order: Order) => sum + (order.profit || 0), 0)
}

// 加载订单列表
async function loadOrders() {
  try {
    await orderStore.fetchOrders(filters.value)
  } catch (error: any) {
    message.error('加载订单失败：' + error.message)
  }
}

// 搜索（防抖）
const handleSearch = debounce(() => {
  orderStore.pagination.page = 1
  loadOrders()
}, 300)

// 日期范围变化
function handleDateChange(value: [number, number] | null) {
  if (value) {
    filters.value.date_from = new Date(value[0]).toISOString().split('T')[0]
    filters.value.date_to = new Date(value[1]).toISOString().split('T')[0]
  } else {
    filters.value.date_from = ''
    filters.value.date_to = ''
  }
  handleSearch()
}

// 新增订单
function handleAdd() {
  selectedOrder.value = null
  showFormModal.value = true
}

// 刷新
function handleRefresh() {
  loadOrders()
}

// 操作处理
function handleAction(action: string, order: Order) {
  if (action === 'edit') {
    selectedOrder.value = order
    showFormModal.value = true
  } else if (action === 'delete') {
    handleDelete(order)
  }
}

// 删除订单
function handleDelete(order: Order) {
  dialog.warning({
    title: '确认删除',
    content: `确定要删除订单 "${order.order_no}" 吗？此操作不可恢复。`,
    positiveText: '删除',
    negativeText: '取消',
    onPositiveClick: async () => {
      const error = await orderStore.deleteOrder(order.id)
      if (error) {
        message.error('删除失败：' + error.message)
      } else {
        message.success('订单已删除')
        loadOrders()
      }
    }
  })
}

// 操作成功后刷新
function handleSuccess() {
  loadOrders()
}

onMounted(() => {
  loadOrders()
  // 加载客户列表用于筛选
  if (customerStore.customers.length === 0) {
    customerStore.fetchCustomers()
  }
})
</script>

<style scoped>
.orders-view {
  height: 100%;
  overflow-y: auto;
}

:deep(.n-statistic) {
  text-align: center;
  padding: 16px;
  background: #fafafa;
  border-radius: 8px;
}

:deep(.n-data-table) {
  margin-top: 8px;
}
</style>
