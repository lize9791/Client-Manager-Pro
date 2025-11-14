<template>
  <n-modal
    v-model:show="showModal"
    :mask-closable="false"
    preset="card"
    :title="isEdit ? '编辑客户' : '新增客户'"
    style="width: 800px;"
    @update:show="handleClose"
  >
    <n-form
      ref="formRef"
      :model="formData"
      :rules="rules"
      label-placement="left"
      label-width="100px"
      require-mark-placement="right-hanging"
    >
      <n-grid :cols="2" :x-gap="24">
        <n-form-item-gi label="客户单号" path="code">
          <n-input v-model:value="formData.code" placeholder="自动生成或手动输入" />
        </n-form-item-gi>

        <n-form-item-gi label="询盘日期" path="inquiry_date">
          <n-date-picker
            v-model:formatted-value="formData.inquiry_date"
            type="date"
            value-format="yyyy-MM-dd"
            style="width: 100%;"
          />
        </n-form-item-gi>

        <n-form-item-gi label="公司名称" path="company">
          <n-input v-model:value="formData.company" placeholder="请输入公司名称" />
        </n-form-item-gi>

        <n-form-item-gi label="联系人" path="contact">
          <n-input v-model:value="formData.contact" placeholder="请输入联系人姓名" />
        </n-form-item-gi>

        <n-form-item-gi label="国家/地区" path="country">
          <n-input v-model:value="formData.country" placeholder="如: 美国, 中国" />
        </n-form-item-gi>

        <n-form-item-gi label="产品" path="product">
          <n-input v-model:value="formData.product" placeholder="请输入产品名称" />
        </n-form-item-gi>

        <n-form-item-gi label="邮箱" path="email">
          <n-input v-model:value="formData.email" placeholder="请输入邮箱地址" />
        </n-form-item-gi>

        <n-form-item-gi label="电话" path="phone">
          <n-input v-model:value="formData.phone" placeholder="请输入电话号码" />
        </n-form-item-gi>

        <n-form-item-gi label="客户来源" path="source">
          <n-select v-model:value="formData.source" :options="sourceOptions" />
        </n-form-item-gi>

        <n-form-item-gi label="跟进方式" path="follow_method">
          <n-select v-model:value="formData.follow_method" :options="methodOptions" />
        </n-form-item-gi>

        <n-form-item-gi label="客户状态" path="status">
          <n-select v-model:value="formData.status" :options="statusOptions" />
        </n-form-item-gi>

        <n-form-item-gi label="是否录入" path="is_entered">
          <n-switch v-model:value="formData.is_entered" />
        </n-form-item-gi>
      </n-grid>

      <n-form-item label="备注" path="remark">
        <n-input
          v-model:value="formData.remark"
          type="textarea"
          placeholder="请输入备注信息"
          :rows="3"
        />
      </n-form-item>
    </n-form>

    <template #footer>
      <n-space justify="end">
        <n-button @click="handleClose">取消</n-button>
        <n-button type="primary" :loading="loading" @click="handleSubmit">
          {{ isEdit ? '保存' : '创建' }}
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
  NFormItemGi,
  NGrid,
  NInput,
  NSelect,
  NSwitch,
  NDatePicker,
  NButton,
  NSpace,
  useMessage,
  type FormInst,
  type FormRules
} from 'naive-ui'
import { useCustomerStore } from '@/stores/customer'
import type { Customer } from '@/types'
import { validateEmail, validatePhone } from '@/utils/helpers'

interface Props {
  show: boolean
  customer?: Customer | null
}

const props = withDefaults(defineProps<Props>(), {
  show: false,
  customer: null
})

const emit = defineEmits<{
  (e: 'update:show', value: boolean): void
  (e: 'success'): void
}>()

const message = useMessage()
const customerStore = useCustomerStore()

const formRef = ref<FormInst | null>(null)
const loading = ref(false)
const showModal = computed({
  get: () => props.show,
  set: val => emit('update:show', val)
})

