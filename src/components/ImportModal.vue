<template>
  <n-modal
    v-model:show="showModal"
    :mask-closable="false"
    preset="card"
    title="导入客户数据"
    style="width: 900px;"
  >
    <n-steps :current="currentStep" :status="stepStatus">
      <n-step title="上传文件" />
      <n-step title="列映射" />
      <n-step title="预览确认" />
      <n-step title="导入结果" />
    </n-steps>

    <n-divider />

    <!-- 步骤 1: 上传文件 -->
    <div v-if="currentStep === 1" class="step-content">
      <n-upload
        :custom-request="handleFileUpload"
        :show-file-list="false"
        accept=".xlsx,.xls,.csv"
      >
        <n-upload-dragger>
          <div style="margin-bottom: 12px;">
            <n-icon size="48" :depth="3">
              <CloudUploadOutline />
            </n-icon>
          </div>
          <n-text style="font-size: 16px;">
            点击或拖拽文件到此区域上传
          </n-text>
          <n-p depth="3" style="margin: 8px 0 0 0;">
            支持 .xlsx, .xls, .csv 格式，单个文件不超过 10MB
          </n-p>
        </n-upload-dragger>
      </n-upload>

      <n-divider />

      <n-alert type="info" title="导入说明">
        <ul>
          <li>支持 Excel (.xlsx, .xls) 和 CSV 格式</li>
          <li>第一行应为列标题</li>
          <li>必填字段：公司名称、联系人、国家、产品、询盘日期</li>
          <li>下载 <a href="#" @click.prevent="downloadTemplate">导入模板</a> 查看格式</li>
        </ul>
      </n-alert>
    </div>

    <!-- 步骤 2: 列映射 -->
    <div v-if="currentStep === 2" class="step-content">
      <n-alert type="info" title="列映射" style="margin-bottom: 16px;">
        请将 Excel 列名映射到系统字段
      </n-alert>

      <n-form label-placement="left" label-width="120px">
        <n-form-item
          v-for="field in systemFields"
          :key="field.key"
          :label="field.label"
          :required="field.required"
        >
          <n-select
            v-model:value="columnMapping[field.key]"
            :options="excelColumns"
            placeholder="选择对应的 Excel 列"
            clearable
          />
        </n-form-item>
      </n-form>
    </div>

    <!-- 步骤 3: 预览确认 -->
    <div v-if="currentStep === 3" class="step-content">
      <n-alert type="warning" title="数据预览" style="margin-bottom: 16px;">
        共 {{ previewData.length }} 条数据，请确认无误后导入
      </n-alert>

      <n-data-table
        :columns="previewColumns"
        :data="previewData.slice(0, 10)"
        :max-height="400"
        :pagination="false"
      />

      <n-p v-if="previewData.length > 10" depth="3" style="margin-top: 8px;">
        仅显示前 10 条数据预览
      </n-p>
    </div>

    <!-- 步骤 4: 导入结果 -->
    <div v-if="currentStep === 4" class="step-content">
      <n-result
        :status="importResult.failed === 0 ? 'success' : 'warning'"
        :title="importResult.failed === 0 ? '导入完成' : '导入完成（部分失败）'"
      >
        <template #footer>
          <n-space vertical>
            <n-statistic label="成功" :value="importResult.success" />
            <n-statistic label="失败" :value="importResult.failed" />

            <n-collapse v-if="importResult.errors.length > 0">
              <n-collapse-item title="查看错误详情" name="errors">
                <n-list>
                  <n-list-item v-for="error in importResult.errors" :key="error.index">
                    第 {{ error.index + 1 }} 行: {{ error.error }}
                  </n-list-item>
                </n-list>
              </n-collapse-item>
            </n-collapse>
          </n-space>
        </template>
      </n-result>
    </div>

    <template #footer>
      <n-space justify="end">
        <n-button v-if="currentStep > 1 && currentStep < 4" @click="handlePrev">
          上一步
        </n-button>
        <n-button v-if="currentStep < 3" type="primary" :disabled="!canNext" @click="handleNext">
          下一步
        </n-button>
        <n-button
          v-if="currentStep === 3"
          type="primary"
          :loading="importing"
          @click="handleImport"
        >
          开始导入
        </n-button>
        <n-button v-if="currentStep === 4" type="primary" @click="handleClose">
          完成
        </n-button>
        <n-button @click="handleClose">取消</n-button>
      </n-space>
    </template>
  </n-modal>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import {
  NModal,
  NSteps,
  NStep,
  NDivider,
  NUpload,
  NUploadDragger,
  NIcon,
  NText,
  NP,
  NAlert,
  NForm,
  NFormItem,
  NSelect,
  NDataTable,
  NResult,
  NStatistic,
  NCollapse,
  NCollapseItem,
  NList,
  NListItem,
  NSpace,
  NButton,
  useMessage,
  type UploadCustomRequestOptions
} from 'naive-ui'
import { CloudUploadOutline } from '@vicons/ionicons5'
import { read, utils, writeFile } from 'xlsx'
import { useCustomerStore } from '@/stores/customer'

interface Props {
  show: boolean
}

const props = defineProps<Props>()
const emit = defineEmits<{
  (e: 'update:show', value: boolean): void
  (e: 'success'): void
}>()

