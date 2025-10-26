import { createRouter, createWebHistory } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      name: 'landing',
      component: () => import('@/views/LandingView.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/projects',
      name: 'projects',
      component: () => import('@/views/ProjectsView.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/car-registration',
      name: 'carRegistration',
      component: () => import('@/views/CarRegistrationView.vue'),
      meta: { requiresAuth: false },
    },
    // {
    //   path: '/about',
    //   name: 'about',
    //   component: () => import('@/views/AboutView.vue'),
    //   meta: { requiresAuth: false },
    // },
    {
      path: '/admin',
      name: 'adminLogin',
      component: () => import('@/views/AdminDashboardView.vue'),
      meta: { requiresAuth: false },
    },
    {
      path: '/admin/dashboard',
      name: 'adminDashboard',
      component: () => import('@/views/HomeView.vue'),
      meta: { requiresAuth: true },
    },
  ],
})

// Navigation guard to protect routes
router.beforeEach((to, from, next) => {
  const authStore = useAuthStore()
  const requiresAuth = to.meta.requiresAuth

  // Initialize auth store if not already done
  if (!authStore.user && authStore.accessToken) {
    authStore.initialize()
  }

  if (requiresAuth && !authStore.isAuthenticated) {
    // Redirect to admin login if trying to access protected route
    next({ name: 'adminLogin' })
  } else if (to.name === 'adminLogin' && authStore.isAuthenticated) {
    // Redirect to admin dashboard if trying to access login page while already authenticated
    next({ name: 'adminDashboard' })
  } else {
    next()
  }
})

export default router
