// @ts-nocheck
import { doc, getDoc, collection, query, where, getDocs, orderBy } from 'firebase/firestore';
import { db } from '../firebase.js';

// Get user ID from URL
const urlParams = new URLSearchParams(window.location.search);
const userId = urlParams.get('id');

const loadingIndicator = document.getElementById('loadingIndicator');
const profileContainer = document.getElementById('profileContainer');

document.addEventListener('DOMContentLoaded', async () => {
  if (!userId) {
    alert("Aucun identifiant utilisateur fourni.");
    window.location.href = 'users.html';
    return;
  }
  
  setupTabs();
  
  try {
    await Promise.all([
      loadUserProfile(),
      loadUserPosts(),
      loadUserLikes(),
      loadUserProjects()
    ]);
  } catch (error) {
    console.error("Error loading user data:", error);
    alert("Erreur lors du chargement des données.");
  } finally {
    if (loadingIndicator) loadingIndicator.style.display = 'none';
    if (profileContainer) profileContainer.style.display = 'block';
  }
});

function setupTabs() {
  const tabBtns = document.querySelectorAll('.tab-btn');
  const tabContents = document.querySelectorAll('.tab-content');
  
  tabBtns.forEach(btn => {
    btn.addEventListener('click', () => {
      // Remove active from all
      tabBtns.forEach(b => b.classList.remove('active'));
      tabContents.forEach(c => c.classList.remove('active'));
      
      // Add active to current
      btn.classList.add('active');
      const targetId = btn.dataset.target;
      document.getElementById(targetId).classList.add('active');
    });
  });
}

