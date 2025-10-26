<template>
  <div class="admin-dashboard">
    <header class="page-header">
      <div class="header-content">
        <h1 class="page-title">Admin Dashboard</h1>
        <div class="header-actions">
          <span v-if="authStore.user" class="user-info">
            Welcome, {{ authStore.user.username }}
          </span>
          <button @click="openCreateModal" class="create-btn">+ New Car</button>
          <button @click="handleLogout" class="logout-btn">Logout</button>
          <router-link to="/" class="back-link">← Back to Home</router-link>
        </div>
      </div>

      <!-- Search and filter controls -->
      <div class="controls">
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Search car by name"
          class="search-input"
        />
        <div class="filter-controls">
          <label class="filter-label">
            <input
              v-model="showActiveOnly"
              type="checkbox"
              class="filter-checkbox"
            />
            Show only available cars
          </label>
        </div>
      </div>
    </header>

    <main class="page-content">
      <!-- Success/Error Toast -->
      <div v-if="toast.show" class="toast" :class="toast.type">
        {{ toast.message }}
      </div>

      <!-- Loading state -->
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Loading Cars...</p>
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="error">
        <p>{{ error }}</p>
        <button @click="fetchProjects" class="retry-btn">Retry</button>
      </div>

      <!-- Empty state -->
      <div v-else-if="filteredProjects.length === 0" class="empty-state">
        <p v-if="projects.length === 0">
          No car found!
        </p>
        <p v-else>
          No car match your search criteria.
        </p>
      </div>

      <!-- Projects list -->
      <div v-else class="projects-list">
        <div
          v-for="project in filteredProjects"
          :key="project.id"
          class="project-card"
        >
          <div class="project-header">
            <h3 class="project-name">{{ project.car_name }}</h3>
            <div class="project-actions">
              <span
                class="project-status"
                :class="{ active: project.is_active, inactive: !project.is_active }"
              >
                {{ project.is_active ? 'Available' : 'Sold' }}
              </span>
              <button @click="openEditModal(project)" class="action-btn edit-btn" title="Edit">
                ✏️
              </button>
              <button @click="confirmDelete(project)" class="action-btn delete-btn" title="Delete">
                🗑️
              </button>
            </div>
          </div>

          <p class="project-description">
            {{ project.description || 'No description provided.' }}
          </p>

          <div class="project-price">
            <span class="price-label">Price:</span>
            <span class="price-value">${{ project.price.toLocaleString() }}</span>
          </div>

          <div class="project-meta">
            <div class="meta-item">
              <span class="meta-label">Created:</span>
              <span class="meta-value">{{ formatDate(project.created_at) }}</span>
            </div>
            <div class="meta-item">
              <span class="meta-label">Updated:</span>
              <span class="meta-value">{{ formatDate(project.updated_at) }}</span>
            </div>
          </div>
        </div>
      </div>
    </main>

    <!-- Create/Edit Modal -->
    <div v-if="showModal" class="modal-overlay" @click="closeModal">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h2>{{ isEditMode ? 'Edit Car' : 'Create New Car' }}</h2>
          <button @click="closeModal" class="close-btn">×</button>
        </div>

        <form @submit.prevent="handleSubmit" class="modal-form">
          <div class="form-group">
            <label for="car_name">Car Name *</label>
            <input
              id="car_name"
              v-model="formData.car_name"
              type="text"
              required
              maxlength="120"
              class="form-input"
              placeholder="Enter car name"
            />
          </div>

          <div class="form-group">
            <label for="description">Description</label>
            <textarea
              id="description"
              v-model="formData.description"
              rows="4"
              class="form-input"
              placeholder="Enter car description"
            ></textarea>
          </div>

          <div class="form-group">
            <label for="price">Price *</label>
            <input
              id="price"
              v-model.number="formData.price"
              type="number"
              required
              min="0"
              class="form-input"
              placeholder="Enter price"
            />
          </div>

          <div class="form-group">
            <label class="checkbox-label">
              <input
                v-model="formData.is_active"
                type="checkbox"
                class="form-checkbox"
              />
              <span>Available</span>
            </label>
          </div>

          <div v-if="formError" class="form-error">
            {{ formError }}
          </div>

          <div class="modal-actions">
            <button type="button" @click="closeModal" class="btn btn-cancel">
              Cancel
            </button>
            <button type="submit" class="btn btn-submit" :disabled="submitting">
              {{ submitting ? 'Saving...' : (isEditMode ? 'Update' : 'Create') }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- Delete Confirmation Modal -->
    <div v-if="showDeleteModal" class="modal-overlay" @click="closeDeleteModal">
      <div class="modal-content delete-modal" @click.stop>
        <div class="modal-header">
          <h2>Confirm Delete</h2>
          <button @click="closeDeleteModal" class="close-btn">×</button>
        </div>

        <div class="modal-body">
          <p>Are you sure you want to delete <strong>{{ projectToDelete?.car_name }}</strong>?</p>
          <p class="warning-text">This action cannot be undone.</p>
        </div>

        <div class="modal-actions">
          <button @click="closeDeleteModal" class="btn btn-cancel">
            Cancel
          </button>
          <button @click="handleDelete" class="btn btn-delete" :disabled="deleting">
            {{ deleting ? 'Deleting...' : 'Delete' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { projectService } from '@/services/api'
import type { Project } from '@/types/project'

const router = useRouter()
const authStore = useAuthStore()

// State
const projects = ref<Project[]>([])
const loading = ref(false)
const error = ref<string | null>(null)
const searchQuery = ref('')
const showActiveOnly = ref(false)

// Modal state
const showModal = ref(false)
const isEditMode = ref(false)
const editingProject = ref<Project | null>(null)
const submitting = ref(false)
const formError = ref<string | null>(null)

// Form data
const formData = ref({
  car_name: '',
  description: '',
  price: 0,
  is_active: true,
})

// Delete modal state
const showDeleteModal = ref(false)
const projectToDelete = ref<Project | null>(null)
const deleting = ref(false)

// Toast notification
const toast = ref({
  show: false,
  message: '',
  type: 'success' as 'success' | 'error',
})

// Computed
const filteredProjects = computed(() => {
  let filtered = projects.value

  // Filter by search query
  if (searchQuery.value.trim()) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(
      (project) =>
        project.car_name.toLowerCase().includes(query) ||
        project.description.toLowerCase().includes(query)
    )
  }

  // Filter by active status
  if (showActiveOnly.value) {
    filtered = filtered.filter((project) => project.is_active)
  }

  return filtered
})

// Methods
const fetchProjects = async () => {
  loading.value = true
  error.value = null

  try {
    projects.value = await projectService.getProjects()
  } catch (err: any) {
    console.error('Failed to fetch projects:', err)
    error.value = err.response?.data?.detail || 'Failed to load projects. Please try again.'
  } finally {
    loading.value = false
  }
}

const handleLogout = () => {
  authStore.logout()
  router.push('/admin')
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  })
}

