<template>
  <div class="dashboard-view">
    <n-space vertical size="large">
      <!-- 统计卡片 - 现代化设计 -->
      <n-grid :cols="4" :x-gap="16">
        <n-gi>
          <div class="stat-card stat-card-1" @click="handleCardClick('customers')">
            <div class="stat-card-icon">
              <n-icon size="40">
                <PeopleOutline />
              </n-icon>
            </div>
            <div class="stat-card-content">
              <div class="stat-label">客户总数</div>
              <div class="stat-value">
                <CountUp :end-val="dashboardStore.stats.total_customers" />
              </div>
              <div class="stat-trend">
                <n-icon size="16"><TrendingUpOutline /></n-icon>
                <span>较昨日 +{{ dashboardStore.stats.today_new }}</span>
              </div>
            </div>
          </div>
        </n-gi>
        <n-gi>
          <div class="stat-card stat-card-2" @click="handleCardClick('today')">
            <div class="stat-card-icon">
              <n-icon size="40">
                <AddCircleOutline />
              </n-icon>
            </div>
            <div class="stat-card-content">
              <div class="stat-label">今日新增</div>
              <div class="stat-value">
                <CountUp :end-val="dashboardStore.stats.today_new" />
              </div>
              <div class="stat-trend">
                <n-icon size="16"><CalendarOutline /></n-icon>
                <span>{{ formatDate(new Date(), 'MM/DD') }}</span>
              </div>
            </div>
          </div>
        </n-gi>
        <n-gi>
          <div class="stat-card stat-card-3" @click="handleCardClick('week')">
            <div class="stat-card-icon">
              <n-icon size="40">
                <StatsChartOutline />
              </n-icon>
            </div>
            <div class="stat-card-content">
              <div class="stat-label">近7天新增</div>
              <div class="stat-value">
                <CountUp :end-val="dashboardStore.stats.last_7_days_new" />
              </div>
              <div class="stat-trend">
                <n-icon size="16"><TimeOutline /></n-icon>
                <span>过去一周</span>
              </div>
            </div>
          </div>
        </n-gi>
        <n-gi>
          <div class="stat-card stat-card-4" @click="handleCardClick('profit')">
            <div class="stat-card-icon">
              <n-icon size="40">
                <CashOutline />
              </n-icon>
            </div>
            <div class="stat-card-content">
              <div class="stat-label">总利润</div>
              <div class="stat-value">
                $<CountUp :end-val="dashboardStore.stats.total_profit" :decimals="2" />
              </div>
              <div class="stat-trend">
                <n-icon size="16"><TrendingUpOutline /></n-icon>
                <span>累计收益</span>
              </div>
            </div>
          </div>
        </n-gi>
      </n-grid>

      <!-- 快速统计 -->
      <n-grid :cols="3" :x-gap="16">
        <n-gi>
          <n-card title="客户状态分布" :bordered="false" class="chart-card">
            <div ref="statusChartRef" style="height: 280px;"></div>
          </n-card>
        </n-gi>
        <n-gi>
          <n-card title="客户来源分布" :bordered="false" class="chart-card">
            <div ref="sourceChartRef" style="height: 280px;"></div>
          </n-card>
        </n-gi>
        <n-gi>
          <n-card title="国家分布 TOP 10" :bordered="false" class="chart-card">
            <div ref="countryChartRef" style="height: 280px;"></div>
          </n-card>
        </n-gi>
      </n-grid>

      <!-- 最近动态 -->
      <n-grid :cols="2" :x-gap="16">
        <n-gi>
          <n-card title="近期跟进记录" :bordered="false" class="activity-card">
            <template #header-extra>
              <n-button text @click="$router.push('/customers')">
                查看更多
                <template #icon>
                  <n-icon><ArrowForwardOutline /></n-icon>
                </template>
              </n-button>
            </template>
            <n-empty v-if="dashboardStore.recentFollowups.length === 0" description="暂无跟进记录" />
            <n-list v-else hoverable>
              <n-list-item v-for="followup in dashboardStore.recentFollowups" :key="followup.id">
                <template #prefix>
                  <n-avatar round :style="{ backgroundColor: getRandomColor() }">
                    <n-icon><PersonOutline /></n-icon>
                  </n-avatar>
                </template>
                <n-thing :title="followup.customer?.company || '未知客户'">
                  <template #description>
                    <n-space size="small">
                      <n-tag size="small" :type="getMethodType(followup.method)">
                        {{ getMethodLabel(followup.method) }}
                      </n-tag>
                      <n-ellipsis style="max-width: 300px;">
                        {{ followup.content }}
                      </n-ellipsis>
                    </n-space>
                  </template>
                  <template #footer>
                    <n-text depth="3" style="font-size: 12px;">
                      <n-icon size="14"><TimeOutline /></n-icon>
                      {{ formatDate(followup.follow_date) }} - {{ followup.follower?.name || '未知' }}
                    </n-text>
                  </template>
                </n-thing>
              </n-list-item>
            </n-list>
          </n-card>
        </n-gi>
        <n-gi>
          <n-card title="待办提醒" :bordered="false" class="activity-card">
            <template #header-extra>
              <n-badge :value="dashboardStore.pendingReminders.length" :max="99">
                <n-icon size="20"><NotificationsOutline /></n-icon>
              </n-badge>
            </template>
            <n-empty v-if="dashboardStore.pendingReminders.length === 0" description="暂无待办提醒" />
            <n-list v-else hoverable>
              <n-list-item v-for="reminder in dashboardStore.pendingReminders" :key="reminder.id">
                <template #prefix>
                  <n-avatar round color="#f0a020">
                    <n-icon><AlarmOutline /></n-icon>
                  </n-avatar>
                </template>
                <n-thing :title="reminder.customer?.company || '未知客户'">
                  <template #description>
                    <n-ellipsis style="max-width: 300px;">
                      {{ reminder.next_plan }}
                    </n-ellipsis>
                  </template>
                  <template #footer>
                    <n-tag size="small" type="warning">
                      <template #icon>
                        <n-icon><AlarmOutline /></n-icon>
                      </template>
                      {{ formatDate(reminder.remind_at!) }}
                    </n-tag>
                  </template>
                </n-thing>
              </n-list-item>
            </n-list>
          </n-card>
        </n-gi>
      </n-grid>
    </n-space>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, nextTick, computed } from 'vue'
