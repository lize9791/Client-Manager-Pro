<template>
  <div class="customers-view">
    <n-card title="客户管理">
      <template #header-extra>
        <n-space>
          <n-button type="primary" @click="showAddModal = true">新增客户</n-button>
          <n-button @click="showImportModal = true">导入</n-button>
          <n-button @click="handleExport">导出</n-button>
        </n-space>
      </template>

      <!-- 筛选条件 -->
      <n-space vertical size="large">
        <n-space>
          <n-input
            v-model:value="filters.keyword"
            placeholder="搜索公司/联系人/邮箱/电话/单号"
            clearable
            style="width: 300px;"
            @update:value="handleSearch"
          >
            <template #prefix>
              <n-icon :component="SearchOutline" />
            </template>
          </n-input>

          <n-select
            v-model:value="filters.status"
            placeholder="状态"
            clearable
            style="width: 150px;"
            :options="statusOptions"
            @update:value="handleFilterChange"
          />

          <n-select
            v-model:value="filters.source"
            placeholder="来源"
            clearable
            style="width: 150px;"
            :options="sourceOptions"
            @update:value="handleFilterChange"
          />

          <n-input
            v-model:value="filters.country"
            placeholder="国家"
            clearable
            style="width: 150px;"
            @update:value="handleSearch"
          />

          <n-select
            v-model:value="filters.is_entered"
            placeholder="是否录入"
            clearable
            style="width: 150px;"
            :options="isEnteredOptions"
            @update:value="handleFilterChange"
          />
        </n-space>

        <!-- 数据表格 -->
        <n-data-table
          :columns="columns"
          :data="customerStore.customers"
          :loading="customerStore.loading"
          :pagination="paginationConfig"
          :row-key="(row: Customer) => row.id"
          @update:page="handlePageChange"
        />
      </n-space>
    </n-card>

    <!-- 新增/编辑客户弹窗 -->
    <customer-form-modal
      v-model:show="showAddModal"
      :customer="editingCustomer"
      @success="handleModalSuccess"
    />

    <!-- 导入弹窗 -->
    <import-modal v-model:show="showImportModal" @success="loadCustomers" />
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted, h } from 'vue'
import { useRouter } from 'vue-router'
import {
  NCard,
  NSpace,
  NButton,
  NInput,
  NSelect,
  NDataTable,
  NIcon,
  NTag,
  NSwitch,
  NDropdown,
  useDialog,
  useMessage,
  type DataTableColumns
} from 'naive-ui'
import { SearchOutline, EllipsisVerticalOutline } from '@vicons/ionicons5'
import { useCustomerStore } from '@/stores/customer'
import type { Customer, CustomerFilter } from '@/types'
import { formatDate, debounce } from '@/utils/helpers'
import CustomerFormModal from '@/components/CustomerFormModal.vue'
import ImportModal from '@/components/ImportModal.vue'

const router = useRouter()
const dialog = useDialog()
const message = useMessage()
const customerStore = useCustomerStore()

const showAddModal = ref(false)
const showImportModal = ref(false)
const editingCustomer = ref<Customer | null>(null)

const filters = reactive<CustomerFilter>({
  keyword: '',
  status: undefined,
  source: undefined,
  country: '',
  is_entered: undefined
})

const statusOptions = [
  { label: '样品已成交', value: 'sample_won' },
  { label: '洽谈中', value: 'negotiating' },
  { label: '排产中', value: 'in_production' },
  { label: '已完成', value: 'completed' },
  { label: '新一轮洽谈', value: 'new_round' },
  { label: '已被他人成交', value: 'won_by_others' },
  { label: '潜在客户', value: 'potential' },
  { label: '高价值客户', value: 'high_value' },
  { label: '无回复', value: 'no_response' },
  { label: '不可执行', value: 'not_executable' },
  { label: '低优先级', value: 'low_priority' }
]

const sourceOptions = [
  { label: '网站', value: 'website' },
  { label: '邮件', value: 'email' },
  { label: '展会', value: 'exhibition' },
  { label: '转介绍', value: 'referral' },
  { label: '电话营销', value: 'cold_call' },
  { label: '社交媒体', value: 'social_media' },
  { label: '其他', value: 'other' }
]

const isEnteredOptions = [
  { label: '已录入', value: true },
  { label: '未录入', value: false }
]

