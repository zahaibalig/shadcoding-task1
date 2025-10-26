<template>
  <div class="car-registration-page">
    <header class="page-header">
      <div class="header-content">
        <h1 class="page-title">Check Car Registration</h1>
        <router-link to="/" class="back-link">← Back to Home</router-link>
      </div>
      <p class="page-description">
        Enter a Norwegian car registration number to see vehicle details
      </p>
    </header>

    <div class="container">
      <div class="search-section">
        <form @submit.prevent="handleSearch" class="search-form">
          <div class="input-group">
            <input
              v-model="registrationNumber"
              type="text"
              placeholder="Enter registration number (e.g., AB12345)"
              class="registration-input"
              :disabled="isLoading"
              maxlength="7"
              required
            />
            <button type="submit" class="search-btn" :disabled="isLoading || !registrationNumber">
              {{ isLoading ? 'Searching...' : 'Search' }}
            </button>
          </div>
        </form>
      </div>

      <!-- Error Message -->
      <div v-if="errorMessage" class="error-message">
        <strong>Error:</strong> {{ errorMessage }}
      </div>

      <!-- Loading State -->
      <div v-if="isLoading" class="loading-spinner">
        <div class="spinner"></div>
        <p>Fetching vehicle information...</p>
      </div>

      <!-- Results Table -->
      <div v-if="vehicleData && !isLoading" class="results-section">
        <h2 class="results-title">Vehicle Information</h2>
        <div class="results-table">
          <table>
            <tbody>
              <tr>
                <th>Registration Number</th>
                <td>{{ vehicleData.registration }}</td>
              </tr>
              <tr>
                <th>Brand</th>
                <td>{{ vehicleData.brand }}</td>
              </tr>
              <tr>
                <th>Model</th>
                <td>{{ vehicleData.model }}</td>
              </tr>
              <tr>
                <th>Year</th>
                <td>{{ vehicleData.year }}</td>
              </tr>
              <tr>
                <th>Next EU Approval</th>
                <td>{{ vehicleData.nextEuApproval }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { vehicleService } from '@/services/api'
import type { Vehicle } from '@/types/vehicle'

const registrationNumber = ref('')
const vehicleData = ref<Vehicle | null>(null)
const isLoading = ref(false)
const errorMessage = ref('')

const handleSearch = async () => {
  if (!registrationNumber.value.trim()) {
    errorMessage.value = 'Please enter a registration number'
    return
  }

  // Reset previous results and errors
  errorMessage.value = ''
  vehicleData.value = null
  isLoading.value = true

  try {
    const data = await vehicleService.lookupRegistration(registrationNumber.value.trim())
    vehicleData.value = data

    // Check if there's an error in the response
    if (data.error) {
      errorMessage.value = data.error
    }
  } catch (error: any) {
    console.error('Error fetching vehicle data:', error)

    // Handle different error scenarios
    if (error.response) {
      // Server responded with error
      const errorData = error.response.data
      errorMessage.value = errorData.error || errorData.detail || 'Failed to fetch vehicle information'
    } else if (error.request) {
      // Request made but no response
      errorMessage.value = 'No response from server. Please check your connection.'
    } else {
      // Other errors
      errorMessage.value = error.message || 'An unexpected error occurred'
    }
  } finally {
    isLoading.value = false
  }
}
</script>

<style scoped>
.car-registration-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

/* Header with ProjectsView style */
.page-header {
  background: rgba(255, 255, 255, 0.95);
  padding: 32px 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.page-title {
  margin: 0;
  font-size: 32px;
  font-weight: 700;
  color: #333;
}

.back-link {
  padding: 8px 16px;
  background-color: #667eea;
  color: white;
  text-decoration: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  transition: background-color 0.2s;
}

.back-link:hover {
  background-color: #5568d3;
}

.page-description {
  max-width: 1200px;
  margin: 0 auto;
  font-size: 16px;
  color: #666;
  text-align: center;
}

.container {
  max-width: 800px;
  margin: 0 auto;
  padding: 32px 20px;
}

.search-section {
  background: white;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
  margin-bottom: 30px;
}

.search-form {
  width: 100%;
}

.input-group {
  display: flex;
  gap: 12px;
}

.registration-input {
  flex: 1;
  padding: 14px 18px;
  font-size: 16px;
  border: 2px solid #e0e0e0;
  border-radius: 8px;
  transition: border-color 0.3s ease;
  text-transform: uppercase;
}

.registration-input:focus {
  outline: none;
  border-color: #667eea;
}

.registration-input:disabled {
  background-color: #f5f5f5;
  cursor: not-allowed;
}

.search-btn {
  padding: 14px 32px;
  font-size: 16px;
  font-weight: 600;
  color: white;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 8px;
  cursor: pointer;
  transition: all 0.3s ease;
  min-width: 140px;
}

.search-btn:hover:not(:disabled) {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(102, 126, 234, 0.4);
}

.search-btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
  transform: none;
}

.error-message {
  background-color: #fee;
  color: #c33;
  padding: 16px 20px;
  border-radius: 8px;
  margin-bottom: 20px;
  border-left: 4px solid #c33;
}

.loading-spinner {
  text-align: center;
  padding: 40px;
  background: white;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.spinner {
  width: 50px;
  height: 50px;
  margin: 0 auto 20px;
  border: 4px solid #f3f3f3;
  border-top: 4px solid #667eea;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

.loading-spinner p {
  color: #666;
  font-size: 16px;
}

.results-section {
  background: white;
  padding: 30px;
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.1);
}

.results-title {
  font-size: 24px;
  font-weight: 700;
  color: #333;
  margin-bottom: 20px;
  text-align: center;
}

.results-table {
  overflow-x: auto;
}

.results-table table {
  width: 100%;
  border-collapse: collapse;
}

.results-table th,
.results-table td {
  padding: 14px 16px;
  text-align: left;
  border-bottom: 1px solid #e0e0e0;
}

.results-table th {
  font-weight: 600;
  color: #667eea;
  width: 40%;
}

.results-table td {
  color: #333;
}

.results-table tr:last-child th,
.results-table tr:last-child td {
  border-bottom: none;
}

.results-table tr:hover {
  background-color: #f8f9fa;
}

@media (max-width: 768px) {
  .page-header {
    padding: 24px 16px;
  }

  .header-content {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .page-title {
    font-size: 24px;
  }

  .container {
    padding: 24px 16px;
  }

  .input-group {
    flex-direction: column;
  }

  .search-btn {
    width: 100%;
  }

  .results-table th {
    width: 50%;
  }

  .search-section,
  .results-section {
    padding: 20px;
  }
}
</style>
