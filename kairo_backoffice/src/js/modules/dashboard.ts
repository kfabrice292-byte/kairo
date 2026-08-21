// @ts-nocheck
import { collection, getCountFromServer, query, where } from 'firebase/firestore';
import { db } from '../firebase.js';

async function safeGetCount(ref, elementId) {
  const el = document.getElementById(elementId);
  if (!el) return;
  
  try {
    const snapshot = await getCountFromServer(ref);
    el.textContent = snapshot.data().count;
  } catch (error) {
    console.error(`Error loading count for ${elementId}:`, error);
    el.textContent = 'N/A';
    el.title = "Erreur de permission ou de connexion";
  }
}

async function loadStats() {
  // Refs
  const usersRef = collection(db, 'users');
  const postsRef = collection(db, 'posts');
  const projectsRef = collection(db, 'projects');
  const opportunitiesRef = collection(db, 'opportunities');
  const reportsRef = collection(db, 'reports');

  // Queries
  const verifiedUsersQuery = query(usersRef, where('isVerified', '==', true));
  const premiumUsersQuery = query(usersRef, where('isPremium', '==', true));
  const agenciesQuery = query(collection(db, 'companies'), where('type', '==', 'agency'));
  const expiredSubsQuery = query(collection(db, 'subscriptions'), where('status', '==', 'expired'));
  const atsAppsRef = collection(db, 'applications');

  // Fetch counts independently to prevent one failure from crashing the whole dashboard
  await Promise.all([
    safeGetCount(usersRef, 'stat-users'),
    safeGetCount(postsRef, 'stat-posts'),
    safeGetCount(projectsRef, 'stat-projects'),
    safeGetCount(opportunitiesRef, 'stat-opportunities'),
    safeGetCount(verifiedUsersQuery, 'stat-verified'),
    safeGetCount(premiumUsersQuery, 'stat-premium'),
    safeGetCount(reportsRef, 'stat-reports'),
    safeGetCount(agenciesQuery, 'stat-agencies'),
    safeGetCount(expiredSubsQuery, 'stat-expired-subs'),
    safeGetCount(atsAppsRef, 'stat-ats-applications')
  ]);

  // Calculate Revenue (Estimate: 1000 FCFA per premium user)
  const premiumEl = document.getElementById('stat-premium');
  const revEl = document.getElementById('stat-revenue');
  if (premiumEl && revEl && premiumEl.textContent !== '...' && premiumEl.textContent !== 'N/A') {
    const premiumCount = parseInt(premiumEl.textContent, 10) || 0;
    const rev = premiumCount * 1000;
    revEl.textContent = rev.toLocaleString('fr-FR') + ' FCFA';
  } else if (revEl) {
    revEl.textContent = '0 FCFA';
  }
}

// Init
document.addEventListener('DOMContentLoaded', () => {
  loadStats();

  const refreshBtn = document.getElementById('refreshDashboardBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', async () => {
      refreshBtn.disabled = true;
      refreshBtn.innerHTML = '<i class="ph ph-spinner ph-spin"></i> Rafraîchissement...';
      
      // Reset UI briefly
      const ids = ['stat-users', 'stat-posts', 'stat-projects', 'stat-opportunities', 'stat-verified', 'stat-reports'];
      ids.forEach(id => {
        const el = document.getElementById(id);
        if (el) el.textContent = '...';
      });

      await loadStats();
      
      refreshBtn.disabled = false;
      refreshBtn.innerHTML = '<i class="ph ph-arrows-clockwise"></i> Rafraîchir';
    });
  }
});
