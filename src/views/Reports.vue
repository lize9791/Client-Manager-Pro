<template>
  <div class="reports-view">
    <n-card title="统计报表">
      <n-empty description="报表功能开发中..." />
      <n-p depth="3">
        此页面将提供各类统计报表和数据分析功能。
      </n-p>
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { NCard, NEmpty, NP } from 'naive-ui'
</script>

<style scoped>
.reports-view {
  height: 100%;
}
</style>