// Modal functions
const openCreateModal = () => {
  isEditMode.value = false
  editingProject.value = null
  formData.value = {
    car_name: '',
    description: '',
    price: 0,
    is_active: true,
  }
  formError.value = null
  showModal.value = true
}

const openEditModal = (project: Project) => {
  isEditMode.value = true
  editingProject.value = project
  formData.value = {
    car_name: project.car_name,
    description: project.description,
    price: project.price,
    is_active: project.is_active,
  }
  formError.value = null
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
  isEditMode.value = false
  editingProject.value = null
  formError.value = null
}

const handleSubmit = async () => {
  if (!formData.value.car_name.trim()) {
    formError.value = 'Car name is required'
    return
  }

  submitting.value = true
  formError.value = null

  try {
    if (isEditMode.value && editingProject.value) {
      // Update existing project
      await projectService.updateProject(editingProject.value.id, formData.value)
      showToast('Project updated successfully!', 'success')
    } else {
      // Create new project
      await projectService.createProject(formData.value)
      showToast('Project created successfully!', 'success')
    }

    closeModal()
    await fetchProjects()
  } catch (err: any) {
    console.error('Failed to save project:', err)
    formError.value = err.response?.data?.detail || 'Failed to save project. Please try again.'
  } finally {
    submitting.value = false
  }
}

