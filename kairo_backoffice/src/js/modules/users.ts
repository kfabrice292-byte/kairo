// @ts-nocheck
import { collection, getDocs, updateDoc, doc, query, orderBy, limit } from 'firebase/firestore';
import { db } from '../firebase.js';

let users = [];
const tableBody = document.getElementById('usersTableBody');
const searchInput = document.getElementById('searchInput');

async function loadUsers() {
  if (!tableBody) return;
  
  try {
    // Fetch last 100 users to prevent massive payload initially
    const q = query(collection(db, 'users'), limit(200)); 
    const snapshot = await getDocs(q);
    
    users = [];
    snapshot.forEach((doc) => {
      users.push({ id: doc.id, ...doc.data() });
    });
    
    renderUsers(users);
  } catch (error) {
    console.error("Error loading users:", error);
    tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des utilisateurs.</td></tr>`;
  }
}

function renderUsers(usersToRender) {
  if (usersToRender.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucun utilisateur trouvé.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = usersToRender.map(user => {
    const avatar = user.photoUrl || user.profileImageUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name || 'U')}&background=random`;
    const isVerified = user.isVerified === true;
    
    return `
      <tr>
        <td>
          <div class="user-cell">
            <img src="${avatar}" alt="Avatar" class="user-cell-avatar">
            <div class="user-cell-info">
              <a href="user-detail.html?id=${user.id}" class="user-cell-name hover:text-primary transition-colors" style="text-decoration: none; font-weight: 600;">
                ${user.name || 'Utilisateur inconnu'}
                ${isVerified ? '<i class="ph-fill ph-seal-check text-primary" title="Vérifié"></i>' : ''}
              </a>
              <span class="user-cell-email">${user.email || 'Pas d\'email'}</span>
            </div>
          </div>
        </td>
        <td>
          <div class="font-medium">${user.jobTitle || user.title || 'Non spécifié'}</div>
          <div class="text-tertiary text-sm" style="max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            ${user.bio || ''}
          </div>
        </td>
        <td>${user.location || user.city || 'Non spécifié'}</td>
        <td>
          ${user.status === 'suspended' 
            ? '<span class="badge badge-danger">Suspendu</span>' 
            : '<span class="badge badge-success">Actif</span>'}
        </td>
        <td>
          <div class="actions-cell">
            <button class="btn-icon toggle-verify-btn" data-id="${user.id}" data-verified="${isVerified}" title="${isVerified ? 'Retirer la vérification' : 'Vérifier ce compte'}">
              <i class="ph-fill ${isVerified ? 'ph-x-circle text-danger' : 'ph-seal-check text-primary'}"></i>
            </button>
            <button class="btn-icon text-danger" title="Suspendre">
              <i class="ph ph-prohibit"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
  
  attachEventListeners();
}

function attachEventListeners() {
  const verifyBtns = document.querySelectorAll('.toggle-verify-btn');
  verifyBtns.forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const userId = e.currentTarget.dataset.id;
      const currentlyVerified = e.currentTarget.dataset.verified === 'true';
      
      try {
        const userRef = doc(db, 'users', userId);
        await updateDoc(userRef, {
          isVerified: !currentlyVerified
        });
        
        // Optimistic UI update
        const userIndex = users.findIndex(u => u.id === userId);
        if (userIndex > -1) {
          users[userIndex].isVerified = !currentlyVerified;
          
          // Re-render based on current search or all
          const searchTerm = searchInput.value.toLowerCase();
          if (searchTerm) {
            handleSearch({ target: { value: searchTerm } });
          } else {
            renderUsers(users);
          }
        }
      } catch (error) {
        console.error("Error updating user verification status:", error);
        alert("Erreur lors de la mise à jour de l'utilisateur.");
      }
    });
  });
}

function handleSearch(e) {
  const term = e.target.value.toLowerCase();
  const filtered = users.filter(u => {
    return (u.name && u.name.toLowerCase().includes(term)) || 
           (u.email && u.email.toLowerCase().includes(term));
  });
  renderUsers(filtered);
}

document.addEventListener('DOMContentLoaded', () => {
  loadUsers();
  
  if (searchInput) {
    searchInput.addEventListener('input', handleSearch);
  }
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadUsers();
    });
  }
});
