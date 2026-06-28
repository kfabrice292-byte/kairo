import { defineConfig } from 'vite';
import { resolve } from 'path';
import tailwindcss from '@tailwindcss/vite';

export default defineConfig({
  base: './',
  plugins: [
    tailwindcss(),
  ],
  build: {
    rollupOptions: {
      input: {
        main: resolve(__dirname, 'index.html'),
        login: resolve(__dirname, 'login.html'),
        register: resolve(__dirname, 'register.html'),
        dashboard: resolve(__dirname, 'dashboard.html'),
        profile: resolve(__dirname, 'profile.html'),
        builder: resolve(__dirname, 'builder.html'),
        cvBuilder: resolve(__dirname, 'cv-builder.html'),
        letter: resolve(__dirname, 'letter.html'),
        opportunities: resolve(__dirname, 'opportunities.html'),
        admin: resolve(__dirname, 'admin.html')
      }
    }
  }
});
