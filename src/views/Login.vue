<template>
  <div class="login-container">
    <n-card class="login-card" title="客户管理系统" size="large">
      <n-tabs v-model:value="activeTab" size="large" animated>
        <n-tab-pane name="login" tab="登录">
          <n-form ref="loginFormRef" :model="loginForm" :rules="loginRules" size="large">
            <n-form-item path="email" label="邮箱">
              <n-input
                v-model:value="loginForm.email"
                placeholder="请输入邮箱"
                @keyup.enter="handleLogin"
              />
            </n-form-item>
            <n-form-item path="password" label="密码">
              <n-input
                v-model:value="loginForm.password"
                type="password"
                show-password-on="click"
                placeholder="请输入密码"
                @keyup.enter="handleLogin"
              />
            </n-form-item>
            <n-button type="primary" block size="large" :loading="loading" @click="handleLogin">
              登录
            </n-button>
          </n-form>
        </n-tab-pane>

        <n-tab-pane name="register" tab="注册">
          <n-form ref="registerFormRef" :model="registerForm" :rules="registerRules" size="large">
            <n-form-item path="name" label="姓名">
              <n-input v-model:value="registerForm.name" placeholder="请输入姓名" />
            </n-form-item>
            <n-form-item path="email" label="邮箱">
              <n-input v-model:value="registerForm.email" placeholder="请输入邮箱" />
            </n-form-item>
            <n-form-item path="password" label="密码">
              <n-input
                v-model:value="registerForm.password"
                type="password"
                show-password-on="click"
                placeholder="请输入密码（至少6位）"
              />
            </n-form-item>
            <n-form-item path="confirmPassword" label="确认密码">
              <n-input
                v-model:value="registerForm.confirmPassword"
                type="password"
                show-password-on="click"
                placeholder="请再次输入密码"
                @keyup.enter="handleRegister"
              />
            </n-form-item>
            <n-button type="primary" block size="large" :loading="loading" @click="handleRegister">
              注册
            </n-button>
          </n-form>
        </n-tab-pane>
      </n-tabs>
    </n-card>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { NCard, NTabs, NTabPane, NForm, NFormItem, NInput, NButton, useMessage } from 'naive-ui'
import type { FormInst, FormRules } from 'naive-ui'
import { useAuthStore } from '@/stores/auth'
import { validateEmail } from '@/utils/helpers'

const router = useRouter()
const message = useMessage()
const authStore = useAuthStore()

const activeTab = ref('login')
const loading = ref(false)

const loginFormRef = ref<FormInst | null>(null)
const loginForm = ref({
  email: '',
  password: ''
})

const registerFormRef = ref<FormInst | null>(null)
const registerForm = ref({
  name: '',
  email: '',
  password: '',
  confirmPassword: ''
})

const loginRules: FormRules = {
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    {
      validator: (rule, value) => validateEmail(value),
      message: '请输入有效的邮箱地址',
      trigger: 'blur'
    }
  ],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

const registerRules: FormRules = {
  name: [{ required: true, message: '请输入姓名', trigger: 'blur' }],
  email: [
    { required: true, message: '请输入邮箱', trigger: 'blur' },
    {
      validator: (rule, value) => validateEmail(value),
      message: '请输入有效的邮箱地址',
      trigger: 'blur'
    }
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' }
  ],
  confirmPassword: [
    { required: true, message: '请确认密码', trigger: 'blur' },
    {
      validator: (rule, value) => value === registerForm.value.password,
      message: '两次输入的密码不一致',
      trigger: 'blur'
    }
  ]
}

async function handleLogin() {
  if (!loginFormRef.value) return

  try {
    await loginFormRef.value.validate()
    loading.value = true

    const error = await authStore.signIn(loginForm.value.email, loginForm.value.password)

    if (error) {
      message.error(error.message || '登录失败')
    } else {
      // 等待用户状态加载完成
      let waitCount = 0
      while (!authStore.user && waitCount < 20) {
        await new Promise(resolve => setTimeout(resolve, 100))
        waitCount++
      }

      if (authStore.user) {
        message.success('登录成功')
        // 使用 replace 避免返回到登录页
        await router.replace({ name: 'Dashboard' })
      } else {
        message.error('登录失败：无法获取用户信息')
      }
    }
  } catch (e) {
    // 表单验证失败
  } finally {
    loading.value = false
  }
}

async function handleRegister() {
  if (!registerFormRef.value) return

  try {
    await registerFormRef.value.validate()
    loading.value = true

    const error = await authStore.signUp(
      registerForm.value.email,
      registerForm.value.password,
      registerForm.value.name
    )

    if (error) {
      message.error(error.message || '注册失败')
    } else {
      message.success('注册成功，请检查邮箱进行验证')
      activeTab.value = 'login'
      loginForm.value.email = registerForm.value.email
    }
  } catch (e) {
    // 表单验证失败
  } finally {
    loading.value = false
  }
}
</script>

<style scoped>
.login-container {
  width: 100%;
  height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.login-card {
  width: 450px;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
}
</style>