// Delete functions
const confirmDelete = (project: Project) => {
  projectToDelete.value = project
  showDeleteModal.value = true
}

const closeDeleteModal = () => {
  showDeleteModal.value = false
  projectToDelete.value = null
}

const handleDelete = async () => {
  if (!projectToDelete.value) return

  deleting.value = true

  try {
    await projectService.deleteProject(projectToDelete.value.id)
    showToast('Project deleted successfully!', 'success')
    closeDeleteModal()
    await fetchProjects()
  } catch (err: any) {
    console.error('Failed to delete project:', err)
    showToast('Failed to delete project. Please try again.', 'error')
  } finally {
    deleting.value = false
  }
}

// Toast notification
const showToast = (message: string, type: 'success' | 'error') => {
  toast.value = {
    show: true,
    message,
    type,
  }

  setTimeout(() => {
    toast.value.show = false
  }, 3000)
}

// Lifecycle
onMounted(async () => {
  await fetchProjects()
})
</script>

<style scoped>
.admin-dashboard {
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
  margin: 0 auto 24px;
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

.header-actions {
  display: flex;
  align-items: center;
  gap: 12px;
}

.user-info {
  font-size: 14px;
  color: #666;
  font-weight: 500;
}

.create-btn {
  padding: 8px 16px;
  background-color: #28a745;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.create-btn:hover {
  background-color: #218838;
}

.logout-btn {
  padding: 8px 16px;
  background-color: #dc3545;
  color: white;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: background-color 0.2s;
}

.logout-btn:hover {
  background-color: #c82333;
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

.controls {
  max-width: 1200px;
  margin: 0 auto;
}

.search-input {
  width: 100%;
  padding: 12px 16px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  box-sizing: border-box;
  margin-bottom: 12px;
}

.search-input:focus {
  outline: none;
  border-color: #667eea;
}

.filter-controls {
  display: flex;
  gap: 16px;
}

.filter-label {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 14px;
  color: #333;
  cursor: pointer;
}

.filter-checkbox {
  width: 16px;
  height: 16px;
  cursor: pointer;
}

.page-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 32px 24px;
  position: relative;
}

/* Toast Notification */
.toast {
  position: fixed;
  top: 20px;
  right: 20px;
  padding: 16px 24px;
  border-radius: 6px;
  color: white;
  font-weight: 500;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  z-index: 10000;
  animation: slideIn 0.3s ease-out;
}

.toast.success {
  background-color: #28a745;
}

.toast.error {
  background-color: #dc3545;
}

@keyframes slideIn {
  from {
    transform: translateX(100%);
    opacity: 0;
  }
  to {
    transform: translateX(0);
    opacity: 1;
  }
}

.loading,
.error,
.empty-state {
  text-align: center;
  padding: 48px 24px;
  color: white;
}

.spinner {
  width: 40px;
  height: 40px;
  margin: 0 auto 16px;
  border: 4px solid rgba(255, 255, 255, 0.3);
  border-top-color: white;
  border-radius: 50%;
  animation: spin 1s linear infinite;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.error {
  color: #ffcccb;
}

.retry-btn {
  margin-top: 16px;
  padding: 10px 20px;
  background-color: white;
  color: #667eea;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.retry-btn:hover {
  opacity: 0.9;
}

.projects-list {
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.project-card {
  background: white;
  border-radius: 8px;
  padding: 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
  transition: transform 0.2s, box-shadow 0.2s;
}

.project-card:hover {
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 12px;
}

.project-name {
  margin: 0;
  font-size: 20px;
  font-weight: 600;
  color: #333;
  flex: 1;
}

.project-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.project-status {
  padding: 4px 12px;
  border-radius: 12px;
  font-size: 12px;
  font-weight: 600;
  text-transform: uppercase;
}

.project-status.active {
  background-color: #d4edda;
  color: #155724;
}

.project-status.inactive {
  background-color: #f8d7da;
  color: #721c24;
}

.action-btn {
  padding: 6px 10px;
  border: none;
  border-radius: 4px;
  font-size: 16px;
  cursor: pointer;
  transition: opacity 0.2s;
}

.action-btn:hover {
  opacity: 0.8;
}

.edit-btn {
  background-color: #ffc107;
}

.delete-btn {
  background-color: #dc3545;
}

.project-description {
  margin: 0 0 12px 0;
  font-size: 14px;
  color: #666;
  line-height: 1.5;
}

.project-price {
  margin: 0 0 16px 0;
  padding: 8px 12px;
  background-color: #f8f9fa;
  border-radius: 6px;
  display: flex;
  align-items: center;
  gap: 8px;
}

.price-label {
  font-size: 13px;
  color: #666;
  font-weight: 500;
}

.price-value {
  font-size: 18px;
  color: #28a745;
  font-weight: 700;
}

.project-meta {
  display: flex;
  gap: 24px;
  padding-top: 16px;
  border-top: 1px solid #eee;
}

.meta-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.meta-label {
  font-size: 12px;
  color: #999;
  font-weight: 500;
  text-transform: uppercase;
}

.meta-value {
  font-size: 13px;
  color: #666;
}

/* Modal Styles */
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background-color: rgba(0, 0, 0, 0.5);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
  padding: 20px;
}

.modal-content {
  background: white;
  border-radius: 12px;
  padding: 0;
  max-width: 500px;
  width: 100%;
  max-height: 90vh;
  overflow-y: auto;
  box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 24px;
  border-bottom: 1px solid #eee;
}

.modal-header h2 {
  margin: 0;
  font-size: 24px;
  color: #333;
}

.close-btn {
  background: none;
  border: none;
  font-size: 32px;
  color: #999;
  cursor: pointer;
  line-height: 1;
  padding: 0;
  width: 32px;
  height: 32px;
}

.close-btn:hover {
  color: #333;
}

.modal-form {
  padding: 24px;
}

.modal-body {
  padding: 24px;
}

.form-group {
  margin-bottom: 20px;
}

.form-group label {
  display: block;
  margin-bottom: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #333;
}

.form-input {
  width: 100%;
  padding: 10px 12px;
  border: 1px solid #ddd;
  border-radius: 6px;
  font-size: 14px;
  font-family: inherit;
  box-sizing: border-box;
}

.form-input:focus {
  outline: none;
  border-color: #667eea;
}

textarea.form-input {
  resize: vertical;
  min-height: 100px;
}

.checkbox-label {
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
}

.form-checkbox {
  width: 18px;
  height: 18px;
  cursor: pointer;
}

.form-error {
  padding: 12px;
  background-color: #fee;
  color: #c33;
  border-radius: 6px;
  font-size: 14px;
  margin-bottom: 16px;
}

.warning-text {
  color: #dc3545;
  font-weight: 500;
  margin-top: 8px;
}

.modal-actions {
  display: flex;
  justify-content: flex-end;
  gap: 12px;
  padding: 24px;
  border-top: 1px solid #eee;
  margin: 0;
}

.btn {
  padding: 10px 20px;
  border: none;
  border-radius: 6px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  transition: opacity 0.2s;
}

.btn:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.btn-cancel {
  background-color: #6c757d;
  color: white;
}

.btn-cancel:hover:not(:disabled) {
  opacity: 0.9;
}

.btn-submit {
  background-color: #28a745;
  color: white;
}

.btn-submit:hover:not(:disabled) {
  opacity: 0.9;
}

.btn-delete {
  background-color: #dc3545;
  color: white;
}

.btn-delete:hover:not(:disabled) {
  opacity: 0.9;
}

.delete-modal {
  max-width: 400px;
}

@media (max-width: 768px) {
  .page-header {
    padding: 24px 16px;
  }

  .header-content {
    flex-direction: column;
    align-items: flex-start;
    gap: 16px;
  }

  .page-title {
    font-size: 24px;
  }

  .header-actions {
    width: 100%;
    justify-content: space-between;
    flex-wrap: wrap;
  }

  .page-content {
    padding: 24px 16px;
  }

  .project-meta {
    flex-direction: column;
    gap: 12px;
  }

  .project-header {
    flex-direction: column;
    align-items: flex-start;
    gap: 12px;
  }

  .project-actions {
    width: 100%;
    justify-content: space-between;
  }

  .toast {
    right: 10px;
    left: 10px;
    top: 10px;
  }
}
</style>
