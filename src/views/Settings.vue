<template>
  <div class="settings-view">
    <n-card title="系统设置">
      <n-empty description="系统设置功能开发中..." />
      <n-p depth="3">
        此页面将提供用户管理、权限配置、系统参数等设置功能。
      </n-p>
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { NCard, NEmpty, NP } from 'naive-ui'
</script>

<style scoped>
.settings-view {
  height: 100%;
}
</style>
