<template>
  <n-modal
    v-model:show="isVisible"
    preset="card"
    :title="isEditing ? '编辑订单' : '新增订单'"
    style="width: 600px;"
    :mask-closable="false"
  >
    <n-form
      ref="formRef"
      :model="formData"
      :rules="rules"
      label-placement="left"
      label-width="100"
      require-mark-placement="right-hanging"
    >
      <n-form-item label="客户" path="customer_id">
        <n-select
          v-model:value="formData.customer_id"
          :options="customerOptions"
          placeholder="请选择客户"
          filterable
          clearable
          @update:value="handleCustomerChange"
        />
      </n-form-item>

      <n-form-item label="订单号" path="order_no">
        <n-input
          v-model:value="formData.order_no"
          placeholder="自动生成或手动输入"
        />
      </n-form-item>

      <n-form-item label="产品" path="product">
        <n-input
          v-model:value="formData.product"
          placeholder="请输入产品名称"
          type="textarea"
          :autosize="{ minRows: 2, maxRows: 4 }"
        />
      </n-form-item>

      <n-form-item label="利润 (USD)" path="profit">
        <n-input-number
          v-model:value="formData.profit"
          placeholder="请输入利润金额"
          :min="0"
          :precision="2"
          style="width: 100%;"
        >
          <template #prefix>$</template>
        </n-input-number>
      </n-form-item>

      <n-form-item label="订单状态" path="status">
        <n-select
          v-model:value="formData.status"
          :options="statusOptions"
          placeholder="请选择订单状态"
        />
      </n-form-item>

      <n-form-item label="创建日期" path="create_date">
        <n-date-picker
          v-model:value="formData.create_date"
          type="date"
          clearable
          style="width: 100%;"
        />
      </n-form-item>

      <n-form-item label="备注" path="remark">
        <n-input
          v-model:value="formData.remark"
          placeholder="请输入备注信息"
          type="textarea"
          :autosize="{ minRows: 3, maxRows: 6 }"
        />
      </n-form-item>
    </n-form>

    <template #footer>
      <n-space justify="end">
        <n-button @click="handleCancel">取消</n-button>
        <n-button type="primary" :loading="loading" @click="handleSubmit">
          {{ isEditing ? '保存' : '创建' }}
        </n-button>
      </n-space>
    </template>
  </n-modal>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue'
import {
  NModal,
  NForm,
  NFormItem,
  NInput,
  NInputNumber,
  NSelect,
  NDatePicker,
  NButton,
  NSpace,
  useMessage,
  type FormInst,
  type FormRules
} from 'naive-ui'
import type { Order, Customer } from '@/types'
import { useOrderStore } from '@/stores/order'
import { useCustomerStore } from '@/stores/customer'
import { getOrderStatusLabel } from '@/utils/helpers'

interface Props {
  visible: boolean
  order?: Order | null
}

const props = withDefaults(defineProps<Props>(), {
  order: null
})

const emit = defineEmits<{
  (e: 'update:visible', value: boolean): void
  (e: 'success'): void
}>()

const message = useMessage()
const orderStore = useOrderStore()
const customerStore = useCustomerStore()

const formRef = ref<FormInst | null>(null)
const loading = ref(false)

const isEditing = computed(() => !!props.order)
const isVisible = computed({
  get: () => props.visible,
  set: (value) => emit('update:visible', value)
})

const formData = ref({
  customer_id: '',
  order_no: '',
  product: '',
  profit: 0,
  status: 'pending' as const,
  create_date: Date.now(),
  remark: ''
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

const rules: FormRules = {
  customer_id: [{ required: true, message: '请选择客户', trigger: 'change' }],
  order_no: [{ required: true, message: '请输入订单号', trigger: 'blur' }],
  product: [{ required: true, message: '请输入产品', trigger: 'blur' }],
  status: [{ required: true, message: '请选择订单状态', trigger: 'change' }],
  create_date: [{ required: true, type: 'number', message: '请选择创建日期', trigger: 'change' }]
}

// 客户选择变化时自动填充产品
function handleCustomerChange(customerId: string) {
  const customer = customerStore.customers.find((c: Customer) => c.id === customerId)
  if (customer && !isEditing.value) {
    formData.value.product = customer.product || ''
  }
}

// 生成订单号
function generateOrderNo(): string {
  const now = new Date()
  const year = now.getFullYear()
  const month = String(now.getMonth() + 1).padStart(2, '0')
  const day = String(now.getDate()).padStart(2, '0')
  const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0')
  return `ORD${year}${month}${day}${random}`
}

// 重置表单
function resetForm() {
  formData.value = {
    customer_id: '',
    order_no: generateOrderNo(),
    product: '',
    profit: 0,
    status: 'pending',
    create_date: Date.now(),
    remark: ''
  }
}

// 填充表单
function fillForm(order: Order) {
  formData.value = {
    customer_id: order.customer_id,
    order_no: order.order_no,
    product: order.product,
    profit: order.profit || 0,
    status: order.status,
    create_date: new Date(order.create_date).getTime(),
    remark: order.remark || ''
  }
}

// 提交表单
async function handleSubmit() {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    loading.value = true

    const orderData = {
      customer_id: formData.value.customer_id,
      order_no: formData.value.order_no,
      product: formData.value.product,
      profit: formData.value.profit,
      status: formData.value.status,
      create_date: new Date(formData.value.create_date).toISOString().split('T')[0],
      remark: formData.value.remark
    }

    let error
    if (isEditing.value && props.order) {
      error = await orderStore.updateOrder(props.order.id, orderData)
    } else {
      error = await orderStore.createOrder(orderData)
    }

    if (error) {
      message.error(error.message || '操作失败')
    } else {
      message.success(isEditing.value ? '订单已更新' : '订单已创建')
      emit('success')
      isVisible.value = false
    }
  } catch (e) {
    // 表单验证失败
  } finally {
    loading.value = false
  }
}

// 取消
function handleCancel() {
  isVisible.value = false
}

// 监听弹窗显示状态
watch(() => props.visible, (visible) => {
  if (visible) {
    if (props.order) {
      fillForm(props.order)
    } else {
      resetForm()
    }
    // 加载客户列表
    if (customerStore.customers.length === 0) {
      customerStore.fetchCustomers()
    }
  }
})
</script>
