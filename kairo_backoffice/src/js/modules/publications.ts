// @ts-nocheck
import { collection, getDocs, deleteDoc, doc, query, limit, getDoc } from 'firebase/firestore';
import { db } from '../firebase.js';

let posts = [];
const tableBody = document.getElementById('postsTableBody');

async function loadPosts() {
  if (!tableBody) return;
  
  try {
    const q = query(collection(db, 'posts'), limit(100)); 
    const snapshot = await getDocs(q);
    
    posts = [];
    
    // We might need to fetch user names if not embedded in the post doc
    for (let document of snapshot.docs) {
      const data = document.data();
      let authorName = data.authorName || 'Inconnu';
      
      // If authorName is not in post, try to fetch it
      if (!data.authorName && data.userId) {
        try {
            const userSnap = await getDoc(doc(db, 'users', data.userId));
            if (userSnap.exists()) {
                authorName = userSnap.data().name || 'Inconnu';
            }
        } catch(e) {}
      }
      
      posts.push({ id: document.id, authorName, ...data });
    }
    
    renderPosts(posts);
  } catch (error) {
    console.error("Error loading posts:", error);
    tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des publications.</td></tr>`;
  }
}

function renderPosts(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucune publication trouvée.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    let content = item.content || item.text || '';
    if (content.length > 80) content = content.substring(0, 80) + '...';
    
    const date = item.createdAt ? new Date(item.createdAt.seconds * 1000).toLocaleDateString('fr-FR') : 'Inconnue';
    
    return `
      <tr>
        <td><div class="font-medium">${item.authorName}</div></td>
        <td><div style="max-width: 300px; white-space: normal;">${content}</div></td>
        <td>${date}</td>
        <td>
          <span class="badge" style="background-color: var(--primary-transparent); color: var(--primary);">
            <i class="ph ph-heart"></i> ${item.likesCount || 0}
          </span>
          <span class="badge" style="background-color: rgba(255,255,255,0.1); color: var(--text-secondary); margin-left: 0.5rem;">
            <i class="ph ph-chat-circle"></i> ${item.commentsCount || 0}
          </span>
        </td>
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
      if (confirm("Êtes-vous sûr de vouloir supprimer cette publication ?")) {
        try {
          await deleteDoc(doc(db, 'posts', id));
          posts = posts.filter(p => p.id !== id);
          renderPosts(posts);
        } catch (error) {
          console.error("Error deleting post:", error);
          alert("Erreur lors de la suppression.");
        }
      }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadPosts();
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadPosts();
    });
  }
});
