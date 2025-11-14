<template>
  <n-layout has-sider style="height: 100vh">
    <n-layout-sider
      bordered
      collapse-mode="width"
      :collapsed-width="64"
      :width="240"
      :collapsed="collapsed"
      show-trigger
      @collapse="collapsed = true"
      @expand="collapsed = false"
    >
      <div class="logo">
        <h2 v-if="!collapsed">客户管理系统</h2>
        <h2 v-else>CRM</h2>
      </div>
      <n-menu
        :collapsed="collapsed"
        :collapsed-width="64"
        :collapsed-icon-size="22"
        :options="menuOptions"
        :value="activeKey"
        @update:value="handleMenuSelect"
      />
    </n-layout-sider>

    <n-layout>
      <n-layout-header bordered style="height: 64px; padding: 0 24px; display: flex; align-items: center; justify-content: space-between;">
        <div style="display: flex; align-items: center; gap: 16px;">
          <n-input
            v-model:value="searchKeyword"
            placeholder="搜索客户..."
            clearable
            style="width: 300px;"
            @keyup.enter="handleSearch"
          >
            <template #prefix>
              <n-icon :component="SearchOutline" />
            </template>
          </n-input>
          <n-button type="primary" @click="showAddCustomer = true">
            <template #icon>
              <n-icon :component="AddOutline" />
            </template>
            新增客户
          </n-button>
        </div>

        <div style="display: flex; align-items: center; gap: 16px;">
          <n-badge :value="reminders.length" :max="99">
            <n-button circle quaternary @click="showReminders = true">
              <template #icon>
                <n-icon :component="NotificationsOutline" />
              </template>
            </n-button>
          </n-badge>

          <n-dropdown :options="userMenuOptions" @select="handleUserMenuSelect">
            <n-button text style="font-size: 14px;">
              <template #icon>
                <n-icon :component="PersonCircleOutline" />
              </template>
              {{ authStore.user?.name || authStore.user?.email }}
            </n-button>
          </n-dropdown>
        </div>
      </n-layout-header>

      <n-layout-content content-style="padding: 24px;" :native-scrollbar="false">
        <router-view />
      </n-layout-content>
    </n-layout>

    <!-- 新增客户弹窗 -->
    <customer-form-modal v-model:show="showAddCustomer" @success="handleCustomerAdded" />

    <!-- 提醒抽屉 -->
    <n-drawer v-model:show="showReminders" :width="400" placement="right">
      <n-drawer-content title="待办提醒" closable>
        <n-empty v-if="reminders.length === 0" description="暂无待办提醒" />
        <n-list v-else>
          <n-list-item v-for="reminder in reminders" :key="reminder.id">
            <n-thing :title="reminder.customer?.company || '未知客户'">
              <template #description>
                <n-space vertical size="small">
                  <span>{{ reminder.content }}</span>
                  <n-tag size="small" type="warning">
                    提醒时间: {{ formatDate(reminder.remind_at!) }}
                  </n-tag>
                </n-space>
              </template>
            </n-thing>
          </n-list-item>
        </n-list>
      </n-drawer-content>
    </n-drawer>
  </n-layout>
</template>

<script setup lang="ts">
import { ref, computed, h, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import {
  NLayout,
  NLayoutSider,
  NLayoutHeader,
  NLayoutContent,
  NMenu,
  NInput,
  NButton,
  NIcon,
  NBadge,
  NDropdown,
  NDrawer,
  NDrawerContent,
  NList,
  NListItem,
  NThing,
  NSpace,
  NTag,
  NEmpty
} from 'naive-ui'
import {
  HomeOutline,
  PeopleOutline,
  DocumentTextOutline,
  StatsChartOutline,
  SettingsOutline,
  SearchOutline,
  AddOutline,
  NotificationsOutline,
  PersonCircleOutline,
  LogOutOutline
} from '@vicons/ionicons5'
import { useAuthStore } from '@/stores/auth'
import { useFollowupStore } from '@/stores/followup'
import { formatDate } from '@/utils/helpers'
import CustomerFormModal from '@/components/CustomerFormModal.vue'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const followupStore = useFollowupStore()

const collapsed = ref(false)
const searchKeyword = ref('')
const showAddCustomer = ref(false)
const showReminders = ref(false)
const reminders = ref<any[]>([])

const activeKey = computed(() => route.name as string)

const menuOptions = computed(() => {
  const options = [
    {
      label: '仪表盘',
      key: 'Dashboard',
      icon: () => h(NIcon, null, { default: () => h(HomeOutline) })
    },
    {
      label: '客户管理',
      key: 'Customers',
      icon: () => h(NIcon, null, { default: () => h(PeopleOutline) })
    },
    {
      label: '订单管理',
      key: 'Orders',
      icon: () => h(NIcon, null, { default: () => h(DocumentTextOutline) })
    },
    {
      label: '统计报表',
      key: 'Reports',
      icon: () => h(NIcon, null, { default: () => h(StatsChartOutline) })
    }
  ]

  if (authStore.isAdmin) {
    options.push({
      label: '系统设置',
      key: 'Settings',
      icon: () => h(NIcon, null, { default: () => h(SettingsOutline) })
    })
  }

  return options
})

const userMenuOptions = [
  {
    label: '退出登录',
    key: 'logout',
    icon: () => h(NIcon, null, { default: () => h(LogOutOutline) })
  }
]

function handleMenuSelect(key: string) {
  router.push({ name: key })
}

function handleSearch() {
  if (searchKeyword.value) {
    router.push({ name: 'Customers', query: { keyword: searchKeyword.value } })
  }
}

function handleUserMenuSelect(key: string) {
  if (key === 'logout') {
    authStore.signOut()
    router.push({ name: 'Login' })
  }
}

function handleCustomerAdded() {
  showAddCustomer.value = false
  if (route.name === 'Customers') {
    router.go(0) // 刷新页面
  }
}

async function loadReminders() {
  reminders.value = await followupStore.fetchPendingReminders()
}

onMounted(() => {
  loadReminders()
  // 每5分钟刷新一次提醒
  setInterval(loadReminders, 5 * 60 * 1000)
})
</script>

<style scoped>
.logo {
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
  border-bottom: 1px solid #f0f0f0;
}

.logo h2 {
  font-size: 18px;
  font-weight: 600;
  color: #18a058;
  margin: 0;
}
</style>