import {
  NSpace,
  NGrid,
  NGi,
  NCard,
  NIcon,
  NList,
  NListItem,
  NThing,
  NTag,
  NText,
  NEmpty,
  NButton,
  NBadge,
  NAvatar,
  NEllipsis,
  useMessage
} from 'naive-ui'
import {
  PeopleOutline,
  TrendingUpOutline,
  StatsChartOutline,
  CashOutline,
  AddCircleOutline,
  CalendarOutline,
  TimeOutline,
  ArrowForwardOutline,
  PersonOutline,
  NotificationsOutline,
  AlarmOutline
} from '@vicons/ionicons5'
import * as echarts from 'echarts'
import { useDashboardStore } from '@/stores/dashboard'
import { formatDate, getMethodLabel, getSourceLabel, getStatusLabel } from '@/utils/helpers'

const message = useMessage()
const dashboardStore = useDashboardStore()

const statusChartRef = ref<HTMLElement | null>(null)
const sourceChartRef = ref<HTMLElement | null>(null)
const countryChartRef = ref<HTMLElement | null>(null)

let statusChart: echarts.ECharts | null = null
let sourceChart: echarts.ECharts | null = null
let countryChart: echarts.ECharts | null = null

// 数字增长动画组件
const CountUp = {
  props: {
    endVal: { type: Number, default: 0 },
    decimals: { type: Number, default: 0 }
  },
  setup(props: any) {
    const displayValue = ref(0)

    const animateValue = () => {
      const duration = 1000
      const frameDuration = 1000 / 60
      const totalFrames = Math.round(duration / frameDuration)
      let frame = 0

      const counter = setInterval(() => {
        frame++
        const progress = frame / totalFrames
        const easeOutQuad = progress * (2 - progress)
        displayValue.value = props.endVal * easeOutQuad

        if (frame === totalFrames) {
          clearInterval(counter)
          displayValue.value = props.endVal
        }
      }, frameDuration)
    }

    onMounted(animateValue)

    const formattedValue = computed(() => {
      return displayValue.value.toFixed(props.decimals)
    })

    return { formattedValue }
  },
  template: '<span>{{ formattedValue }}</span>'
}

function getMethodType(method: string): 'success' | 'info' | 'warning' | 'error' | 'default' {
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

function getRandomColor(): string {
  const colors = ['#18a058', '#2080f0', '#f0a020', '#d03050', '#9333ea', '#06b6d4']
  return colors[Math.floor(Math.random() * colors.length)]
}

function handleCardClick(type: string) {
  // 可以添加点击卡片后的交互，比如跳转到相应页面
  console.log('Card clicked:', type)
}

function initStatusChart() {
  if (!statusChartRef.value) return

  statusChart = echarts.init(statusChartRef.value)

  const data = Object.entries(dashboardStore.stats.by_status).map(([name, value]) => ({
    name: getStatusLabel(name),
    value
  }))

  const option: echarts.EChartsOption = {
    tooltip: {
      trigger: 'item',
      formatter: '{b}: {c} ({d}%)'
    },
    legend: {
      bottom: 10,
      left: 'center',
      textStyle: { fontSize: 12 }
    },
    series: [
      {
        name: '客户状态',
        type: 'pie',
        radius: ['45%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 8,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 14,
            fontWeight: 'bold'
          },
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        },
        labelLine: {
          show: false
        },
        data
      }
    ]
  }

  statusChart.setOption(option)
}

