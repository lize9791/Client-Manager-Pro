<template>
  <n-config-provider :theme-overrides="themeOverrides">
    <n-message-provider>
      <n-dialog-provider>
        <n-notification-provider>
          <router-view />
        </n-notification-provider>
      </n-dialog-provider>
    </n-message-provider>
  </n-config-provider>
</template>

<script setup lang="ts">
import { NConfigProvider, NMessageProvider, NDialogProvider, NNotificationProvider } from 'naive-ui'
import { onMounted } from 'vue'
import { supabase } from '@/utils/supabase'

const themeOverrides = {
  common: {
    primaryColor: '#18a058',
    primaryColorHover: '#36ad6a',
    primaryColorPressed: '#0c7a43',
    primaryColorSuppl: '#36ad6a'
  }
}

// 处理邮件确认回调中的 auth tokens
onMounted(() => {
  // Hash 路由模式下，auth tokens 会在 hash 中
  const hash = window.location.hash

  // 检查是否包含 access_token (邮件确认回调)
  if (hash.includes('access_token=')) {
    // Supabase 会自动处理 URL 中的 tokens
    // 监听 auth state change 事件
    const { data } = supabase.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN' && session) {
        console.log('User confirmed email and signed in')

        // 清理 URL 中的 token 参数，保持 URL 整洁
        // 但保留路由路径
        const cleanHash = hash.split('?')[0].split('&')[0]
        window.location.hash = cleanHash || '#/'
      }
    })

    // 清理监听器
    return () => {
      data.subscription.unsubscribe()
    }
  }
})
</script>

<style>
* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial,
    'Noto Sans', sans-serif, 'Apple Color Emoji', 'Segoe UI Emoji', 'Segoe UI Symbol',
    'Noto Color Emoji';
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

#app {
  width: 100%;
  height: 100vh;
  overflow: hidden;
}
</style>
