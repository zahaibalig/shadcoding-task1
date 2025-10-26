<template>
  <div class="about-page">
    <header class="page-header">
      <div class="header-content">
        <h1 class="page-title">About Our Projects</h1>
        <router-link to="/" class="back-link">← Back to Home</router-link>
      </div>
    </header>

    <main class="page-content">
      <!-- Loading state -->
      <div v-if="loading" class="loading">
        <div class="spinner"></div>
        <p>Loading projects...</p>
      </div>

      <!-- Error state -->
      <div v-else-if="error" class="error">
        <p>{{ error }}</p>
        <button @click="fetchProjects" class="retry-btn">Retry</button>
      </div>

      <!-- Empty state -->
      <div v-else-if="projects.length === 0" class="empty-state">
        <p>No projects available at the moment.</p>
      </div>

      <!-- Projects list -->
      <div v-else class="projects-list">
        <div
          v-for="project in projects"
          :key="project.id"
          class="project-card"
        >
          <div class="project-header">
            <h3 class="project-name">{{ project.name }}</h3>
            <span
              class="project-status"
              :class="{ active: project.is_active, inactive: !project.is_active }"
            >
              {{ project.is_active ? 'Active' : 'Inactive' }}
            </span>
          </div>

          <p class="project-description">
            {{ project.description || 'No description provided.' }}
          </p>

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
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import axios from 'axios'
import type { Project } from '@/types/project'

// State
const projects = ref<Project[]>([])
const loading = ref(false)
const error = ref<string | null>(null)

// Methods
const fetchProjects = async () => {
  loading.value = true
  error.value = null

  try {
    // Fetch projects without authentication
    const response = await axios.get('http://localhost:8000/api/projects/')
    projects.value = response.data
  } catch (err: any) {
    console.error('Failed to fetch projects:', err)
    error.value = 'Failed to load projects. Please try again.'
  } finally {
    loading.value = false
  }
}

const formatDate = (dateString: string): string => {
  const date = new Date(dateString)
  return date.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric',
  })
}

// Lifecycle
onMounted(async () => {
  await fetchProjects()
})
</script>

<style scoped>
.about-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
}

.page-header {
  background: rgba(255, 255, 255, 0.95);
  padding: 32px 24px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
}

.header-content {
  max-width: 1200px;
  margin: 0 auto;
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

.page-content {
  max-width: 1200px;
  margin: 0 auto;
  padding: 32px 24px;
}

.loading,
.error,
.empty-state {
  text-align: center;
  padding: 48px 24px;
  color: white;
  font-size: 18px;
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

.project-description {
  margin: 0 0 16px 0;
  font-size: 14px;
  color: #666;
  line-height: 1.5;
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

  .page-content {
    padding: 24px 16px;
  }

  .project-meta {
    flex-direction: column;
    gap: 12px;
  }
}
</style>
