import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { supabase } from '@/utils/supabase'
import type { User, UserRole } from '@/types'
import type { AuthError, Session } from '@supabase/supabase-js'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const session = ref<Session | null>(null)
  const loading = ref(false)

  const isAuthenticated = computed(() => !!user.value)
  const userRole = computed<UserRole>(() => user.value?.role || 'viewer')
  const isAdmin = computed(() => userRole.value === 'admin')
  const isSales = computed(() => userRole.value === 'sales')
  const isViewer = computed(() => userRole.value === 'viewer')

  /**
   * 初始化认证状态
   */
  async function initialize() {
    loading.value = true
    try {
      const {
        data: { session: currentSession }
      } = await supabase.auth.getSession()

      if (currentSession) {
        session.value = currentSession
        await fetchUserProfile(currentSession.user.id)
      }

      // 监听认证状态变化
      supabase.auth.onAuthStateChange(async (_event, newSession) => {
        session.value = newSession
        if (newSession?.user) {
          await fetchUserProfile(newSession.user.id)
        } else {
          user.value = null
        }
      })
    } catch (error) {
      console.error('Failed to initialize auth:', error)
    } finally {
      loading.value = false
    }
  }

  /**
   * 获取用户资料
   */
  async function fetchUserProfile(userId: string) {
    try {
      const { data, error } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .maybeSingle()

      if (error) throw error

      // 如果用户记录不存在，自动创建
      if (!data) {
        const authUser = (await supabase.auth.getUser()).data.user
        if (authUser) {
          const newUser = {
            id: authUser.id,
            email: authUser.email!,
            name: authUser.user_metadata?.name || authUser.email!.split('@')[0],
            role: 'sales' as const
          }

          const { data: createdUser, error: createError } = await supabase
            .from('users')
            .insert(newUser)
            .select()
            .single()

          if (createError) {
            console.error('Failed to create user profile:', createError)
          } else {
            user.value = createdUser
          }
        }
      } else {
        user.value = data
      }
    } catch (error) {
      console.error('Failed to fetch user profile:', error)
    }
  }

  /**
   * 登录
   */
  async function signIn(email: string, password: string): Promise<AuthError | null> {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password
      })

      if (error) return error

      session.value = data.session
      if (data.user) {
        await fetchUserProfile(data.user.id)
      }

      return null
    } catch (error) {
      console.error('Sign in error:', error)
      return error as AuthError
    } finally {
      loading.value = false
    }
  }

  /**
   * 注册
   */
  async function signUp(
    email: string,
    password: string,
    name?: string
  ): Promise<AuthError | null> {
    loading.value = true
    try {
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: {
          data: {
            name
          },
          emailRedirectTo: window.location.origin + window.location.pathname
        }
      })

      if (error) return error

      // 创建用户资料（默认角色为 sales）
      if (data.user) {
        const { error: profileError } = await supabase.from('users').insert({
          id: data.user.id,
          email: data.user.email!,
          name: name || email.split('@')[0],
          role: 'sales'
        })

        if (profileError) {
          console.error('Failed to create user profile:', profileError)
        }
      }

      return null
    } catch (error) {
      console.error('Sign up error:', error)
      return error as AuthError
    } finally {
      loading.value = false
    }
  }

  /**
   * 登出
   */
  async function signOut() {
    loading.value = true
    try {
      await supabase.auth.signOut()
      user.value = null
      session.value = null
    } catch (error) {
      console.error('Sign out error:', error)
    } finally {
      loading.value = false
    }
  }

  /**
   * 更新用户资料
   */
  async function updateProfile(updates: Partial<User>): Promise<boolean> {
    if (!user.value) return false

    try {
      const { error } = await supabase
        .from('users')
        .update(updates)
        .eq('id', user.value.id)

      if (error) throw error

      user.value = { ...user.value, ...updates }
      return true
    } catch (error) {
      console.error('Update profile error:', error)
      return false
    }
  }

  return {
    user,
    session,
    loading,
    isAuthenticated,
    userRole,
    isAdmin,
    isSales,
    isViewer,
    initialize,
    signIn,
    signUp,
    signOut,
    updateProfile
  }
})
