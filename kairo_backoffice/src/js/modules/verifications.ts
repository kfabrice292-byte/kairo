// @ts-nocheck
import { collection, getDocs, deleteDoc, doc, updateDoc, query, where, orderBy } from 'firebase/firestore';
import { db } from '../firebase.js';

let verifications = [];
const tableBody = document.getElementById('verificationsTableBody');

async function loadVerifications() {
  if (!tableBody) return;
  
  try {
    // Demandes de vérification en attente (on suppose que isVerified = false ou pendingVerification = true)
    // Pour simplifier, on cherche ceux qui ont 'pendingVerification' == true
    const q = query(collection(db, 'users'), where('pendingVerification', '==', true));
    const snapshot = await getDocs(q);
    
    verifications = [];
    snapshot.forEach((doc) => {
      verifications.push({ id: doc.id, ...doc.data() });
    });
    
    renderVerifications(verifications);
  } catch (error) {
    console.error("Error loading verifications:", error);
    
    // Fallback if index missing or pendingVerification doesn't exist
    try {
      const allQ = query(collection(db, 'users'));
      const allSnap = await getDocs(allQ);
      verifications = [];
      allSnap.forEach(d => {
        const data = d.data();
        if (data.pendingVerification) verifications.push({ id: d.id, ...data });
      });
      renderVerifications(verifications);
    } catch(e) {
      tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des demandes.</td></tr>`;
    }
  }
}

function renderVerifications(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucune demande de vérification en attente.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    const avatar = item.photoUrl || item.profileImageUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(item.name || 'U')}&background=random`;
    
    return `
      <tr>
        <td>
          <div class="user-cell">
            <img src="${avatar}" alt="Avatar" class="user-cell-avatar">
            <div class="user-cell-info">
              <a href="user-detail.html?id=${item.id}" class="user-cell-name font-medium hover:text-primary transition-colors" style="text-decoration: none;">
                ${item.name || item.fullName || 'Sans nom'}
              </a>
              <span class="user-cell-email">${item.email || 'Pas d\'email'}</span>
            </div>
          </div>
        </td>
        <td><span class="badge" style="background-color: var(--bg-card); border: 1px solid var(--border-color);">${item.accountType || item.role || 'Général'}</span></td>
        <td>Récemment</td>
        <td>
          <span class="badge badge-warning">En attente</span>
        </td>
        <td>
          <div class="actions-cell">
            <button class="btn btn-primary approve-btn" data-id="${item.id}" style="padding: 4px 12px; font-size: 0.8rem;">
              <i class="ph ph-check"></i> Accepter
            </button>
            <button class="btn btn-secondary reject-btn" data-id="${item.id}" style="padding: 4px 12px; font-size: 0.8rem; background-color: var(--danger-transparent); color: var(--danger); border-color: transparent;">
              Refuser
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
  
  attachEventListeners();
}

function attachEventListeners() {
  const approveBtns = document.querySelectorAll('.approve-btn');
  const rejectBtns = document.querySelectorAll('.reject-btn');
  
  approveBtns.forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const id = e.currentTarget.dataset.id;
      if (confirm("Valider ce profil et lui attribuer le badge certifié ?")) {
        try {
          await updateDoc(doc(db, 'users', id), {
            isVerified: true,
            pendingVerification: false
          });
          verifications = verifications.filter(v => v.id !== id);
          renderVerifications(verifications);
        } catch (error) {
          console.error("Error approving:", error);
          alert("Erreur lors de la validation.");
        }
      }
    });
  });

  rejectBtns.forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const id = e.currentTarget.dataset.id;
      if (confirm("Refuser cette demande ? (Le compte restera non vérifié)")) {
        try {
          await updateDoc(doc(db, 'users', id), {
            pendingVerification: false
          });
          verifications = verifications.filter(v => v.id !== id);
          renderVerifications(verifications);
        } catch (error) {
          console.error("Error rejecting:", error);
          alert("Erreur lors du refus.");
        }
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadVerifications();
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadVerifications();
    });
  }
});
