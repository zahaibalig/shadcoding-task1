<template>
  <div class="landing-page">
    <div class="landing-container">
      <h1 class="landing-title">Welcome to Project Gallery</h1>

      <div class="button-group">
        <router-link to="/projects" class="btn btn-primary">
          View Projects
        </router-link>

        <router-link to="/admin" class="btn btn-login">
          Admin Login
        </router-link>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
// Landing page component - no logic needed
</script>

<style scoped>
.landing-page {
  min-height: 100vh;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.landing-container {
  text-align: center;
  max-width: 600px;
  width: 100%;
}

.landing-title {
  font-size: 48px;
  font-weight: 700;
  color: white;
  margin-bottom: 48px;
  text-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
}

.button-group {
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
}

.btn {
  display: inline-block;
  padding: 16px 48px;
  font-size: 18px;
  font-weight: 600;
  text-decoration: none;
  border-radius: 8px;
  transition: all 0.3s ease;
  min-width: 250px;
  text-align: center;
}

.btn-primary {
  background-color: white;
  color: #667eea;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 16px rgba(0, 0, 0, 0.2);
  background-color: #f8f9fa;
}

.btn-secondary {
  background-color: rgba(255, 255, 255, 0.2);
  color: white;
  border: 2px solid white;
}

.btn-secondary:hover {
  background-color: rgba(255, 255, 255, 0.3);
  transform: translateY(-2px);
}

.btn-login {
  background-color: transparent;
  color: white;
  border: 2px solid rgba(255, 255, 255, 0.5);
}

.btn-login:hover {
  border-color: white;
  background-color: rgba(255, 255, 255, 0.1);
  transform: translateY(-2px);
}

@media (max-width: 768px) {
  .landing-title {
    font-size: 32px;
    margin-bottom: 32px;
  }

  .btn {
    padding: 14px 32px;
    font-size: 16px;
    min-width: 200px;
  }
}
</style>
