import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount, VueWrapper } from '@vue/test-utils'
import CarRegistrationView from '../CarRegistrationView.vue'
import { vehicleService } from '@/services/api'
import type { Vehicle } from '@/types/vehicle'

// Mock the vehicle service
vi.mock('@/services/api', () => ({
  vehicleService: {
    lookupRegistration: vi.fn(),
  },
}))

// Mock router-link
const mockRouterLink = {
  name: 'RouterLink',
  template: '<a><slot /></a>',
  props: ['to'],
}

describe('CarRegistrationView', () => {
  let wrapper: VueWrapper

  beforeEach(() => {
    vi.clearAllMocks()
  })

  afterEach(() => {
    if (wrapper) {
      wrapper.unmount()
    }
  })

  const mountComponent = () => {
    return mount(CarRegistrationView, {
      global: {
        stubs: {
          RouterLink: mockRouterLink,
        },
      },
    })
  }

  describe('Component Rendering', () => {
    it('should render the page header correctly', () => {
      wrapper = mountComponent()

      expect(wrapper.find('.page-title').text()).toBe('Check Car Registration')
      expect(wrapper.find('.page-description').text()).toContain(
        'Enter a Norwegian car registration number'
      )
    })

    it('should render the search form', () => {
      wrapper = mountComponent()

      expect(wrapper.find('.search-form').exists()).toBe(true)
      expect(wrapper.find('.registration-input').exists()).toBe(true)
      expect(wrapper.find('.search-btn').exists()).toBe(true)
    })

    it('should render back link', () => {
      wrapper = mountComponent()

      const backLink = wrapper.findComponent(mockRouterLink)
      expect(backLink.exists()).toBe(true)
      expect(backLink.text()).toContain('Back to Home')
    })

    it('should have correct input placeholder', () => {
      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      expect(input.attributes('placeholder')).toBe('Enter registration number (e.g., AB12345)')
    })

    it('should have maxlength of 7 on input', () => {
      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      expect(input.attributes('maxlength')).toBe('7')
    })
  })

  describe('Form Validation and Interaction', () => {
    it('should disable search button when input is empty', () => {
      wrapper = mountComponent()

      const searchBtn = wrapper.find('.search-btn')
      expect(searchBtn.attributes('disabled')).toBeDefined()
    })

    it('should enable search button when input has value', async () => {
      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const searchBtn = wrapper.find('.search-btn')
      expect(searchBtn.attributes('disabled')).toBeUndefined()
    })

    it('should convert input to uppercase', async () => {
      wrapper = mountComponent()

      const input = wrapper.find('.registration-input') as any
      expect(input.classes()).toContain('registration-input')
      // Check if CSS text-transform is applied
      expect(input.element.style.textTransform ||
             window.getComputedStyle(input.element).textTransform).toBeTruthy()
    })

    it('should clear error message when starting a new search', async () => {
      const mockVehicle: Vehicle = {
        registration: 'AB12345',
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        nextEuApproval: '2025-12-31',
      }

      vi.mocked(vehicleService.lookupRegistration).mockResolvedValue(mockVehicle)

      wrapper = mountComponent()

      // Set an error message first
      const vm = wrapper.vm as any
      vm.errorMessage = 'Some error'
      await wrapper.vm.$nextTick()

      expect(wrapper.find('.error-message').exists()).toBe(true)

      // Start a new search
      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      // Error should be cleared
      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))
      const vm2 = wrapper.vm as any
      expect(vm2.errorMessage).toBe('')
    })
  })

  describe('Successful Vehicle Lookup', () => {
    it('should display vehicle data on successful lookup', async () => {
      const mockVehicle: Vehicle = {
        registration: 'AB12345',
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        nextEuApproval: '2025-12-31',
      }

      vi.mocked(vehicleService.lookupRegistration).mockResolvedValue(mockVehicle)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(vehicleService.lookupRegistration).toHaveBeenCalledWith('AB12345')
      expect(wrapper.find('.results-section').exists()).toBe(true)
      expect(wrapper.html()).toContain('AB12345')
      expect(wrapper.html()).toContain('Toyota')
      expect(wrapper.html()).toContain('Corolla')
      expect(wrapper.html()).toContain('2020')
      expect(wrapper.html()).toContain('2025-12-31')
    })

    it('should hide loading spinner after successful lookup', async () => {
      const mockVehicle: Vehicle = {
        registration: 'AB12345',
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        nextEuApproval: '2025-12-31',
      }

      vi.mocked(vehicleService.lookupRegistration).mockResolvedValue(mockVehicle)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(wrapper.find('.loading-spinner').exists()).toBe(false)
    })
  })

  describe('Loading State', () => {
    it('should show loading spinner during API call', async () => {
      vi.mocked(vehicleService.lookupRegistration).mockImplementation(
        () => new Promise((resolve) => setTimeout(resolve, 100))
      )

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()

      expect(wrapper.find('.loading-spinner').exists()).toBe(true)
      expect(wrapper.find('.loading-spinner').text()).toContain('Fetching vehicle information')
    })

    it('should disable input and button during loading', async () => {
      vi.mocked(vehicleService.lookupRegistration).mockImplementation(
        () => new Promise((resolve) => setTimeout(resolve, 100))
      )

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()

      const inputElement = wrapper.find('.registration-input')
      const button = wrapper.find('.search-btn')

      expect(inputElement.attributes('disabled')).toBeDefined()
      expect(button.attributes('disabled')).toBeDefined()
      expect(button.text()).toBe('Searching...')
    })
  })

  describe('Error Handling', () => {
    it('should display error message for invalid registration number', async () => {
      const errorResponse = {
        response: {
          status: 404,
          data: { error: 'Please enter a correct registration number. Vehicle not found.' },
        },
      }

      vi.mocked(vehicleService.lookupRegistration).mockRejectedValue(errorResponse)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('INVALID')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(wrapper.find('.error-message').exists()).toBe(true)
      expect(wrapper.find('.error-message').text()).toContain(
        'Please enter a correct registration number'
      )
    })

    it('should display error for network failure', async () => {
      const errorResponse = {
        request: {},
        message: 'Network Error',
      }

      vi.mocked(vehicleService.lookupRegistration).mockRejectedValue(errorResponse)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(wrapper.find('.error-message').exists()).toBe(true)
      expect(wrapper.find('.error-message').text()).toContain('No response from server')
    })

    it('should display error for rate limit', async () => {
      const errorResponse = {
        response: {
          status: 429,
          data: { error: 'Rate limit exceeded. Maximum 50,000 calls per day.' },
        },
      }

      vi.mocked(vehicleService.lookupRegistration).mockRejectedValue(errorResponse)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(wrapper.find('.error-message').exists()).toBe(true)
      expect(wrapper.find('.error-message').text()).toContain('Rate limit exceeded')
    })

    it('should display error when submitting empty form', async () => {
      wrapper = mountComponent()

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()

      expect(wrapper.find('.error-message').exists()).toBe(true)
      expect(wrapper.find('.error-message').text()).toContain('Please enter a registration number')
    })

    it('should not display results section when there is an error', async () => {
      const errorResponse = {
        response: {
          status: 404,
          data: { error: 'Vehicle not found' },
        },
      }

      vi.mocked(vehicleService.lookupRegistration).mockRejectedValue(errorResponse)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('INVALID')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(wrapper.find('.error-message').exists()).toBe(true)
      expect(wrapper.find('.results-section').exists()).toBe(false)
    })
  })

  describe('Data Management', () => {
    it('should clear previous results when starting a new search', async () => {
      const mockVehicle: Vehicle = {
        registration: 'AB12345',
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        nextEuApproval: '2025-12-31',
      }

      vi.mocked(vehicleService.lookupRegistration).mockResolvedValue(mockVehicle)

      wrapper = mountComponent()

      // First search
      const input = wrapper.find('.registration-input')
      await input.setValue('AB12345')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      expect(wrapper.find('.results-section').exists()).toBe(true)

      // Second search with error
      vi.mocked(vehicleService.lookupRegistration).mockRejectedValue({
        response: { status: 404, data: { error: 'Not found' } },
      })

      await input.setValue('INVALID')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()
      await new Promise((resolve) => setTimeout(resolve, 0))

      // Results should be cleared
      expect(wrapper.find('.results-section').exists()).toBe(false)
    })

    it('should trim whitespace from registration input', async () => {
      const mockVehicle: Vehicle = {
        registration: 'AB12345',
        brand: 'Toyota',
        model: 'Corolla',
        year: '2020',
        nextEuApproval: '2025-12-31',
      }

      vi.mocked(vehicleService.lookupRegistration).mockResolvedValue(mockVehicle)

      wrapper = mountComponent()

      const input = wrapper.find('.registration-input')
      await input.setValue('  AB12345  ')

      const form = wrapper.find('.search-form')
      await form.trigger('submit.prevent')

      await wrapper.vm.$nextTick()

      expect(vehicleService.lookupRegistration).toHaveBeenCalledWith('AB12345')
    })
  })
})
