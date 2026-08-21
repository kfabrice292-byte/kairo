// @ts-nocheck
import { collection, getDocs, deleteDoc, doc, addDoc, query, orderBy, Timestamp } from 'firebase/firestore';
import { db } from '../firebase.js';

let subscriptions = [];
const tableBody = document.getElementById('subscriptionsTableBody');
const refreshBtn = document.getElementById('refreshBtn');

async function loadSubscriptions() {
  if (!tableBody) return;
  
  try {
    const q = query(collection(db, 'subscriptions'), orderBy('startDate', 'desc'));
    const snapshot = await getDocs(q);
    
    subscriptions = [];
    snapshot.forEach((doc) => {
      subscriptions.push({ id: doc.id, ...doc.data() });
    });
    
    renderSubscriptions(subscriptions);
  } catch (error) {
    console.error("Error loading subscriptions:", error);
    try {
        const fallbackQ = query(collection(db, 'subscriptions'));
        const fallbackSnap = await getDocs(fallbackQ);
        subscriptions = [];
        fallbackSnap.forEach((doc) => {
          subscriptions.push({ id: doc.id, ...doc.data() });
        });
        renderSubscriptions(subscriptions);
    } catch(e) {
        tableBody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">Erreur lors du chargement des abonnements.</td></tr>`;
    }
  }
}

function renderSubscriptions(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="6" style="text-align: center; padding: 2rem;">Aucun abonnement trouvé.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    const start = item.startDate ? new Date(item.startDate.seconds * 1000).toLocaleDateString() : '-';
    const end = item.endDate ? new Date(item.endDate.seconds * 1000).toLocaleDateString() : '-';
    
    let statusBadge = '';
    if (item.status === 'active') statusBadge = `<span class="badge" style="background-color: var(--success-transparent); color: var(--success);">Actif</span>`;
    else if (item.status === 'expired') statusBadge = `<span class="badge" style="background-color: var(--danger-transparent); color: var(--danger);">Expiré</span>`;
    else statusBadge = `<span class="badge">${item.status || 'Inconnu'}</span>`;

    return `
      <tr>
        <td><span class="font-medium">${item.entityId || 'Client'}</span></td>
        <td><span class="badge" style="background-color: var(--primary-transparent); color: var(--primary);">${item.entityType === 'user' ? 'Utilisateur' : (item.entityType === 'company' ? 'Entreprise' : 'Agence')}</span></td>
        <td>${item.planName || '-'}</td>
        <td>${item.amount ? item.amount + ' FCFA' : '0 FCFA'}</td>
        <td>${start} - ${end}</td>
        <td>${statusBadge}</td>
      </tr>
    `;
  }).join('');
}

document.addEventListener('DOMContentLoaded', () => {
  loadSubscriptions();
  
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="6" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadSubscriptions();
    });
  }
  
  const addBtn = document.getElementById('addBtn');
  if (addBtn) {
    addBtn.addEventListener('click', () => {
      alert("La création manuelle d'abonnements sera disponible dans une prochaine mise à jour.");
    });
  }
});
