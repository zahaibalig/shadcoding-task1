import { describe, it, expect, beforeEach, vi } from 'vitest'
import type { Vehicle } from '@/types/vehicle'

// Use vi.hoisted to create mocks that can be used in the factory
const { mockAxiosInstance, mockedAxiosStatic } = vi.hoisted(() => {
  const mockInstance = {
    get: vi.fn(),
    post: vi.fn(),
    patch: vi.fn(),
    delete: vi.fn(),
    interceptors: {
      request: { use: vi.fn(), eject: vi.fn() },
      response: { use: vi.fn(), eject: vi.fn() },
    },
  }

  const mockedStatic = {
    post: vi.fn(),
    get: vi.fn(),
  }

  return {
    mockAxiosInstance: mockInstance,
    mockedAxiosStatic: mockedStatic,
  }
})

// Mock axios module
vi.mock('axios', () => {
  return {
    default: {
      create: vi.fn(() => mockAxiosInstance),
      ...mockedAxiosStatic,
    },
  }
})

// Import after mocking
import { vehicleService, authService, projectService } from '../api'

describe('Vehicle Service', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('lookupRegistration', () => {
    it('should successfully fetch vehicle data', async () => {
      const mockVehicle: Vehicle = {
        registration: 'AB12345',
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        nextEuApproval: '2025-12-31',
      }

      mockAxiosInstance.get.mockResolvedValue({ data: mockVehicle })

      const result = await vehicleService.lookupRegistration('AB12345')

      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/vehicles/lookup/', {
        params: { registration: 'AB12345' },
      })
      expect(result).toEqual(mockVehicle)
    })

    it('should handle 404 error when vehicle not found', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: {
          status: 404,
          data: { error: 'Please enter a correct registration number. Vehicle not found.' },
        },
      })

      await expect(vehicleService.lookupRegistration('INVALID')).rejects.toMatchObject({
        response: {
          status: 404,
        },
      })
    })

    it('should handle network error', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        request: {},
        message: 'Network Error',
      })

      await expect(vehicleService.lookupRegistration('AB12345')).rejects.toMatchObject({
        message: 'Network Error',
      })
    })

    it('should handle server error', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: {
          status: 500,
          data: { error: 'Internal server error' },
        },
      })

      await expect(vehicleService.lookupRegistration('AB12345')).rejects.toMatchObject({
        response: {
          status: 500,
        },
      })
    })

    it('should handle rate limit error', async () => {
      mockAxiosInstance.get.mockRejectedValue({
        response: {
          status: 429,
          data: { error: 'Rate limit exceeded. Maximum 50,000 calls per day.' },
        },
      })

      await expect(vehicleService.lookupRegistration('AB12345')).rejects.toMatchObject({
        response: {
          status: 429,
        },
      })
    })

    it('should pass registration number as query parameter', async () => {
      mockAxiosInstance.get.mockResolvedValue({ data: {} })

      await vehicleService.lookupRegistration('TEST123')

      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/vehicles/lookup/', {
        params: { registration: 'TEST123' },
      })
    })
  })
})

describe('Auth Service', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('login', () => {
    it('should successfully login and return tokens', async () => {
      const mockResponse = {
        access: 'mock-access-token',
        refresh: 'mock-refresh-token',
      }

      mockedAxiosStatic.post.mockResolvedValue({ data: mockResponse })

      const result = await authService.login('testuser', 'password123')

      expect(mockedAxiosStatic.post).toHaveBeenCalledWith('http://localhost:8000/api/auth/jwt/create/', {
        username: 'testuser',
        password: 'password123',
      })
      expect(result).toEqual(mockResponse)
    })

    it('should handle login failure', async () => {
      mockedAxiosStatic.post.mockRejectedValue({
        response: {
          status: 401,
          data: { detail: 'Invalid credentials' },
        },
      })

      await expect(authService.login('wronguser', 'wrongpass')).rejects.toMatchObject({
        response: {
          status: 401,
        },
      })
    })
  })

  describe('getUserInfo', () => {
    it('should fetch user information', async () => {
      const mockUser = {
        id: 1,
        username: 'testuser',
        email: 'test@example.com',
      }

      mockedAxiosStatic.get.mockResolvedValue({ data: mockUser })

      const result = await authService.getUserInfo('mock-token')

      expect(mockedAxiosStatic.get).toHaveBeenCalledWith('http://localhost:8000/api/auth/users/me/', {
        headers: {
          Authorization: 'Bearer mock-token',
        },
      })
      expect(result).toEqual(mockUser)
    })

    it('should handle unauthorized access', async () => {
      mockedAxiosStatic.get.mockRejectedValue({
        response: {
          status: 401,
          data: { detail: 'Authentication credentials were not provided.' },
        },
      })

      await expect(authService.getUserInfo('invalid-token')).rejects.toMatchObject({
        response: {
          status: 401,
        },
      })
    })
  })
})

describe('Project Service', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  describe('getProjects', () => {
    it('should fetch all projects', async () => {
      const mockProjects = [
        { id: 1, name: 'Project 1', description: 'Description 1' },
        { id: 2, name: 'Project 2', description: 'Description 2' },
      ]

      mockAxiosInstance.get.mockResolvedValue({ data: mockProjects })

      const result = await projectService.getProjects()

      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/projects/')
      expect(result).toEqual(mockProjects)
    })
  })

  describe('getProject', () => {
    it('should fetch a single project by id', async () => {
      const mockProject = { id: 1, name: 'Project 1', description: 'Description 1' }

      mockAxiosInstance.get.mockResolvedValue({ data: mockProject })

      const result = await projectService.getProject(1)

      expect(mockAxiosInstance.get).toHaveBeenCalledWith('/projects/1/')
      expect(result).toEqual(mockProject)
    })
  })

  describe('createProject', () => {
    it('should create a new project', async () => {
      const newProject = { name: 'New Project', description: 'New Description' }
      const createdProject = { id: 3, ...newProject }

      mockAxiosInstance.post.mockResolvedValue({ data: createdProject })

      const result = await projectService.createProject(newProject)

      expect(mockAxiosInstance.post).toHaveBeenCalledWith('/projects/', newProject)
      expect(result).toEqual(createdProject)
    })
  })

  describe('updateProject', () => {
    it('should update an existing project', async () => {
      const updates = { name: 'Updated Name' }
      const updatedProject = { id: 1, name: 'Updated Name', description: 'Description 1' }

      mockAxiosInstance.patch.mockResolvedValue({ data: updatedProject })

      const result = await projectService.updateProject(1, updates)

      expect(mockAxiosInstance.patch).toHaveBeenCalledWith('/projects/1/', updates)
      expect(result).toEqual(updatedProject)
    })
  })

  describe('deleteProject', () => {
    it('should delete a project', async () => {
      mockAxiosInstance.delete.mockResolvedValue({})

      await projectService.deleteProject(1)

      expect(mockAxiosInstance.delete).toHaveBeenCalledWith('/projects/1/')
    })
  })
})
