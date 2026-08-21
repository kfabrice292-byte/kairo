// @ts-nocheck
import { collection, getDocs, deleteDoc, doc, query, limit } from 'firebase/firestore';
import { db } from '../firebase.js';

let reports = [];
const tableBody = document.getElementById('reportsTableBody');

async function loadReports() {
  if (!tableBody) return;
  
  try {
    const q = query(collection(db, 'reports'), limit(100)); 
    const snapshot = await getDocs(q);
    
    reports = [];
    snapshot.forEach((doc) => {
      reports.push({ id: doc.id, ...doc.data() });
    });
    
    renderReports(reports);
  } catch (error) {
    console.error("Error loading reports:", error);
    tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des signalements.</td></tr>`;
  }
}

function renderReports(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucun signalement en attente.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    const date = item.createdAt ? new Date(item.createdAt.seconds * 1000).toLocaleDateString('fr-FR') : 'Inconnue';
    
    return `
      <tr>
        <td>
          <span class="badge" style="background-color: var(--border-color-light);">${item.targetType || 'Contenu'}</span><br>
          <span class="text-sm text-tertiary">ID: ${item.targetId || 'N/A'}</span>
        </td>
        <td><div class="font-medium text-danger">${item.reason || 'Non spécifié'}</div></td>
        <td>${item.reporterId || 'Utilisateur inconnu'}</td>
        <td>${date}</td>
        <td>
          <div class="actions-cell">
            <button class="btn-icon text-success delete-btn" data-id="${item.id}" title="Ignorer / Traité (Supprimer le signalement)">
              <i class="ph ph-check-circle"></i>
            </button>
            <button class="btn-icon text-danger" title="Voir / Modérer la cible">
              <i class="ph ph-eye"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
  
  attachEventListeners();
}

function attachEventListeners() {
  const deleteBtns = document.querySelectorAll('.delete-btn');
  deleteBtns.forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const id = e.currentTarget.dataset.id;
      if (confirm("Marquer ce signalement comme traité ? (Il sera supprimé de la liste)")) {
        try {
          await deleteDoc(doc(db, 'reports', id));
          reports = reports.filter(r => r.id !== id);
          renderReports(reports);
        } catch (error) {
          console.error("Error deleting report:", error);
          alert("Erreur lors de la suppression.");
        }
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadReports();
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadReports();
    });
  }
});
