/* ─────────────────────────────────────────────────────────────
   Config Error Page
   Rendered when Firebase / Cloudinary env vars are not set.
   ───────────────────────────────────────────────────────────── */
import styles from './ConfigErrorPage.module.css';

export function ConfigErrorPage() {
  return (
    <div className={styles.page}>
      <div className={styles.card}>
        <div className={styles.iconWrap} aria-hidden="true">⚙️</div>

        <h1 className={styles.title}>Configuration Required</h1>
        <p className={styles.subtitle}>
          Firebase and Cloudinary environment variables are not set.
          Create a <code style={{ color: 'var(--color-secondary)', fontFamily: 'monospace' }}>.env</code> file
          in the <code style={{ color: 'var(--color-secondary)', fontFamily: 'monospace' }}>web_admin/</code> folder
          and fill in your credentials.
        </p>

        {/* Steps */}
        <div className={styles.section}>
          <p className={styles.sectionTitle}>Setup Steps</p>
          <ol className={styles.steps}>
            <li className={styles.step}>
              <span className={styles.stepNum}>1</span>
              Copy <code style={{ color: 'var(--color-primary)', fontFamily: 'monospace' }}>.env.example</code> to <code style={{ color: 'var(--color-primary)', fontFamily: 'monospace' }}>.env</code> in the <code style={{ fontFamily: 'monospace' }}>web_admin/</code> folder
            </li>
            <li className={styles.step}>
              <span className={styles.stepNum}>2</span>
              Fill in your Firebase project credentials (from Firebase Console → Project Settings)
            </li>
            <li className={styles.step}>
              <span className={styles.stepNum}>3</span>
              Fill in your Cloudinary Cloud Name and unsigned Upload Preset (from Cloudinary Dashboard → Settings → Upload)
            </li>
            <li className={styles.step}>
              <span className={styles.stepNum}>4</span>
              Click <strong style={{ color: 'var(--color-text-primary)' }}>Reload Page</strong> after saving the file
            </li>
          </ol>
        </div>

        {/* .env template */}
        <div className={styles.section}>
          <p className={styles.sectionTitle}>.env Template</p>
          <div className={styles.codeBlock}>
            <span className={styles.envVar}>VITE_FIREBASE_API_KEY</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>your_api_key{'\n'}</span>
            <span className={styles.envVar}>VITE_FIREBASE_AUTH_DOMAIN</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>your_project.firebaseapp.com{'\n'}</span>
            <span className={styles.envVar}>VITE_FIREBASE_PROJECT_ID</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>syd-flows{'\n'}</span>
            <span className={styles.envVar}>VITE_FIREBASE_STORAGE_BUCKET</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>your_project.appspot.com{'\n'}</span>
            <span className={styles.envVar}>VITE_FIREBASE_APP_ID</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>your_app_id{'\n'}</span>
            {'\n'}
            <span className={styles.envVar}>VITE_CLOUDINARY_CLOUD_NAME</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>your_cloud_name{'\n'}</span>
            <span className={styles.envVar}>VITE_CLOUDINARY_UPLOAD_PRESET</span>
            <span className={styles.envEq}>=</span>
            <span className={styles.envVal}>your_upload_preset</span>
          </div>
        </div>

        <button
          id="reload-page-btn"
          className={styles.reloadBtn}
          onClick={() => window.location.reload()}
        >
          Reload Page After Saving .env
        </button>
      </div>
    </div>
  );
}
