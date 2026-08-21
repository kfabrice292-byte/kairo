import { defineConfig } from 'vite';
import { resolve } from 'path';

export default defineConfig({
  base: './',
  build: {
    outDir: 'dist',
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        login: resolve(__dirname, 'login.html'),
        applications: resolve(__dirname, 'applications.html'),
        companies: resolve(__dirname, 'companies.html'),
        agencies: resolve(__dirname, 'agencies.html'),
        subscriptions: resolve(__dirname, 'subscriptions.html'),
        opportunities: resolve(__dirname, 'opportunities.html'),
        projects: resolve(__dirname, 'projects.html'),
        publications: resolve(__dirname, 'publications.html'),
        reports: resolve(__dirname, 'reports.html'),
        settings: resolve(__dirname, 'settings.html'),
        user_detail: resolve(__dirname, 'user-detail.html'),
        users: resolve(__dirname, 'users.html'),
        verifications: resolve(__dirname, 'verifications.html'),
        admin: resolve(__dirname, 'admin.html'),
        kairo_pro: resolve(__dirname, 'kairo-pro.html'),
        pro_login: resolve(__dirname, 'pro-login.html')
      }
    }
  }
});
