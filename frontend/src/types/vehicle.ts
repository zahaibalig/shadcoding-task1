// Type definitions for Vehicle data from Statens Vegvesen API

export interface Vehicle {
  registration: string
  brand: string
  model: string
  year: string
  nextEuApproval: string
  error?: string
}

// For API error responses
export interface VehicleApiError {
  error: string
}
