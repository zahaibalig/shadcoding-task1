// Type definitions for Project model matching Django backend

export interface Project {
  id: number
  car_name: string
  description: string
  price: number
  is_active: boolean
  created_at: string
  updated_at: string
}

export interface ProjectListResponse {
  results: Project[]
  count?: number
}

// For API error responses
export interface ApiError {
  detail?: string
  message?: string
  [key: string]: any
}
