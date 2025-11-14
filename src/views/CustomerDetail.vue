<template>
  <div class="customer-detail-view">
    <n-spin :show="customerStore.loading">
      <n-space vertical size="large">
        <!-- 返回按钮 -->
        <n-button text @click="router.back()">
          <template #icon>
            <n-icon :component="ArrowBackOutline" />
          </template>
          返回
        </n-button>

        <!-- 客户基本信息 -->
        <n-card v-if="customer" title="客户信息">
          <template #header-extra>
            <n-space>
              <n-button @click="handleEdit">编辑</n-button>
              <n-button type="error" @click="handleDelete">删除</n-button>
            </n-space>
          </template>

          <n-descriptions :column="3" bordered>
            <n-descriptions-item label="客户单号">{{ customer.code }}</n-descriptions-item>
            <n-descriptions-item label="公司">{{ customer.company }}</n-descriptions-item>
            <n-descriptions-item label="联系人">{{ customer.contact }}</n-descriptions-item>
            <n-descriptions-item label="国家">{{ customer.country }}</n-descriptions-item>
            <n-descriptions-item label="产品">{{ customer.product }}</n-descriptions-item>
            <n-descriptions-item label="状态">
              <n-tag :type="getStatusType(customer.status)">
                {{ getStatusLabel(customer.status) }}
              </n-tag>
            </n-descriptions-item>
            <n-descriptions-item label="邮箱">{{ customer.email || '-' }}</n-descriptions-item>
            <n-descriptions-item label="电话">{{ customer.phone || '-' }}</n-descriptions-item>
            <n-descriptions-item label="来源">
              {{ getSourceLabel(customer.source) }}
            </n-descriptions-item>
            <n-descriptions-item label="询盘日期">
              {{ formatDate(customer.inquiry_date) }}
            </n-descriptions-item>
            <n-descriptions-item label="负责人">
              {{ customer.owner?.name || customer.owner?.email }}
            </n-descriptions-item>
            <n-descriptions-item label="是否录入">
              <n-switch :value="customer.is_entered" disabled />
            </n-descriptions-item>
            <n-descriptions-item label="备注" :span="3">
              {{ customer.remark || '-' }}
            </n-descriptions-item>
          </n-descriptions>
        </n-card>

        <!-- 订单列表 -->
        <n-card title="订单列表">
          <template #header-extra>
            <n-button type="primary" @click="showAddOrder = true">新增订单</n-button>
          </template>

          <n-empty v-if="!customer?.orders || customer.orders.length === 0" description="暂无订单" />
          <n-data-table v-else :columns="orderColumns" :data="customer.orders" :pagination="false" />
        </n-card>

        <!-- 跟进记录 -->
        <n-card title="跟进记录">
          <template #header-extra>
            <n-button type="primary" @click="showAddFollowup = true">添加跟进</n-button>
          </template>

          <n-empty
            v-if="!customer?.followups || customer.followups.length === 0"
            description="暂无跟进记录"
          />
          <n-timeline v-else>
            <n-timeline-item
              v-for="followup in customer.followups"
              :key="followup.id"
              :title="formatDate(followup.follow_date)"
              :type="getFollowupType(followup.method)"
            >
              <template #header>
                <n-space>
                  <span>{{ formatDate(followup.follow_date) }}</span>
                  <n-tag size="small" :type="getFollowupType(followup.method)">
                    {{ getMethodLabel(followup.method) }}
                  </n-tag>
                </n-space>
              </template>
              <p>{{ followup.content }}</p>
              <p v-if="followup.next_plan">
                <strong>下一步计划：</strong>{{ followup.next_plan }}
              </p>
              <n-text depth="3">
                跟进人：{{ followup.follower?.name || followup.follower?.email }}
              </n-text>
            </n-timeline-item>
          </n-timeline>
        </n-card>
      </n-space>
    </n-spin>

    <!-- 编辑客户 -->
    <customer-form-modal
      v-model:show="showEdit"
      :customer="customer"
      @success="handleUpdateSuccess"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  NSpin,
  NSpace,
  NButton,
  NIcon,
  NCard,
  NDescriptions,
  NDescriptionsItem,
  NTag,
  NSwitch,
  NEmpty,
  NDataTable,
  NTimeline,
  NTimelineItem,
  NText,
  useDialog,
  useMessage,
  type DataTableColumns
} from 'naive-ui'
import { ArrowBackOutline } from '@vicons/ionicons5'
import { useCustomerStore } from '@/stores/customer'
import { formatDate, getStatusLabel, getStatusType, getMethodLabel, getSourceLabel } from '@/utils/helpers'
import type { Customer, Order } from '@/types'
import CustomerFormModal from '@/components/CustomerFormModal.vue'

const router = useRouter()
const route = useRoute()
const dialog = useDialog()
const message = useMessage()
const customerStore = useCustomerStore()

const customer = ref<Customer | null>(null)
const showEdit = ref(false)
const showAddOrder = ref(false)
const showAddFollowup = ref(false)

const orderColumns: DataTableColumns<Order> = [
  { title: '订单号', key: 'order_no' },
  { title: '产品', key: 'product' },
  { title: '利润', key: 'profit' },
  { title: '状态', key: 'status' },
  { title: '创建日期', key: 'create_date', render: row => formatDate(row.create_date) }
]

function getFollowupType(method: string): 'success' | 'info' | 'warning' | 'error' {
  const map: Record<string, any> = {
    email: 'info',
    phone: 'success',
    whatsapp: 'success',
    wechat: 'success',
    meeting: 'warning',
    other: 'default'
  }
  return map[method] || 'default'
}

function handleEdit() {
  showEdit.value = true
}

function handleDelete() {
  if (!customer.value) return

  dialog.warning({
    title: '确认删除',
    content: `确定要删除客户 "${customer.value.company}" 吗？此操作不可恢复。`,
    positiveText: '删除',
    negativeText: '取消',
    onPositiveClick: async () => {
      try {
        await customerStore.deleteCustomer(customer.value!.id)
        message.success('删除成功')
        router.push({ name: 'Customers' })
      } catch (error: any) {
        message.error(error?.message || '删除失败')
      }
    }
  })
}

async function handleUpdateSuccess() {
  showEdit.value = false
  await loadCustomer()
}

async function loadCustomer() {
  const id = route.params.id as string
  customer.value = await customerStore.fetchCustomerById(id)

  if (!customer.value) {
    message.error('客户不存在')
    router.push({ name: 'Customers' })
  }
}

onMounted(() => {
  loadCustomer()
})
</script>

<style scoped>
.customer-detail-view {
  height: 100%;
  overflow-y: auto;
}
</style>
