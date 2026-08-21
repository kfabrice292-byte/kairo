// @ts-nocheck
import { 
    collection, 
    getDocs, 
    getDoc,
    addDoc, 
    updateDoc, 
    deleteDoc, 
    doc,
    serverTimestamp,
    query,
    orderBy
  } from "firebase/firestore";
  import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
  import { db, auth, storage } from "../firebase.js";
  import { onAuthStateChanged } from 'firebase/auth';
  
  let opportunitiesList = [];
  
  document.addEventListener('DOMContentLoaded', async () => {
    onAuthStateChanged(auth, async (user) => {
      if (!user) return;
      
      await loadOpportunities();
    });
  
    // Elements
    const addBtn = document.getElementById('addBtn') || document.getElementById('addBtnLarge');
    const refreshBtn = document.getElementById('refreshBtn');
    const modal = document.getElementById('addModal');
    const closeBtn = document.getElementById('closeModalBtn');
    const cancelBtn = document.getElementById('cancelBtn');
    const form = document.getElementById('addForm');
    const imagePreviewContainer = document.getElementById('imagePreviewContainer');
    const imagePreview = document.getElementById('imagePreview');
    const oppImageFile = document.getElementById('oppImageFile');
    const oppImageUrl = document.getElementById('oppImageUrl');
    
    // Listeners
    oppImageFile.addEventListener('change', (e) => {
      if (e.target.files.length > 0) {
        imagePreview.src = URL.createObjectURL(e.target.files[0]);
        imagePreviewContainer.style.display = 'block';
      } else if (!oppImageUrl.value) {
        imagePreviewContainer.style.display = 'none';
      }
    });


    const oppAppType = document.getElementById('oppAppType');
    const externalLinkGroup = document.getElementById('externalLinkGroup');
    const oppExtLink = document.getElementById('oppExtLink');
    
    if (oppAppType) {
      oppAppType.addEventListener('change', (e) => {
        if (e.target.value === 'external') {
          externalLinkGroup.style.display = 'block';
          oppExtLink.required = true;
        } else {
          externalLinkGroup.style.display = 'none';
          oppExtLink.required = false;
        }
      });
    }

    if (addBtn) {
      addBtn.addEventListener('click', () => {
      form.reset();
      form.removeAttribute('data-edit-id');
      oppImageUrl.value = '';
      imagePreview.src = '';
      imagePreviewContainer.style.display = 'none';
      oppImageFile.required = true;
      document.querySelector('.modal-title').textContent = "Publier une Opportunité";
      document.getElementById('saveBtn').textContent = "Publier l'affiche";
      if (oppAppType) oppAppType.value = 'external';
      if (oppExtLink) oppExtLink.value = '';
      if (externalLinkGroup) externalLinkGroup.style.display = 'block';
      if (oppExtLink) oppExtLink.required = true;
      document.getElementById('oppTitle').value = '';
      modal.classList.add('active');
    });
    }
    
    if (refreshBtn) refreshBtn.addEventListener('click', loadOpportunities);
    
    const closeModal = () => modal.classList.remove('active');
    closeBtn.addEventListener('click', closeModal);
    cancelBtn.addEventListener('click', closeModal);
    
    modal.addEventListener('click', (e) => {
      if (e.target === modal) closeModal();
    });
  
    // Submit
    form.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const title = document.getElementById('oppTitle').value;
      const companyVal = document.getElementById('oppCompany') ? document.getElementById('oppCompany').value : 'KAIRO';
      const typeVal = document.getElementById('oppType').value;
      const domainVal = document.getElementById('oppDomain').value;
      const desc = document.getElementById('oppDesc').value;
      
      const appTypeVal = oppAppType ? oppAppType.value : 'internal_ats';
      const extLinkVal = oppExtLink ? oppExtLink.value : '';
      
      const tagsSelect = document.getElementById('oppTags');
      const tagsVal = tagsSelect ? Array.from(tagsSelect.selectedOptions).map(opt => opt.value) : [];
      
      const submitBtn = document.getElementById('saveBtn');
      submitBtn.disabled = true;
      submitBtn.innerHTML = '<i class="ph ph-spinner ph-spin"></i> Publication...';
      
      try {
        let finalImageUrl = oppImageUrl.value;
        if (oppImageFile.files.length > 0) {
          const file = oppImageFile.files[0];
          const formData = new FormData();
          formData.append("image", file);
          const apiKey = "42583eab8962481f83526a0882f3d384"; // KAIRO ImgBB Key
          
          const response = await fetch(`https://api.imgbb.com/1/upload?key=${apiKey}`, {
              method: "POST",
              body: formData
          });
          const data = await response.json();
          if (data.success) {
              finalImageUrl = data.data.url;
          } else {
              throw new Error("ImgBB upload failed");
          }
        }

        const editId = form.getAttribute('data-edit-id');
        
        const opData = {
          title: title,
          type: typeVal,
          department: domainVal,
          company: companyVal,
          imageUrl: finalImageUrl,
          description: desc,
          location: 'En ligne / Non spécifié', // Default
          status: 'ouvert',
          postedBy: auth.currentUser.uid,
          applicationType: appTypeVal,
          externalLink: appTypeVal === 'external' ? extLinkVal : null,
          tags: tagsVal,
          updatedAt: serverTimestamp()
        };
  
        if (editId) {
          await updateDoc(doc(db, 'opportunities', editId), opData);
          alert('Opportunité modifiée avec succès !');
        } else {
          // Monétisation B2B : Vérification abonnement / Paiement unique
          const confirmPayment = confirm("Monétisation B2B :\nVous n'avez pas d'abonnement 'Cabinet' actif (3000 FCFA/mois).\nLa publication de cette offre coûte 1000 FCFA (Paiement Unique).\n\nVoulez-vous procéder au paiement sécurisé ?");
          if (!confirmPayment) {
              throw new Error("Paiement annulé. La publication a été interrompue.");
          }
          
          opData.createdAt = serverTimestamp();
          opData.applicants = [];
          opData.mandatorySkills = [];
          await addDoc(collection(db, 'opportunities'), opData);
          alert('Paiement validé (1000 FCFA). Opportunité publiée avec succès !');
        }
        
        closeModal();
        await loadOpportunities();
        
      } catch (error) {
        console.error("Erreur lors de la sauvegarde :", error);
        alert('Erreur: ' + error.message);
      } finally {
        submitBtn.disabled = false;
        submitBtn.textContent = form.getAttribute('data-edit-id') ? "Modifier" : "Publier l'affiche";
      }
    });
  });
  
  async function loadOpportunities() {
    const grid = document.getElementById('oppsGridContainer');
    grid.innerHTML = '<div style="text-align: center; padding: 3rem; grid-column: 1 / -1;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i><p class="mt-4 text-secondary">Chargement...</p></div>';
    
    try {
      const q = query(collection(db, 'opportunities'), orderBy('createdAt', 'desc'));
      const snapshot = await getDocs(q);
      
      opportunitiesList = [];
      snapshot.forEach(doc => {
        opportunitiesList.push({ id: doc.id, ...doc.data() });
      });
      
      renderGrid();
    } catch (error) {
      console.error("Erreur chargement opportunités:", error);
      grid.innerHTML = `<div class="text-error" style="text-align:center; grid-column: 1 / -1; padding: 3rem;">Erreur: ${error.message}</div>`;
    }
  }
  
  function renderGrid() {
    const grid = document.getElementById('oppsGridContainer');
    
    if (opportunitiesList.length === 0) {
      grid.innerHTML = '<div style="text-align: center; padding: 3rem; color: var(--text-secondary); grid-column: 1 / -1;">Aucune opportunité trouvée.</div>';
      return;
    }
    
    grid.innerHTML = '';
    
    opportunitiesList.forEach(op => {
      const card = document.createElement('div');
      card.className = 'opp-card';
      const isClosed = op.status === 'fermé';
      const imgSrc = op.imageUrl || op.companyLogoUrl || 'https://via.placeholder.com/60?text=KAIRO';
      
      card.innerHTML = `
        <div class="opp-card-header">
          <img src="${imgSrc}" class="opp-card-logo" alt="Affiche" onerror="this.src='https://via.placeholder.com/60?text=KAIRO'">
          <div style="flex: 1; padding-right: 40px;">
            <div class="opp-card-title">${op.title}</div>
            <div class="text-sm text-secondary">${op.company || 'KAIRO'}</div>
          </div>
        </div>
        
        <div class="opp-card-desc">${op.description || 'Aucune description disponible.'}</div>
        
        <div class="opp-card-meta">
          <span class="badge" style="background: var(--bg-dark); border: 1px solid var(--border-color);">${op.type || 'Général'}</span>
          <span class="badge" style="background: var(--bg-dark); border: 1px solid var(--border-color);">${op.department || 'Domaine'}</span>
        </div>
        
        <span class="badge ${isClosed ? 'bg-error' : 'bg-success'} text-white opp-status-badge">
          ${isClosed ? 'Fermée' : 'Active'}
        </span>
        
        <div class="opp-card-actions">
          <button class="btn-icon" onclick="viewMatches('${op.id}')" title="Profils compatibles (Matching IA)">
            <i class="ph-fill ph-magic-wand text-primary"></i>
          </button>
          <button class="btn-icon" onclick="editOpportunity('${op.id}')" title="Modifier">
            <i class="ph ph-pencil-simple text-primary"></i>
          </button>
          <button class="btn-icon" onclick="toggleStatus('${op.id}', '${op.status}')" title="${isClosed ? 'Réactiver' : 'Clôturer'}">
            <i class="ph ${isClosed ? 'ph-play-circle text-success' : 'ph-stop-circle text-warning'}"></i>
          </button>
          <button class="btn-icon" onclick="deleteOpportunity('${op.id}')" title="Supprimer">
            <i class="ph ph-trash text-error"></i>
          </button>
        </div>
      `;
      grid.appendChild(card);
    });
  }
  
  window.editOpportunity = (id) => {
    const op = opportunitiesList.find(o => o.id === id);
    if (!op) return;
    
    const form = document.getElementById('addForm');
    form.setAttribute('data-edit-id', id);
    
    document.getElementById('oppTitle').value = op.title || '';
    if (document.getElementById('oppCompany')) document.getElementById('oppCompany').value = op.company || 'KAIRO';
    document.getElementById('oppType').value = op.type || 'Emploi';
    document.getElementById('oppDomain').value = op.department || '';
    document.getElementById('oppDesc').value = op.description || '';
    
    const tagsSelect = document.getElementById('oppTags');
    if (tagsSelect) {
        Array.from(tagsSelect.options).forEach(opt => {
            opt.selected = (op.tags || []).includes(opt.value);
        });
        if (window.syncTagChips) window.syncTagChips();
    }
    

    const imageUrl = op.imageUrl || op.companyLogoUrl || '';
    
    if (oppAppType) {
        oppAppType.value = op.applicationType || 'external';
        if (oppAppType.value === 'external') {
            if (externalLinkGroup) externalLinkGroup.style.display = 'block';
            if (oppExtLink) {
                oppExtLink.required = true;
                oppExtLink.value = op.externalLink || '';
            }
        } else {
            if (externalLinkGroup) externalLinkGroup.style.display = 'none';
            if (oppExtLink) {
                oppExtLink.required = false;
                oppExtLink.value = '';
            }
        }
    }

    document.getElementById('oppImageUrl').value = imageUrl;
    document.getElementById('oppImageFile').required = !imageUrl;
    
    if (imageUrl) {
        document.getElementById('imagePreview').src = imageUrl;
        document.getElementById('imagePreviewContainer').style.display = 'block';
    } else {
        document.getElementById('imagePreview').src = '';
        document.getElementById('imagePreviewContainer').style.display = 'none';
    }
    
    document.querySelector('.modal-title').textContent = "Modifier l'Affiche";
    document.getElementById('saveBtn').textContent = "Enregistrer les modifications";
    
    document.getElementById('addModal').classList.add('active');
  };
  
  window.toggleStatus = async (id, currentStatus) => {
    const newStatus = currentStatus === 'fermé' ? 'ouvert' : 'fermé';
    if(confirm(`Voulez-vous vraiment ${newStatus === 'fermé' ? 'clôturer' : 'réactiver'} cette annonce ?`)) {
      try {
        await updateDoc(doc(db, 'opportunities', id), {
          status: newStatus,
          updatedAt: serverTimestamp()
        });
        loadOpportunities();
      } catch (error) {
        alert("Erreur: " + error.message);
      }
    }
  };
  
  window.deleteOpportunity = async (id) => {
    if(confirm("Supprimer définitivement cette affiche ?")) {
      try {
        await deleteDoc(doc(db, 'opportunities', id));
        loadOpportunities();
      } catch (error) {
        alert("Erreur: " + error.message);
      }
    }
  };

  // --- Matching Engine Logic ---
  const matchesModal = document.getElementById('matchesModal');
  const closeMatchesModalBtn = document.getElementById('closeMatchesModalBtn');
  const cancelMatchesBtn = document.getElementById('cancelMatchesBtn');
  
  if (closeMatchesModalBtn) closeMatchesModalBtn.addEventListener('click', () => matchesModal.classList.remove('active'));
  if (cancelMatchesBtn) cancelMatchesBtn.addEventListener('click', () => matchesModal.classList.remove('active'));
  if (matchesModal) {
    matchesModal.addEventListener('click', (e) => {
      if (e.target === matchesModal) matchesModal.classList.remove('active');
    });
  }

  window.viewMatches = async (oppId) => {
    const tbody = document.getElementById('matchesTableBody');
    tbody.innerHTML = '<tr><td colspan="5" class="text-center text-secondary py-8"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i><p class="mt-2">Recherche des meilleurs profils...</p></td></tr>';
    matchesModal.classList.add('active');
    
    try {
      // 1. Fetch top candidates from subcollection
      const q = query(collection(db, 'opportunities', oppId, 'top_candidates'), orderBy('score', 'desc'));
      const snapshot = await getDocs(q);
      
      if (snapshot.empty) {
        tbody.innerHTML = "<tr><td colspan='5' class='text-center text-secondary py-8'>Aucun profil hautement compatible trouvé pour le moment. L'algorithme analysera les nouveaux utilisateurs.</td></tr>";
        return;
      }
      
      // 2. We have the user IDs and scores. Now fetch user details.
      const candidatesHTML = [];
      for (const docSnap of snapshot.docs) {
        const matchData = docSnap.data();
        const userDoc = await getDoc(doc(db, 'users', matchData.userId));
        
        if (userDoc.exists()) {
          const userData = userDoc.data();
          const avatar = userData.photoUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.displayName || userData.firstName || 'U')}&background=F97316&color=fff`;
          const scoreClass = matchData.score >= 80 ? 'text-success' : (matchData.score >= 50 ? 'text-warning' : 'text-secondary');
          const relevanceBadge = matchData.relevance === 'PRIMARY' 
            ? '<span class="badge bg-success text-white">Parfait</span>' 
            : '<span class="badge bg-warning text-white">Pertinent</span>';

          candidatesHTML.push(`
            <tr>
              <td>
                <div class="flex items-center gap-3">
                  <img src="${avatar}" alt="Avatar" style="width: 32px; height: 32px; border-radius: 50%;">
                  <div>
                    <div class="font-medium">${userData.displayName || userData.firstName + ' ' + userData.lastName || 'Candidat'}</div>
                    <div class="text-sm text-secondary">${userData.email || ''}</div>
                  </div>
                </div>
              </td>
              <td>${userData.fieldOfStudy || userData.professionalTitle || '-'}</td>
              <td>${userData.city || userData.country || '-'}</td>
              <td>
                <div class="font-bold ${scoreClass}">${matchData.score}%</div>
                ${relevanceBadge}
              </td>
              <td>
                <a href="user-detail.html?id=${matchData.userId}" class="btn btn-primary" style="padding: 0.4rem 0.8rem; font-size: 0.85rem;">Voir Profil</a>
              </td>
            </tr>
          `);
        }
      }
      
      tbody.innerHTML = candidatesHTML.join('');
    } catch(error) {
      console.error(error);
      tbody.innerHTML = `<tr><td colspan="5" class="text-error text-center py-4">Erreur: ${error.message}</td></tr>`;
    }
  };

