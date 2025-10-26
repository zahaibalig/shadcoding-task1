import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authService } from '@/services/api'

export interface User {
  id: number
  username: string
  email?: string
  first_name?: string
  last_name?: string
}

export interface LoginCredentials {
  username: string
  password: string
}

export interface TokenResponse {
  access: string
  refresh: string
}

export const useAuthStore = defineStore('auth', () => {
  const user = ref<User | null>(null)
  const accessToken = ref<string | null>(localStorage.getItem('access_token'))
  const refreshToken = ref<string | null>(localStorage.getItem('refresh_token'))
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!accessToken.value)

  const login = async (credentials: LoginCredentials): Promise<boolean> => {
    loading.value = true
    error.value = null

    try {
      const tokens: TokenResponse = await authService.login(
        credentials.username,
        credentials.password
      )

      accessToken.value = tokens.access
      refreshToken.value = tokens.refresh

      // Save tokens to localStorage
      localStorage.setItem('access_token', tokens.access)
      localStorage.setItem('refresh_token', tokens.refresh)

      // Fetch user info
      await fetchUserInfo()

      return true
    } catch (err: any) {
      console.error('Login error:', err)
      error.value = err.response?.data?.detail || 'Login failed. Please check your credentials.'
      return false
    } finally {
      loading.value = false
    }
  }

  const fetchUserInfo = async () => {
    if (!accessToken.value) return

    try {
      const userInfo = await authService.getUserInfo(accessToken.value)
      user.value = userInfo
      localStorage.setItem('user', JSON.stringify(userInfo))
    } catch (err: any) {
      console.error('Failed to fetch user info:', err)
      // Don't logout on user info failure if we have a valid token
      // error.value = 'Failed to fetch user information'
    }
  }

  const logout = () => {
    user.value = null
    accessToken.value = null
    refreshToken.value = null
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    localStorage.removeItem('user')
  }

  const initialize = async () => {
    if (accessToken.value) {
      // Try to load user from localStorage first
      const storedUser = localStorage.getItem('user')
      if (storedUser) {
        try {
          user.value = JSON.parse(storedUser)
        } catch (e) {
          console.error('Failed to parse stored user:', e)
        }
      }

      // Then fetch fresh user info
      await fetchUserInfo()
    }
  }

  return {
    user,
    accessToken,
    refreshToken,
    loading,
    error,
    isAuthenticated,
    login,
    logout,
    fetchUserInfo,
    initialize,
  }
})