async function loadUserProfile() {
  const userDoc = await getDoc(doc(db, 'users', userId));
  if (!userDoc.exists()) throw new Error("User not found");
  
  const user = userDoc.data();
  
  document.getElementById('detailName').innerHTML = `${user.name || user.fullName || 'Utilisateur inconnu'} <i class="ph-fill ph-seal-check text-primary" id="detailVerifiedIcon" style="display: none;"></i> <i class="ph-fill ph-star text-blue-500" id="detailPremiumIcon" style="display: none;" title="Abonné Premium"></i>`;
  document.getElementById('detailEmail').innerHTML = `<i class="ph ph-envelope"></i> ${user.email || 'Non spécifié'}`;
  document.getElementById('detailJob').innerHTML = `<i class="ph ph-briefcase"></i> ${user.professionalTitle || user.jobTitle || user.title || user.headline || 'Titre non spécifié'}`;
  document.getElementById('detailLocation').innerHTML = `<i class="ph ph-map-pin"></i> ${user.city || ''} ${user.country || 'Localisation non spécifiée'}`;
  
  const avatarUrl = user.photoURL || user.photoUrl || user.profileImageUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name || 'U')}&background=random`;
  document.getElementById('detailAvatar').src = avatarUrl;
  
  if (user.isVerified) {
    const icon = document.getElementById('detailVerifiedIcon');
    if (icon) icon.style.display = 'inline-block';
  }
  if (user.isPremium) {
    const pIcon = document.getElementById('detailPremiumIcon');
    if (pIcon) pIcon.style.display = 'inline-block';
  }

  const togglePremiumBtn = document.getElementById('togglePremiumBtn');
  const togglePremiumText = document.getElementById('togglePremiumText');
  if (togglePremiumBtn) {
    if (user.isPremium) {
      togglePremiumBtn.style.backgroundColor = 'var(--danger)';
      togglePremiumText.textContent = 'Révoquer Premium';
    } else {
      togglePremiumBtn.style.backgroundColor = 'var(--info)';
      togglePremiumText.textContent = 'Accorder Premium';
    }

    // Remove old listeners to avoid duplicates
    const newBtn = togglePremiumBtn.cloneNode(true);
    togglePremiumBtn.parentNode.replaceChild(newBtn, togglePremiumBtn);
    
    newBtn.addEventListener('click', async () => {
      const confirmMsg = user.isPremium 
        ? "Voulez-vous vraiment révoquer l'accès Premium de cet utilisateur ?" 
        : "Voulez-vous vraiment accorder l'accès Premium à cet utilisateur ?";
        
      if (confirm(confirmMsg)) {
        newBtn.disabled = true;
        newBtn.innerHTML = '<i class="ph ph-spinner ph-spin"></i> Traitement...';
        try {
          const userRef = doc(db, 'users', userId);
          await updateDoc(userRef, { isPremium: !user.isPremium });
          loadUserProfile(); // Reload profile to update UI
        } catch (error) {
          console.error("Erreur lors de la mise à jour :", error);
          alert("Erreur lors de la mise à jour du statut Premium.");
          newBtn.disabled = false;
          newBtn.innerHTML = '<i class="ph-fill ph-star"></i> <span id="togglePremiumText">Erreur</span>';
        }
      }
    });
  }
}

async function loadUserPosts() {
  const postsList = document.getElementById('postsList');
  
  try {
    const q = query(collection(db, 'posts'), where('authorId', '==', userId));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) {
      postsList.innerHTML = `<p class="text-secondary p-4">Aucune publication créée.</p>`;
      return;
    }
    
    let html = '';
    snapshot.forEach(doc => {
      const post = doc.data();
      const date = post.createdAt ? new Date(post.createdAt.seconds * 1000).toLocaleDateString('fr-FR') : 'Date inconnue';
      
      html += `
        <div class="content-card">
          <div class="content-card-header">
            <span>${date}</span>
            <span><i class="ph-fill ph-heart text-primary"></i> ${post.likesCount || (post.likedBy ? post.likedBy.length : 0)} likes</span>
          </div>
          <div class="mt-2 text-primary-contrast">${post.content || post.text || ''}</div>
          ${post.imageUrl ? `<img src="${post.imageUrl}" class="mt-4" style="max-height: 200px; border-radius: 8px;">` : ''}
        </div>
      `;
    });
    
    postsList.innerHTML = html;
  } catch (error) {
    postsList.innerHTML = `<p class="text-danger p-4">Erreur: Impossible de charger les publications. Il manque peut-être un index Firebase.</p>`;
  }
}

async function loadUserLikes() {
  const likesList = document.getElementById('likesList');
  
  try {
    const q = query(collection(db, 'posts'), where('likedBy', 'array-contains', userId));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) {
      likesList.innerHTML = `<p class="text-secondary p-4">Aucune publication aimée.</p>`;
      return;
    }
    
    let html = '';
    snapshot.forEach(doc => {
      const post = doc.data();
      
      html += `
        <div class="content-card">
          <div class="content-card-header">
            <span>Auteur ID: ${post.authorId || 'Inconnu'}</span>
            <span><i class="ph-fill ph-heart text-primary"></i> aimée</span>
          </div>
          <div class="mt-2 text-primary-contrast">${post.content || post.text || ''}</div>
        </div>
      `;
    });
    
    likesList.innerHTML = html;
  } catch (error) {
    likesList.innerHTML = `<p class="text-danger p-4">Erreur: Impossible de charger les likes. Il manque peut-être un index Firebase.</p>`;
  }
}

async function loadUserProjects() {
  const projectsList = document.getElementById('projectsList');
  
  try {
    const q = query(collection(db, 'projects'), where('userId', '==', userId));
    const snapshot = await getDocs(q);
    
    if (snapshot.empty) {
      projectsList.innerHTML = `<p class="text-secondary p-4">Aucun projet créé.</p>`;
      return;
    }
    
    let html = '';
    snapshot.forEach(doc => {
      const proj = doc.data();
      const date = proj.createdAt ? new Date(proj.createdAt.seconds * 1000).toLocaleDateString('fr-FR') : '';
      
      html += `
        <div class="content-card">
          <div class="content-card-header">
            <span>${date}</span>
            <span class="badge" style="background-color: var(--primary-transparent); color: var(--primary);">${proj.category || 'Général'}</span>
          </div>
          <h3 class="font-bold text-lg mt-2">${proj.title || 'Projet sans titre'}</h3>
          <p class="mt-2 text-secondary">${proj.description || ''}</p>
        </div>
      `;
    });
    
    projectsList.innerHTML = html;
  } catch (error) {
    projectsList.innerHTML = `<p class="text-danger p-4">Erreur: Impossible de charger les projets. Il manque peut-être un index Firebase.</p>`;
  }
}
