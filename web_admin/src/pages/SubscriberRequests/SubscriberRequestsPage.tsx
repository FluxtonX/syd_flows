/* ─────────────────────────────────────────────────────────────
   SubscriberRequestsPage – Manage subscriber entitlement requests
   Ultra-Premium UI Layout & Executive Stats Summary
   SYD FLOWS Admin Design System
   ───────────────────────────────────────────────────────────── */
import { useState, useEffect } from 'react';
import { AppLayout } from '@/components/layout/AppLayout/AppLayout';
import { ConfirmModal } from '@/components/ui/ConfirmModal/ConfirmModal';
import {
  getAllSubscriptionRequests,
  approveSubscriptionRequest,
  revokeUserSubscription,
  deleteSubscriptionRequest,
} from '@/services/firebase/firestore';
import type { SubscriptionRequestRecord } from '@/types';
import styles from './SubscriberRequestsPage.module.css';

export function SubscriberRequestsPage() {
  const [requests, setRequests] = useState<SubscriptionRequestRecord[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'pending' | 'approved' | 'cancelled'>('all');
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  const [modalAction, setModalAction] = useState<{
    type: 'approve' | 'revoke' | 'delete';
    request: SubscriptionRequestRecord;
  } | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  useEffect(() => {
    loadRequests();
  }, []);

  async function loadRequests() {
    setLoading(true);
    try {
      const fetched = await getAllSubscriptionRequests();
      setRequests(fetched);
    } catch (err) {
      console.error('Failed to load subscriber requests:', err);
      showToast('Error loading subscriber requests');
    } finally {
      setLoading(false);
    }
  }

  function showToast(msg: string) {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  }

  async function handleConfirmModal() {
    if (!modalAction) return;
    setActionLoading(true);
    const { type, request } = modalAction;

    try {
      if (type === 'approve') {
        await approveSubscriptionRequest(request.userId, request.id, request.planId);
        showToast(`Approved subscription for ${request.userEmail || request.userId} 🎉`);
      } else if (type === 'revoke') {
        await revokeUserSubscription(request.userId, request.id);
        showToast(`Revoked subscription for ${request.userEmail || request.userId}`);
      } else if (type === 'delete') {
        await deleteSubscriptionRequest(request.userId, request.id);
        showToast(`Deleted request for ${request.userEmail || request.userId}`);
      }
      setModalAction(null);
      const updated = await getAllSubscriptionRequests();
      setRequests(updated);
    } catch (err: unknown) {
      if (err instanceof Error) {
        showToast(err.message);
      } else {
        showToast('Operation failed');
      }
    } finally {
      setActionLoading(false);
    }
  }

  const filteredRequests = requests.filter((req) => {
    const matchesQuery =
      (req.userEmail || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (req.displayName || '').toLowerCase().includes(searchQuery.toLowerCase()) ||
      (req.userId || '').toLowerCase().includes(searchQuery.toLowerCase());

    if (!matchesQuery) return false;
    if (statusFilter === 'all') return true;
    if (statusFilter === 'pending') return req.status === 'pending';
    if (statusFilter === 'approved') return req.status === 'approved' || req.status === 'active';
    if (statusFilter === 'cancelled') return req.status === 'cancelled' || req.status === 'rejected';
    return true;
  });

  const pendingCount = requests.filter((r) => r.status === 'pending').length;
  const approvedCount = requests.filter((r) => r.status === 'approved' || r.status === 'active').length;
  const cancelledCount = requests.filter((r) => r.status === 'cancelled' || r.status === 'rejected').length;

  return (
    <AppLayout>
      <div className={styles.container}>
        {/* Page Header */}
        <div className={styles.header}>
          <div className={styles.headerLeft}>
            <h1 className={styles.title}>
              <div className={styles.titleIcon}>
                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                  <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
                  <circle cx="9" cy="7" r="4" />
                  <path d="M23 21v-2a4 4 0 0 0-3-3.87" />
                  <path d="M16 3.13a4 4 0 0 1 0 7.75" />
                </svg>
              </div>
              Subscriber Requests
            </h1>
            <p className={styles.subtitle}>
              Review, approve or revoke premium subscription access for SYD FLOWS users.
              {pendingCount > 0 && (
                <span className={styles.pendingBadge}>
                  <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                    <circle cx="12" cy="12" r="10" />
                    <polyline points="12 6 12 12 16 14" />
                  </svg>
                  {pendingCount} pending review
                </span>
              )}
            </p>
          </div>

          <div className={styles.headerActions}>
            <button
              type="button"
              className={styles.refreshBtn}
              onClick={loadRequests}
              disabled={loading}
            >
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                <path d="M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8" />
                <path d="M21 3v5h-5" />
              </svg>
              {loading ? 'Refreshing...' : 'Refresh Data'}
            </button>
          </div>
        </div>

        {/* Executive Stats Bar */}
        <div className={styles.statsGrid}>
          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconTotal}`}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                <path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2" />
                <circle cx="9" cy="7" r="4" />
                <path d="M22 21v-2a4 4 0 0 0-3-3.87" />
                <path d="M16 3.13a4 4 0 0 1 0 7.75" />
              </svg>
            </div>
            <div className={styles.statInfo}>
              <span className={styles.statLabel}>Total Requests</span>
              <span className={styles.statValue}>{requests.length}</span>
            </div>
          </div>

          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconPending}`}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                <circle cx="12" cy="12" r="10" />
                <polyline points="12 6 12 12 16 14" />
              </svg>
            </div>
            <div className={styles.statInfo}>
              <span className={styles.statLabel}>Pending Review</span>
              <span className={styles.statValue}>{pendingCount}</span>
            </div>
          </div>

          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconApproved}`}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14" />
                <polyline points="22 4 12 14.01 9 11.01" />
              </svg>
            </div>
            <div className={styles.statInfo}>
              <span className={styles.statLabel}>Approved Access</span>
              <span className={styles.statValue}>{approvedCount}</span>
            </div>
          </div>

          <div className={styles.statCard}>
            <div className={`${styles.statIcon} ${styles.statIconRevoked}`}>
              <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2">
                <circle cx="12" cy="12" r="10" />
                <line x1="15" y1="9" x2="9" y2="15" />
                <line x1="9" y1="9" x2="15" y2="15" />
              </svg>
            </div>
            <div className={styles.statInfo}>
              <span className={styles.statLabel}>Revoked Access</span>
              <span className={styles.statValue}>{cancelledCount}</span>
            </div>
          </div>
        </div>

        {/* Requests Card */}
        <div className={styles.requestsCard}>
          {/* Toolbar */}
          <div className={styles.tableToolbar}>
            <div className={styles.searchBox}>
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                <circle cx="11" cy="11" r="8" />
                <line x1="21" y1="21" x2="16.65" y2="16.65" />
              </svg>
              <input
                type="text"
                placeholder="Search by email, name or user ID..."
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
              />
              {searchQuery && (
                <button
                  type="button"
                  className={styles.clearSearchBtn}
                  onClick={() => setSearchQuery('')}
                >
                  <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <line x1="18" y1="6" x2="6" y2="18" />
                    <line x1="6" y1="6" x2="18" y2="18" />
                  </svg>
                </button>
              )}
            </div>

            <div className={styles.filterGroup}>
              {(['all', 'pending', 'approved', 'cancelled'] as const).map((filter) => (
                <button
                  key={filter}
                  className={`${styles.filterBtn} ${statusFilter === filter ? styles.filterBtnActive : ''}`}
                  onClick={() => setStatusFilter(filter)}
                >
                  {filter.charAt(0).toUpperCase() + filter.slice(1)}
                  {filter === 'pending' && pendingCount > 0 && (
                    <span className={styles.badgeCount}>{pendingCount}</span>
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Table */}
          <div className={styles.tableWrapper}>
            {loading ? (
              <div className={styles.emptyState}>
                <div className={styles.emptyIcon}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="12" cy="12" r="10" />
                    <path d="M12 6v6l4 2" />
                  </svg>
                </div>
                <span>Loading subscriber requests...</span>
              </div>
            ) : filteredRequests.length === 0 ? (
              <div className={styles.emptyState}>
                <div className={styles.emptyIcon}>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                    <circle cx="11" cy="11" r="8" />
                    <line x1="21" y1="21" x2="16.65" y2="16.65" />
                  </svg>
                </div>
                <span>
                  {searchQuery || statusFilter !== 'all'
                    ? 'No requests match your current search/filter.'
                    : 'No subscription requests found.'}
                </span>
              </div>
            ) : (
              <table className={styles.table}>
                <thead>
                  <tr>
                    <th>Customer</th>
                    <th>Selected Plan</th>
                    <th>Status</th>
                    <th>Source</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredRequests.map((req) => {
                    const initial = (req.displayName || req.userEmail || 'U').trim()[0].toUpperCase();

                    return (
                      <tr key={req.id}>
                        <td>
                          <div className={styles.userCell}>
                            <div className={styles.avatarCircle}>{initial}</div>
                            <div className={styles.userInfo}>
                              <span className={styles.userName}>{req.displayName || 'App User'}</span>
                              <span className={styles.userEmail}>{req.userEmail || req.userId}</span>
                            </div>
                          </div>
                        </td>
                        <td>
                          <span className={styles.planBadge}>
                            {req.planId?.toLowerCase().includes('annual') ? '✨' : '⚡'}
                            {req.planId ? req.planId.charAt(0).toUpperCase() + req.planId.slice(1) : 'Annual'} Plan
                          </span>
                        </td>
                        <td>
                          <span
                            className={`${styles.statusPill} ${
                              req.status === 'approved' || req.status === 'active'
                                ? styles.statusApproved
                                : req.status === 'cancelled' || req.status === 'rejected'
                                ? styles.statusCancelled
                                : styles.statusPending
                            }`}
                          >
                            <span className={styles.statusDot} />
                            {req.status === 'approved' || req.status === 'active'
                              ? 'Approved'
                              : req.status === 'cancelled' || req.status === 'rejected'
                              ? 'Revoked'
                              : 'Pending'}
                          </span>
                        </td>
                        <td>
                          <span className={styles.sourceBadge}>
                            📱 {req.source ? req.source.replace(/_/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase()) : 'Mobile App'}
                          </span>
                        </td>
                        <td>
                          <div className={styles.actionBtns}>
                            {req.status !== 'approved' && req.status !== 'active' && (
                              <button
                                className={styles.approveBtn}
                                onClick={() => setModalAction({ type: 'approve', request: req })}
                              >
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                                  <polyline points="20 6 9 17 4 12" />
                                </svg>
                                Approve &amp; Unlock
                              </button>
                            )}

                            {(req.status === 'approved' || req.status === 'active') && (
                              <button
                                className={styles.revokeBtn}
                                onClick={() => setModalAction({ type: 'revoke', request: req })}
                              >
                                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
                                  <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                                  <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                                </svg>
                                Revoke Access
                              </button>
                            )}

                            <button
                              className={styles.deleteBtn}
                              title="Delete request"
                              onClick={() => setModalAction({ type: 'delete', request: req })}
                            >
                              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                <polyline points="3 6 5 6 21 6" />
                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" />
                              </svg>
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Confirmation Modal */}
        <ConfirmModal
          isOpen={!!modalAction}
          title={
            modalAction?.type === 'approve'
              ? 'Approve Subscription Access'
              : modalAction?.type === 'revoke'
              ? 'Revoke Premium Subscription'
              : 'Delete Subscription Request'
          }
          message={
            modalAction?.type === 'approve'
              ? `Are you sure you want to approve this subscription request and unlock full premium workout access for ${
                  modalAction.request.userEmail || modalAction.request.userId
                }?`
              : modalAction?.type === 'revoke'
              ? `Are you sure you want to revoke premium access for ${
                  modalAction?.request.userEmail || modalAction?.request.userId
                }? The user will immediately revert to standard access.`
              : `Are you sure you want to permanently delete this subscription request record?`
          }
          confirmLabel={
            actionLoading
              ? 'Processing...'
              : modalAction?.type === 'approve'
              ? 'Approve & Unlock'
              : modalAction?.type === 'revoke'
              ? 'Revoke Access'
              : 'Delete'
          }
          confirmVariant={modalAction?.type === 'approve' ? 'primary' : 'danger'}
          onConfirm={handleConfirmModal}
          onCancel={() => setModalAction(null)}
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