function initSourceChart() {
  if (!sourceChartRef.value) return

  sourceChart = echarts.init(sourceChartRef.value)

  const data = Object.entries(dashboardStore.stats.by_source).map(([name, value]) => ({
    name: getSourceLabel(name),
    value
  }))

  const option: echarts.EChartsOption = {
    tooltip: {
      trigger: 'item',
      formatter: '{b}: {c} ({d}%)'
    },
    legend: {
      bottom: 10,
      left: 'center',
      textStyle: { fontSize: 12 }
    },
    series: [
      {
        name: '客户来源',
        type: 'pie',
        radius: ['45%', '70%'],
        avoidLabelOverlap: false,
        itemStyle: {
          borderRadius: 8,
          borderColor: '#fff',
          borderWidth: 2
        },
        label: {
          show: false
        },
        emphasis: {
          label: {
            show: true,
            fontSize: 14,
            fontWeight: 'bold'
          },
          itemStyle: {
            shadowBlur: 10,
            shadowOffsetX: 0,
            shadowColor: 'rgba(0, 0, 0, 0.5)'
          }
        },
        labelLine: {
          show: false
        },
        data
      }
    ]
  }

  sourceChart.setOption(option)
}

function initCountryChart() {
  if (!countryChartRef.value) return

  countryChart = echarts.init(countryChartRef.value)

  const sortedData = Object.entries(dashboardStore.stats.by_country)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10)

  const option: echarts.EChartsOption = {
    tooltip: {
      trigger: 'axis',
      axisPointer: {
        type: 'shadow'
      }
    },
    grid: {
      left: '3%',
      right: '4%',
      bottom: '3%',
      containLabel: true
    },
    xAxis: {
      type: 'value',
      boundaryGap: [0, 0.01],
      axisLine: { show: false },
      axisTick: { show: false },
      splitLine: {
        lineStyle: { color: '#f0f0f0' }
      }
    },
    yAxis: {
      type: 'category',
      data: sortedData.map(([name]) => name),
      axisLine: { show: false },
      axisTick: { show: false }
    },
    series: [
      {
        name: '客户数量',
        type: 'bar',
        data: sortedData.map(([, value]) => value),
        barWidth: 16,
        itemStyle: {
          borderRadius: [0, 8, 8, 0],
          color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
            { offset: 0, color: '#667eea' },
            { offset: 1, color: '#764ba2' }
          ])
        },
        emphasis: {
          itemStyle: {
            color: new echarts.graphic.LinearGradient(0, 0, 1, 0, [
              { offset: 0, color: '#764ba2' },
              { offset: 1, color: '#667eea' }
            ])
          }
        }
      }
    ]
  }

  countryChart.setOption(option)
}

async function loadData() {
  try {
    await dashboardStore.fetchStats()

    // 初始化图表
    await nextTick()
    initStatusChart()
    initSourceChart()
    initCountryChart()
  } catch (error: any) {
    message.error('加载数据失败：' + error.message)
  }
}

onMounted(() => {
  loadData()

  // 监听窗口大小变化
  window.addEventListener('resize', () => {
    statusChart?.resize()
    sourceChart?.resize()
    countryChart?.resize()
  })
})
</script>

<style scoped>
.dashboard-view {
  height: 100%;
  overflow-y: auto;
  padding: 4px;
}

/* 现代化统计卡片 */
.stat-card {
  position: relative;
  padding: 24px;
  border-radius: 16px;
  color: white;
  cursor: pointer;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06);
}

.stat-card::before {
  content: '';
  position: absolute;
  top: 0;
  right: 0;
  width: 120px;
  height: 120px;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 50%;
  transform: translate(40%, -40%);
  transition: all 0.3s ease;
}

.stat-card:hover {
  transform: translateY(-8px);
  box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
}

.stat-card:hover::before {
  transform: translate(40%, -40%) scale(1.2);
}

.stat-card-1 {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.stat-card-2 {
  background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);
}

.stat-card-3 {
  background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);
}

.stat-card-4 {
  background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);
}

.stat-card-icon {
  position: absolute;
  top: 20px;
  right: 20px;
  opacity: 0.3;
  animation: float 3s ease-in-out infinite;
}

@keyframes float {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-10px);
  }
}

.stat-card-content {
  position: relative;
  z-index: 1;
}

.stat-label {
  font-size: 14px;
  opacity: 0.9;
  margin-bottom: 8px;
  font-weight: 500;
}

.stat-value {
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 8px;
  line-height: 1.2;
}

.stat-trend {
  display: flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  opacity: 0.8;
}

/* 图表卡片 */
.chart-card {
  border-radius: 12px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
  transition: all 0.3s ease;
}

.chart-card:hover {
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  transform: translateY(-2px);
}

/* 活动卡片 */
.activity-card {
  border-radius: 12px;
  box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1);
}

.activity-card :deep(.n-card-header) {
  padding: 20px 24px 16px;
}

.activity-card :deep(.n-list-item) {
  padding: 16px 24px;
  transition: all 0.2s ease;
}

.activity-card :deep(.n-list-item:hover) {
  background: rgba(0, 0, 0, 0.02);
}
</style>
