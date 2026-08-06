/* ─────────────────────────────────────────────────────────────
   App Router – Defines all routes with auth protection
   ───────────────────────────────────────────────────────────── */
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { LoginPage } from '@/pages/Login/LoginPage';
import { DashboardPage } from '@/pages/Dashboard/DashboardPage';
import { VideosPage } from '@/pages/Videos/VideosPage';
import { UploadVideoPage } from '@/pages/UploadVideo/UploadVideoPage';
import { AuthGuard } from '@/components/layout/AuthGuard/AuthGuard';
import { ROUTES } from '@/constants';

export function AppRouter() {
  return (
    <BrowserRouter>
      <Routes>
        {/* Public */}
        <Route path={ROUTES.LOGIN} element={<LoginPage />} />

        {/* Protected */}
        <Route
          path={ROUTES.DASHBOARD}
          element={
            <AuthGuard>
              <DashboardPage />
            </AuthGuard>
          }
        />
        <Route
          path={ROUTES.VIDEOS}
          element={
            <AuthGuard>
              <VideosPage />
            </AuthGuard>
          }
        />
        <Route
          path={ROUTES.UPLOAD}
          element={
            <AuthGuard>
              <UploadVideoPage />
            </AuthGuard>
          }
        />

        {/* Root redirect */}
        <Route path={ROUTES.ROOT} element={<Navigate to={ROUTES.DASHBOARD} replace />} />

        {/* 404 fallback */}
        <Route path="*" element={<Navigate to={ROUTES.DASHBOARD} replace />} />
      </Routes>
    </BrowserRouter>
  );
}
