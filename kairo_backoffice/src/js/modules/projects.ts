// @ts-nocheck
import { collection, getDocs, deleteDoc, doc, query, limit, getDoc } from 'firebase/firestore';
import { db } from '../firebase.js';

let projects = [];
const tableBody = document.getElementById('projectsTableBody');

async function loadProjects() {
  if (!tableBody) return;
  
  try {
    const q = query(collection(db, 'projects'), limit(100)); 
    const snapshot = await getDocs(q);
    
    projects = [];
    
    for (let document of snapshot.docs) {
      const data = document.data();
      let authorName = 'Inconnu';
      
      if (data.userId) {
        try {
            const userSnap = await getDoc(doc(db, 'users', data.userId));
            if (userSnap.exists()) {
                authorName = userSnap.data().name || 'Inconnu';
            }
        } catch(e) {}
      }
      
      projects.push({ id: document.id, authorName, ...data });
    }
    
    renderProjects(projects);
  } catch (error) {
    console.error("Error loading projects:", error);
    tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des projets.</td></tr>`;
  }
}

function renderProjects(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucun projet trouvé.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    const date = item.createdAt ? new Date(item.createdAt.seconds * 1000).toLocaleDateString('fr-FR') : 'Inconnue';
    
    return `
      <tr>
        <td>
          <div class="font-medium">${item.title || 'Projet sans titre'}</div>
        </td>
        <td>${item.authorName}</td>
        <td><span class="badge" style="background-color: var(--primary-transparent); color: var(--primary);">${item.category || 'Général'}</span></td>
        <td>${date}</td>
        <td>
          <div class="actions-cell">
            <button class="btn-icon text-danger delete-btn" data-id="${item.id}" title="Supprimer">
              <i class="ph ph-trash"></i>
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
      if (confirm("Êtes-vous sûr de vouloir supprimer ce projet ?")) {
        try {
          await deleteDoc(doc(db, 'projects', id));
          projects = projects.filter(p => p.id !== id);
          renderProjects(projects);
        } catch (error) {
          console.error("Error deleting project:", error);
          alert("Erreur lors de la suppression.");
        }
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadProjects();
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadProjects();
    });
  }
});