const columns: DataTableColumns<Customer> = [
  {
    title: '单号',
    key: 'code',
    width: 150,
    fixed: 'left',
    render: row => h('a', { onClick: () => handleView(row) }, row.code)
  },
  {
    title: '公司',
    key: 'company',
    width: 200,
    ellipsis: { tooltip: true }
  },
  {
    title: '联系人',
    key: 'contact',
    width: 120
  },
  {
    title: '国家',
    key: 'country',
    width: 100
  },
  {
    title: '产品',
    key: 'product',
    width: 150,
    ellipsis: { tooltip: true }
  },
  {
    title: '状态',
    key: 'status',
    width: 120,
    render: row => {
      const statusMap: Record<string, { type: any; label: string }> = {
        sample_won: { type: 'success', label: '样品已成交' },
        negotiating: { type: 'info', label: '洽谈中' },
        in_production: { type: 'warning', label: '排产中' },
        completed: { type: 'success', label: '已完成' },
        new_round: { type: 'info', label: '新一轮洽谈' },
        won_by_others: { type: 'error', label: '已被他人成交' },
        potential: { type: 'default', label: '潜在客户' },
        high_value: { type: 'success', label: '高价值客户' },
        no_response: { type: 'warning', label: '无回复' },
        not_executable: { type: 'error', label: '不可执行' },
        low_priority: { type: 'default', label: '低优先级' }
      }
      const { type, label } = statusMap[row.status] || { type: 'default', label: row.status }
      return h(NTag, { type, size: 'small' }, { default: () => label })
    }
  },
  {
    title: '是否录入',
    key: 'is_entered',
    width: 100,
    render: row => h(NSwitch, { value: row.is_entered, disabled: true })
  },
  {
    title: '询盘日期',
    key: 'inquiry_date',
    width: 120,
    render: row => formatDate(row.inquiry_date)
  },
  {
    title: '负责人',
    key: 'owner',
    width: 120,
    render: row => row.owner?.name || row.owner?.email || '-'
  },
  {
    title: '操作',
    key: 'actions',
    width: 80,
    fixed: 'right',
    render: row => {
      return h(
        NDropdown,
        {
          options: [
            { label: '查看', key: 'view' },
            { label: '编辑', key: 'edit' },
            { label: '删除', key: 'delete' }
          ],
          onSelect: (key: string) => handleAction(key, row)
        },
        {
          default: () =>
            h(
              NButton,
              { text: true },
              { icon: () => h(NIcon, null, { default: () => h(EllipsisVerticalOutline) }) }
            )
        }
      )
    }
  }
]

const paginationConfig = computed(() => ({
  page: customerStore.pagination.page,
  pageSize: customerStore.pagination.pageSize,
  pageCount: Math.ceil(customerStore.pagination.total / customerStore.pagination.pageSize),
  showSizePicker: true,
  pageSizes: [10, 20, 50, 100],
  onChange: (page: number) => handlePageChange(page),
  onUpdatePageSize: (pageSize: number) => handlePageSizeChange(pageSize)
}))

const handleSearch = debounce(() => {
  loadCustomers()
}, 500)

function handleFilterChange() {
  loadCustomers()
}

async function loadCustomers(page?: number) {
  try {
    await customerStore.fetchCustomers(
      filters,
      page || customerStore.pagination.page,
      customerStore.pagination.pageSize
    )
  } catch (error: any) {
    message.error(error?.message || '加载客户列表失败')
  }
}

function handlePageChange(page: number) {
  loadCustomers(page)
}

function handlePageSizeChange(pageSize: number) {
  customerStore.pagination.pageSize = pageSize
  loadCustomers(1)
}

function handleView(customer: Customer) {
  router.push({ name: 'CustomerDetail', params: { id: customer.id } })
}

function handleAction(key: string, customer: Customer) {
  switch (key) {
    case 'view':
      handleView(customer)
      break
    case 'edit':
      editingCustomer.value = customer
      showAddModal.value = true
      break
    case 'delete':
      handleDelete(customer)
      break
  }
}

function handleDelete(customer: Customer) {
  dialog.warning({
    title: '确认删除',
    content: `确定要删除客户 "${customer.company}" 吗？此操作不可恢复。`,
    positiveText: '删除',
    negativeText: '取消',
    onPositiveClick: async () => {
      try {
        await customerStore.deleteCustomer(customer.id)
        message.success('删除成功')
        loadCustomers()
      } catch (error: any) {
        message.error(error?.message || '删除失败')
      }
    }
  })
}

function handleModalSuccess() {
  showAddModal.value = false
  editingCustomer.value = null
  loadCustomers()
}

async function handleExport() {
  try {
    // 导出当前筛选条件下的所有数据
    const { utils, writeFile } = await import('xlsx')

    const exportData = customerStore.customers.map(c => ({
      单号: c.code,
      公司: c.company,
      联系人: c.contact,
      国家: c.country,
      产品: c.product,
      邮箱: c.email,
      电话: c.phone,
      状态: c.status,
      来源: c.source,
      询盘日期: c.inquiry_date,
      是否录入: c.is_entered ? '是' : '否',
      备注: c.remark
    }))

    const ws = utils.json_to_sheet(exportData)
    const wb = utils.book_new()
    utils.book_append_sheet(wb, ws, '客户列表')

    const fileName = `customers_${new Date().toISOString().split('T')[0]}.xlsx`
    writeFile(wb, fileName)

    message.success('导出成功')
  } catch (error: any) {
    message.error('导出失败：' + error.message)
  }
}

onMounted(() => {
  loadCustomers()
})
</script>

<style scoped>
.customers-view {
  height: 100%;
}
</style>
