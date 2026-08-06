/* ─────────────────────────────────────────────────────────────
   Application Entry Point
   ───────────────────────────────────────────────────────────── */
import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@/styles/global.css';
import App from './App';

const rootElement = document.getElementById('root');

if (!rootElement) {
  throw new Error(
    'Root element #root not found. Please check index.html.',
  );
}

createRoot(rootElement).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