const isEdit = computed(() => !!props.customer)

const formData = ref({
  code: '',
  inquiry_date: new Date().toISOString().split('T')[0],
  company: '',
  contact: '',
  country: '',
  product: '',
  email: '',
  phone: '',
  source: 'other' as any,
  follow_method: undefined as any,
  status: 'new' as any,
  is_entered: false,
  remark: ''
})

const sourceOptions = [
  { label: '网站', value: 'website' },
  { label: '邮件', value: 'email' },
  { label: '展会', value: 'exhibition' },
  { label: '转介绍', value: 'referral' },
  { label: '电话营销', value: 'cold_call' },
  { label: '社交媒体', value: 'social_media' },
  { label: '其他', value: 'other' }
]

const methodOptions = [
  { label: '邮件', value: 'email' },
  { label: '电话', value: 'phone' },
  { label: 'WhatsApp', value: 'whatsapp' },
  { label: '微信', value: 'wechat' },
  { label: '会议', value: 'meeting' },
  { label: '其他', value: 'other' }
]

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

const rules: FormRules = {
  code: { required: true, message: '请输入客户单号', trigger: 'blur' },
  inquiry_date: { required: true, message: '请选择询盘日期', trigger: 'blur' },
  company: { required: true, message: '请输入公司名称', trigger: 'blur' },
  contact: { required: true, message: '请输入联系人', trigger: 'blur' },
  country: { required: true, message: '请输入国家/地区', trigger: 'blur' },
  product: { required: true, message: '请输入产品', trigger: 'blur' },
  source: { required: true, message: '请选择客户来源', trigger: 'change' },
  status: { required: true, message: '请选择客户状态', trigger: 'change' },
  email: {
    validator: (rule, value) => {
      if (!value) return true
      return validateEmail(value)
    },
    message: '请输入有效的邮箱地址',
    trigger: 'blur'
  },
  phone: {
    validator: (rule, value) => {
      if (!value) return true
      return validatePhone(value)
    },
    message: '请输入有效的电话号码',
    trigger: 'blur'
  }
}

// 监听 customer 变化，填充表单
watch(
  () => props.customer,
  newCustomer => {
    if (newCustomer) {
      formData.value = {
        code: newCustomer.code,
        inquiry_date: newCustomer.inquiry_date,
        company: newCustomer.company,
        contact: newCustomer.contact,
        country: newCustomer.country,
        product: newCustomer.product,
        email: newCustomer.email || '',
        phone: newCustomer.phone || '',
        source: newCustomer.source,
        follow_method: newCustomer.follow_method,
        status: newCustomer.status,
        is_entered: newCustomer.is_entered,
        remark: newCustomer.remark || ''
      }
    } else {
      resetForm()
    }
  },
  { immediate: true }
)

function resetForm() {
  formData.value = {
    code: `CUS${Date.now()}`,
    inquiry_date: new Date().toISOString().split('T')[0],
    company: '',
    contact: '',
    country: '',
    product: '',
    email: '',
    phone: '',
    source: 'other',
    follow_method: undefined,
    status: 'new',
    is_entered: false,
    remark: ''
  }
}

async function handleSubmit() {
  if (!formRef.value) return

  try {
    await formRef.value.validate()
    loading.value = true

    if (isEdit.value && props.customer) {
      await customerStore.updateCustomer(props.customer.id, formData.value)
      message.success('客户更新成功')
    } else {
      await customerStore.createCustomer(formData.value)
      message.success('客户创建成功')
    }

    emit('success')
    handleClose()
  } catch (error: any) {
    if (error?.errorFields) {
      // 表单验证错误
      return
    }
    message.error(error?.message || '操作失败')
  } finally {
    loading.value = false
  }
}

function handleClose() {
  resetForm()
  formRef.value?.restoreValidation()
  emit('update:show', false)
}
</script>
