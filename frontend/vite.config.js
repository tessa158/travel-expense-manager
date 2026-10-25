import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

// The dev server forwards /api calls to the Express backend, so the browser sees one origin
// (this keeps the secure session cookie simple and avoids CORS problems).
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: { '/api': { target: 'http://localhost:4000', changeOrigin: false } },
  },
});
