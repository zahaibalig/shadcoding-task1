import axios, { type AxiosInstance, type InternalAxiosRequestConfig } from 'axios'
import type { Project } from '@/types/project'
import type { Vehicle } from '@/types/vehicle'

// API base URL - uses environment variable with fallback
// In production: Uses VITE_API_URL from .env.production
// In development: Uses VITE_API_URL from .env.development or defaults to production URL
const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://zohaib.no/api'

// Create axios instance
const apiClient: AxiosInstance = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
})

// Request interceptor to add JWT token to requests
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const accessToken = localStorage.getItem('access_token')
    if (accessToken && config.headers) {
      config.headers.Authorization = `Bearer ${accessToken}`
    }
    return config
  },
  (error) => {
    return Promise.reject(error)
  }
)

// Response interceptor to handle token refresh
apiClient.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config

    // If error is 401 and we haven't tried refreshing yet
    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true

      try {
        const refreshToken = localStorage.getItem('refresh_token')
        if (refreshToken) {
          const response = await axios.post(`${API_BASE_URL}/auth/jwt/refresh/`, {
            refresh: refreshToken,
          })

          const { access } = response.data
          localStorage.setItem('access_token', access)

          // Retry the original request with new token
          if (originalRequest.headers) {
            originalRequest.headers.Authorization = `Bearer ${access}`
          }
          return apiClient(originalRequest)
        }
      } catch (refreshError) {
        // Refresh token failed, clear storage and redirect to login
        localStorage.removeItem('access_token')
        localStorage.removeItem('refresh_token')
        localStorage.removeItem('user')
        window.location.href = '/admin'
        return Promise.reject(refreshError)
      }
    }

    return Promise.reject(error)
  }
)

// Authentication service
export const authService = {
  async login(username: string, password: string) {
    const response = await axios.post(`${API_BASE_URL}/auth/jwt/create/`, {
      username,
      password,
    })
    return response.data
  },

  async getUserInfo(token: string) {
    const response = await axios.get(`${API_BASE_URL}/auth/users/me/`, {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
    return response.data
  },
}

// Project service
export const projectService = {
  async getProjects(): Promise<Project[]> {
    const response = await apiClient.get('/projects/')
    // Django REST framework returns array directly for list views
    return response.data
  },

  async getProject(id: number): Promise<Project> {
    const response = await apiClient.get(`/projects/${id}/`)
    return response.data
  },

  async createProject(project: Partial<Project>): Promise<Project> {
    const response = await apiClient.post('/projects/', project)
    return response.data
  },

  async updateProject(id: number, project: Partial<Project>): Promise<Project> {
    const response = await apiClient.patch(`/projects/${id}/`, project)
    return response.data
  },

  async deleteProject(id: number): Promise<void> {
    await apiClient.delete(`/projects/${id}/`)
  },
}

// Vehicle service
export const vehicleService = {
  async lookupRegistration(registrationNumber: string): Promise<Vehicle> {
    const response = await apiClient.get('/vehicles/lookup/', {
      params: {
        registration: registrationNumber,
      },
    })
    return response.data
  },
}

export default apiClient
