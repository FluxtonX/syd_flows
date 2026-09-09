/* ─────────────────────────────────────────────────────────────
   SubscriptionsPage – Configure Plans & Pricing
   Subscriber requests are managed in the dedicated Subscriber Requests page.
   SYD FLOWS Admin Design System
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect } from 'react';
import { AppLayout } from '@/components/layout/AppLayout/AppLayout';
import { ConfirmModal } from '@/components/ui/ConfirmModal/ConfirmModal';
import { Spinner } from '@/components/ui/Spinner/Spinner';
import {
  getSubscriptionPlansConfig,
  saveSubscriptionPlansConfig,
} from '@/services/firebase/firestore';
import { DEFAULT_SUBSCRIPTION_CONFIG } from '@/constants';
import type { SubscriptionPlansConfig } from '@/types';
import styles from './SubscriptionsPage.module.css';

export function SubscriptionsPage() {
  const [config, setConfig] = useState<SubscriptionPlansConfig>(DEFAULT_SUBSCRIPTION_CONFIG);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Reset defaults confirmation modal
  const [showResetConfirm, setShowResetConfirm] = useState(false);

  useEffect(() => {
    loadConfig();
  }, []);

  async function loadConfig() {
    setLoading(true);
    try {
      const fetchedConfig = await getSubscriptionPlansConfig();
      setConfig(fetchedConfig);
    } catch (err) {
      console.error('Failed to load subscription config:', err);
      showToast('Error loading subscription plans');
    } finally {
      setLoading(false);
    }
  }

  function showToast(msg: string) {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  }

  async function handleSaveConfig(e?: React.FormEvent) {
    if (e) e.preventDefault();
    setSaving(true);
    try {
      await saveSubscriptionPlansConfig(config);
      showToast('Subscription pricing & plans synced to mobile app live! 🚀');
    } catch (err: any) {
      showToast(err?.message || 'Failed to save subscription plans');
    } finally {
      setSaving(false);
    }
  }

  function handleResetDefaults() {
    setShowResetConfirm(false);
    setConfig(DEFAULT_SUBSCRIPTION_CONFIG);
    showToast('Reset to default plan values. Click Save to publish.');
  }

  function handlePlanChange(index: number, field: string, value: any) {
    setConfig((prev) => {
      const currentPlans = Array.isArray(prev?.plans) && prev.plans.length > 0
        ? [...prev.plans]
        : [...DEFAULT_SUBSCRIPTION_CONFIG.plans];
      currentPlans[index] = {
        ...currentPlans[index],
        [field]: value,
      };
      return {
        ...prev,
        plans: currentPlans,
      };
    });
  }

  const currentPlans = Array.isArray(config?.plans) && config.plans.length > 0
    ? config.plans
    : DEFAULT_SUBSCRIPTION_CONFIG.plans;

  const annualPlan = currentPlans.find((p) => p.id === 'annual') || currentPlans[0] || DEFAULT_SUBSCRIPTION_CONFIG.plans[0];
  const monthlyPlan = currentPlans.find((p) => p.id === 'monthly') || currentPlans[1] || DEFAULT_SUBSCRIPTION_CONFIG.plans[1];

  return (
    <AppLayout>
      <div className={styles.container}>
        {/* Top Header */}
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <h1 className={styles.title}>
              <div className={styles.titleIcon}>
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <path d="M12 2v20M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" />
                </svg>
              </div>
              Plans &amp; Pricing
            </h1>
            <p className={styles.subtitle}>
              Configure pricing, discounts, and trial offers. Changes sync live to the mobile app.
            </p>
          </div>

          <div className={styles.headerActions}>
            <button
              type="button"
              className={styles.saveBtnPrimary}
              onClick={() => handleSaveConfig()}
              disabled={saving || loading}
            >
              {saving ? (
                'Syncing...'
              ) : (
                <>
                  <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z" />
                    <polyline points="17 21 17 13 7 13 7 21" />
                    <polyline points="7 3 7 8 15 8" />
                  </svg>
                  Save & Sync Changes
                </>
              )}
            </button>
          </div>
        </div>

        {/* Plans & Pricing Settings */}
        {loading ? (
          <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '300px' }}>
            <Spinner size="lg" label="Loading subscription plans..." />
          </div>
        ) : (
          <form onSubmit={handleSaveConfig} className={styles.plansGrid}>
          <div className={styles.formColumn}>
            {/* Card 1: Screen Tagline & Hero Copy */}
            <div className={styles.cardSection}>
              <div className={styles.sectionHeader}>
                <div className={styles.sectionTitleGroup}>
                  <div className={styles.sectionTitleIcon}>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <circle cx="12" cy="12" r="10" />
                      <line x1="12" y1="8" x2="12" y2="12" />
                      <line x1="12" y1="16" x2="12.01" y2="16" />
                    </svg>
                  </div>
                  <h3 className={styles.sectionTitle}>Screen Branding & Hero Copy</h3>
                </div>
                <span className={styles.sectionTag}>Mobile Header</span>
              </div>

              <div className={styles.formGroup}>
                <label className={styles.label}>
                  Top Badge Tagline
                  <span className={styles.labelHint}>Displays inside pill tag</span>
                </label>
                <input
                  type="text"
                  className={styles.input}
                  value={config.heroTagline}
                  onChange={(e) => setConfig({ ...config, heroTagline: e.target.value })}
                  placeholder="e.g. PERSONALISED WELLNESS"
                />
              </div>

              <div className={styles.formRow}>
                <div className={styles.formGroup}>
                  <label className={styles.label}>
                    Hero Title
                    <span className={styles.labelHint}>Main value proposition</span>
                  </label>
                  <textarea
                    rows={2}
                    className={styles.textarea}
                    value={config.heroTitle}
                    onChange={(e) => setConfig({ ...config, heroTitle: e.target.value })}
                    placeholder="e.g. Feel supported\nin every phase."
                  />
                </div>
                <div className={styles.formGroup}>
                  <label className={styles.label}>
                    Hero Subtitle
                    <span className={styles.labelHint}>Supporting details</span>
                  </label>
                  <textarea
                    rows={2}
                    className={styles.textarea}
                    value={config.heroSubtitle}
                    onChange={(e) => setConfig({ ...config, heroSubtitle: e.target.value })}
                    placeholder="Unlock the complete workout library..."
                  />
                </div>
              </div>
            </div>

            {/* Card 2: Annual Plan (Best Value) */}
            {annualPlan && (
              <div className={`${styles.cardSection} ${styles.cardSectionHighlight}`}>
                <div className={styles.sectionHeader}>
                  <div className={styles.sectionTitleGroup}>
                    <div className={styles.sectionTitleIcon} style={{ color: 'var(--color-primary)' }}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2" />
                      </svg>
                    </div>
                    <h3 className={styles.sectionTitle}>Annual Subscription Plan</h3>
                  </div>
                  <span className={styles.sectionTag}>Featured Plan</span>
                </div>

                <div className={styles.formRow}>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Plan Title</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={annualPlan.title}
                      onChange={(e) => handlePlanChange(0, 'title', e.target.value)}
                      placeholder="Annual Plan"
                    />
                  </div>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Badge Label</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={annualPlan.badge || ''}
                      onChange={(e) => handlePlanChange(0, 'badge', e.target.value)}
                      placeholder="BEST VALUE"
                    />
                  </div>
                </div>

                <div className={styles.formRow}>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Headline Price (e.g. $4.99)</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={annualPlan.price}
                      onChange={(e) => handlePlanChange(0, 'price', e.target.value)}
                      placeholder="$4.99"
                    />
                  </div>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Billing Period Label</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={annualPlan.period}
                      onChange={(e) => handlePlanChange(0, 'period', e.target.value)}
                      placeholder="/ month (billed annually)"
                    />
                  </div>
                </div>

                <div className={styles.formRow}>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Trial / Offer Subtitle</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={annualPlan.subtitle}
                      onChange={(e) => handlePlanChange(0, 'subtitle', e.target.value)}
                      placeholder="First 7 days free, then $59.99/yr"
                    />
                  </div>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Total Charged Detail</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={annualPlan.detail}
                      onChange={(e) => handlePlanChange(0, 'detail', e.target.value)}
                      placeholder="$59.99 charged annually"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Card 3: Monthly Plan */}
            {monthlyPlan && (
              <div className={styles.cardSection}>
                <div className={styles.sectionHeader}>
                  <div className={styles.sectionTitleGroup}>
                    <div className={styles.sectionTitleIcon}>
                      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <circle cx="12" cy="12" r="10" />
                        <polyline points="12 6 12 12 16 14" />
                      </svg>
                    </div>
                    <h3 className={styles.sectionTitle}>Monthly Subscription Plan</h3>
                  </div>
                  <span className={styles.sectionTag} style={{ background: 'var(--color-surface)' }}>Standard Plan</span>
                </div>

                <div className={styles.formRow}>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Plan Title</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={monthlyPlan.title}
                      onChange={(e) => handlePlanChange(1, 'title', e.target.value)}
                      placeholder="Monthly Plan"
                    />
                  </div>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Price (e.g. $9.99)</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={monthlyPlan.price}
                      onChange={(e) => handlePlanChange(1, 'price', e.target.value)}
                      placeholder="$9.99"
                    />
                  </div>
                </div>

                <div className={styles.formRow}>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Subtitle</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={monthlyPlan.subtitle}
                      onChange={(e) => handlePlanChange(1, 'subtitle', e.target.value)}
                      placeholder="Flexible, cancel anytime"
                    />
                  </div>
                  <div className={styles.formGroup}>
                    <label className={styles.label}>Billing Detail</label>
                    <input
                      type="text"
                      className={styles.input}
                      value={monthlyPlan.detail}
                      onChange={(e) => handlePlanChange(1, 'detail', e.target.value)}
                      placeholder="Billed monthly"
                    />
                  </div>
                </div>
              </div>
            )}

            {/* Bottom Sticky Action Footer */}
            <div className={styles.stickyFooter}>
              <button type="button" className={styles.resetBtnSecondary} onClick={() => setShowResetConfirm(true)}>
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                  <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" />
                  <path d="M21 3v5h-5" />
                  <path d="M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16" />
                  <path d="M8 16H3v5" />
                </svg>
                Reset Defaults
              </button>
              <button type="submit" className={styles.saveBtnPrimary} disabled={saving || loading}>
                {saving ? (
                  'Syncing...'
                ) : (
                  <>
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                    Save & Sync to App
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Live Mobile Preview Column */}
          <div className={styles.previewStickyWrapper}>
            <div className={styles.previewHeading}>
              <span className={styles.previewHeadingTitle}>Live App Preview</span>
              <span className={styles.liveDot}>Syncing Live</span>
            </div>

            <div className={styles.previewPhone}>
              <div className={styles.previewNotch} />
              <div className={styles.previewTagline}>SYD FLOWS PREMIUM</div>
              <div className={styles.previewAppTitle}>Upgrade your flow</div>

              {/* Hero preview */}
              <div className={styles.previewHeroCard}>
                <div className={styles.previewHeroTag}>{config.heroTagline || 'PERSONALISED WELLNESS'}</div>
                <div className={styles.previewHeroTitle}>{config.heroTitle}</div>
                <div className={styles.previewHeroSubtitle}>{config.heroSubtitle}</div>
              </div>

              <div className={styles.previewPlansSectionTitle}>CHOOSE YOUR PLAN</div>

              {/* Annual Plan Card Preview */}
              {annualPlan && (
                <div className={styles.previewPlanCard}>
                  <div>
                    <div className={styles.previewPlanTitle}>
                      {annualPlan.title}
                      {annualPlan.badge && <span className={styles.previewBadge}>{annualPlan.badge}</span>}
                    </div>
                    <div className={styles.previewPlanSubtitle}>{annualPlan.subtitle}</div>
                    <div className={styles.previewPlanDetail}>{annualPlan.detail}</div>
                  </div>
                  <div>
                    <div className={styles.previewPlanPrice}>{annualPlan.price}</div>
                    <div className={styles.previewPlanPeriod}>{annualPlan.period}</div>
                  </div>
                </div>
              )}

              {/* Monthly Plan Card Preview */}
              {monthlyPlan && (
                <div className={`${styles.previewPlanCard} ${styles.previewPlanCardSecondary}`}>
                  <div>
                    <div className={styles.previewPlanTitle}>{monthlyPlan.title}</div>
                    <div className={styles.previewPlanSubtitle}>{monthlyPlan.subtitle}</div>
                    <div className={styles.previewPlanDetail}>{monthlyPlan.detail}</div>
                  </div>
                  <div>
                    <div className={styles.previewPlanPrice}>{monthlyPlan.price}</div>
                    <div className={styles.previewPlanPeriod}>{monthlyPlan.period}</div>
                  </div>
                </div>
              )}

              <div className={styles.previewMainButton}>
                Start 7-day free trial
              </div>
            </div>
          </div>
        </form>
        )}

        {/* Reset Confirmation Modal */}
        <ConfirmModal
          isOpen={showResetConfirm}
          title="Reset to Default Settings?"
          message="Are you sure you want to reset all plan details and branding copy to default values? You will still need to click Save to sync with the mobile app."
          confirmLabel="Reset Defaults"
          confirmVariant="danger"
          onConfirm={handleResetDefaults}
          onCancel={() => setShowResetConfirm(false)}
        />

        {/* Floating Toast */}
        {toastMessage && (
          <div className={styles.toast}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="var(--color-primary)" strokeWidth="2.5">
              <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
              <polyline points="22 4 12 14.01 9 11.01" />
            </svg>
            {toastMessage}
          </div>
        )}
      </div>
    </AppLayout>
  );
}