const message = useMessage()
const customerStore = useCustomerStore()

const showModal = computed({
  get: () => props.show,
  set: val => emit('update:show', val)
})

const currentStep = ref(1)
const stepStatus = ref<'process' | 'finish' | 'error' | 'wait'>('process')
const importing = ref(false)

const excelData = ref<any[]>([])
const excelColumns = ref<Array<{ label: string; value: string }>>([])
const columnMapping = ref<Record<string, string>>({})
const previewData = ref<any[]>([])

const importResult = ref({
  success: 0,
  failed: 0,
  errors: [] as Array<{ index: number; error: string }>
})

const systemFields = [
  { key: 'code', label: '客户单号', required: true },
  { key: 'company', label: '公司名称', required: true },
  { key: 'contact', label: '联系人', required: true },
  { key: 'country', label: '国家/地区', required: true },
  { key: 'product', label: '产品', required: true },
  { key: 'inquiry_date', label: '询盘日期', required: true },
  { key: 'email', label: '邮箱', required: false },
  { key: 'phone', label: '电话', required: false },
  { key: 'source', label: '客户来源', required: false },
  { key: 'remark', label: '备注', required: false }
]

const previewColumns = computed(() => [
  { title: '公司', key: 'company' },
  { title: '联系人', key: 'contact' },
  { title: '国家', key: 'country' },
  { title: '产品', key: 'product' },
  { title: '邮箱', key: 'email' },
  { title: '询盘日期', key: 'inquiry_date' }
])

const canNext = computed(() => {
  if (currentStep.value === 1) {
    return excelData.value.length > 0
  }
  if (currentStep.value === 2) {
    const requiredFields = systemFields.filter(f => f.required)
    return requiredFields.every(f => columnMapping.value[f.key])
  }
  return true
})

async function handleFileUpload(options: UploadCustomRequestOptions) {
  const { file } = options
  try {
    const data = await file.file?.arrayBuffer()
    if (!data) {
      throw new Error('文件读取失败')
    }

    const workbook = read(data)
    const firstSheet = workbook.Sheets[workbook.SheetNames[0]]
    const jsonData = utils.sheet_to_json(firstSheet, { raw: false })

    if (jsonData.length === 0) {
      throw new Error('文件中没有数据')
    }

    excelData.value = jsonData as any[]

    // 提取列名
    const columns = Object.keys(jsonData[0] as object)
    excelColumns.value = columns.map(col => ({ label: col, value: col }))

    // 自动映射（如果列名匹配）
    systemFields.forEach(field => {
      const matchedCol = columns.find(col =>
        col.toLowerCase().includes(field.label.toLowerCase())
      )
      if (matchedCol) {
        columnMapping.value[field.key] = matchedCol
      }
    })

    message.success('文件上传成功')
    currentStep.value = 2
  } catch (error: any) {
    message.error('文件解析失败：' + error.message)
  }
}

function handleNext() {
  if (currentStep.value === 2) {
    // 生成预览数据
    previewData.value = excelData.value.map(row => {
      const mapped: any = {}
      Object.entries(columnMapping.value).forEach(([sysField, excelCol]) => {
        if (excelCol) {
          mapped[sysField] = row[excelCol]
        }
      })
      return mapped
    })
  }
  currentStep.value++
}

function handlePrev() {
  currentStep.value--
}

async function handleImport() {
  importing.value = true
  try {
    const customers = previewData.value.map(data => ({
      ...data,
      status: 'new',
      source: data.source || 'other',
      is_entered: false
    }))

    const result = await customerStore.importCustomers(customers)
    importResult.value = result

    currentStep.value = 4
    stepStatus.value = result.failed === 0 ? 'finish' : 'error'

    if (result.failed === 0) {
      message.success(`成功导入 ${result.success} 条数据`)
      emit('success')
    } else {
      message.warning(`导入完成：成功 ${result.success} 条，失败 ${result.failed} 条`)
    }
  } catch (error: any) {
    message.error('导入失败：' + error.message)
    stepStatus.value = 'error'
  } finally {
    importing.value = false
  }
}

function downloadTemplate() {
  const template = [
    {
      客户单号: 'CUS20240101001',
      公司名称: '示例公司 Inc.',
      联系人: '张三',
      '国家/地区': '美国',
      产品: '示例产品',
      询盘日期: '2024-01-01',
      邮箱: 'example@company.com',
      电话: '+1-234-567-8900',
      客户来源: 'website',
      备注: '这是一条示例数据'
    }
  ]

  const ws = utils.json_to_sheet(template)
  const wb = utils.book_new()
  utils.book_append_sheet(wb, ws, '客户导入模板')

  writeFile(wb, '客户导入模板.xlsx')
  message.success('模板下载成功')
}

function handleClose() {
  currentStep.value = 1
  stepStatus.value = 'process'
  excelData.value = []
  excelColumns.value = []
  columnMapping.value = {}
  previewData.value = []
  importResult.value = { success: 0, failed: 0, errors: [] }
  emit('update:show', false)
}
</script>

<style scoped>
.step-content {
  min-height: 400px;
  padding: 24px 0;
}
</style>
