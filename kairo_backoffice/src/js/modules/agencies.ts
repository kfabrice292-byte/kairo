// @ts-nocheck
import { auth, db } from '../firebase.js';
import { onAuthStateChanged } from 'firebase/auth';
import { collection, getDocs, doc, getDoc, collection as subcollection, updateDoc, serverTimestamp, query, where, addDoc } from 'firebase/firestore';

document.addEventListener('DOMContentLoaded', () => {
  console.log("KAIRO PRO ATS - Agencies Module Loaded");

  // Authentication & Security Guard
  onAuthStateChanged(auth, async (user) => {
    if (!user) {
      window.location.href = 'pro-login.html';
      return;
    }

    try {
      // Verify role
      const userDoc = await getDoc(doc(db, 'users', user.uid));
      const userData = userDoc.data();
      if (!userData || (userData.role !== 'agency' && userData.role !== 'admin')) {
        console.error("Accès refusé : vous n'êtes pas une entreprise.");
        window.location.href = 'pro-login.html';
        return;
      }
      
      // Update topbar with company name
      const topbarName = document.getElementById('topbar-user-name');
      const topbarAvatar = document.getElementById('topbar-user-avatar');
      const companyName = userData.companyName || userData.displayName || 'Entreprise';
      if (topbarName) topbarName.textContent = companyName;
      if (topbarAvatar) topbarAvatar.textContent = companyName.charAt(0).toUpperCase();
      
      const agencyType = userData.agencyType || 'company';
      if (agencyType === 'cabinet') {
        const menuTeam = document.getElementById('menu-team');
        const menuReporting = document.getElementById('menu-reporting');
        const clientGroup = document.getElementById('offerClientGroup');
        if (menuTeam) menuTeam.style.display = 'flex';
        if (menuReporting) menuReporting.style.display = 'flex';
        if (clientGroup) clientGroup.style.display = 'block';
      }

      initATS(user, companyName);
      loadSettings(user, userData);
      loadTalents();
    } catch (error) {
      console.error("Error verifying user role:", error);
      window.location.href = 'pro-login.html';
    }
  });
});

let currentOfferId = null;

async function initATS(user, companyName) {
  // Sidebar Navigation Logic
  const sidebarLinks = document.querySelectorAll('.sidebar-nav .nav-item');
  const mainSections = document.querySelectorAll('.main-section');
  
  sidebarLinks.forEach(link => {
    link.addEventListener('click', (e) => {
      e.preventDefault();
      // Remove active from all links
      sidebarLinks.forEach(l => l.classList.remove('active'));
      // Add active to clicked link
      link.classList.add('active');
      
      // Hide all sections
      mainSections.forEach(section => {
        (section as HTMLElement).style.display = 'none';
        section.classList.remove('active');
      });
      
      // Show target section
      const targetId = link.getAttribute('data-section');
      if (targetId) {
        const targetSection = document.getElementById(targetId);
        if (targetSection) {
          targetSection.style.display = 'block';
          targetSection.classList.add('active');
        }
      }
    });
  });

  // Top Tabs logic (within Dashboard)
  const tabs = document.querySelectorAll('.kairo-tab');
  const views = document.querySelectorAll('.kairo-view');

  tabs.forEach(tab => {
    tab.addEventListener('click', () => {
      // Remove active from all
      tabs.forEach(t => t.classList.remove('active'));
      views.forEach(v => {
        v.classList.remove('active');
        (v as HTMLElement).style.display = 'none';
      });
      // Add active to clicked
      tab.classList.add('active');
      const targetId = tab.getAttribute('data-target');
      const targetView = document.getElementById(targetId);
      if (targetView) {
        targetView.classList.add('active');
        targetView.style.display = 'block';
      }
      
      (tab as HTMLElement).style.borderBottomColor = 'var(--primary)';
      (tab as HTMLElement).style.color = 'var(--primary)';
      tabs.forEach(t => {
        if(t !== tab) {
          (t as HTMLElement).style.borderBottomColor = 'transparent';
          (t as HTMLElement).style.color = 'var(--text-secondary)';
        }
      });
    });
  });

  // Init SortableJS for Drag and Drop Kanban
  const columns = ['col-new', 'col-evaluating', 'col-interview', 'col-hired'];
  columns.forEach(colId => {
    const el = document.getElementById(colId);
    if (el) {
      new Sortable(el, {
        group: 'kanban',
        animation: 150,
        ghostClass: 'sortable-ghost',
        dragClass: 'sortable-drag',
        onEnd: function (evt) {
          const itemEl = evt.item;  // dragged HTMLElement
          const toList = evt.to;    // target list
          const candidateId = itemEl.getAttribute('data-id');
          const newStatus = toList.parentElement.getAttribute('data-status');
          
          console.log(`Candidate ${candidateId} moved to ${newStatus}`);
          updateCandidateStatus(candidateId, newStatus);
        },
      });
    }
  });

  // Modal Logic for "Nouvelle Offre"
  const addOfferBtn = document.getElementById('addOfferBtn');
  const createOfferModal = document.getElementById('createOfferModal');
  const closeOfferModalBtn = document.getElementById('closeOfferModal');
  const cancelOfferBtn = document.getElementById('cancelOfferBtn');
  const createOfferForm = document.getElementById('createOfferForm') as HTMLFormElement;
  
  const openModal = () => { if (createOfferModal) createOfferModal.style.display = 'flex'; };
  const closeModal = () => { 
    if (createOfferModal) createOfferModal.style.display = 'none'; 
    if (createOfferForm) createOfferForm.reset();
  };

  if (addOfferBtn) addOfferBtn.addEventListener('click', openModal);
  if (closeOfferModalBtn) closeOfferModalBtn.addEventListener('click', closeModal);
  if (cancelOfferBtn) cancelOfferBtn.addEventListener('click', closeModal);
  
  if (createOfferForm) {
    createOfferForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const title = (document.getElementById('offerTitle') as HTMLInputElement).value;
      const contract = (document.getElementById('offerContract') as HTMLSelectElement).value;
      const location = (document.getElementById('offerLocation') as HTMLInputElement).value;
      const desc = (document.getElementById('offerDesc') as HTMLTextAreaElement).value;
      const requireCV = (document.getElementById('offerRequireCV') as HTMLInputElement).checked;
      const requirePortfolio = (document.getElementById('offerRequirePortfolio') as HTMLInputElement).checked;
      const client = (document.getElementById('offerClient') as HTMLInputElement)?.value || '';
      const saveBtn = document.getElementById('saveOfferBtn') as HTMLButtonElement;
      
      if (saveBtn) {
        saveBtn.disabled = true;
        saveBtn.textContent = 'Publication...';
      }
      
      try {
        await addDoc(collection(db, 'opportunities'), {
          title: title,
          contractType: contract,
          location: location,
          description: desc,
          client: client,
          requireCV: requireCV,
          requirePortfolio: requirePortfolio,
          companyId: user.uid,
          company: companyName,
          status: 'active',
          createdAt: serverTimestamp()
        });
        
        closeModal();
        await loadOffers(user.uid); // Refresh list
        
        // Switch to "Mes Offres" tab if not already there
        const offersTabBtn = document.querySelector('[data-target="offersView"]') as HTMLElement;
        if (offersTabBtn) offersTabBtn.click();
        
      } catch (error) {
        console.error("Error creating offer:", error);
        alert("Erreur lors de la création de l'offre.");
      } finally {
        if (saveBtn) {
          saveBtn.disabled = false;
          saveBtn.textContent = "Publier l'offre";
        }
      }
    });
  }

  // Load Offers
  await loadOffers(user.uid);
}

async function loadOffers(userId) {
  try {
    const offersRef = collection(db, 'opportunities');
    const q = query(offersRef, where('companyId', '==', userId));
    const snapshot = await getDocs(q);

    
    const selector = document.getElementById('offerSelector');
    const grid = document.getElementById('offersGrid');
    
    selector.innerHTML = '<option value="">Sélectionner une offre...</option>';
    grid.innerHTML = '';
    
    if (snapshot.empty) {
      selector.innerHTML = '<option value="">Aucune offre trouvée</option>';
      grid.innerHTML = '<p>Aucune offre publiée.</p>';
      return;
    }

    let isFirst = true;

    snapshot.forEach(doc => {
      const data = doc.data();
      const oppId = doc.id;
      
      // Select Options
      const option = document.createElement('option');
      option.value = oppId;
      option.textContent = data.title || 'Offre sans titre';
      selector.appendChild(option);

      // Grid Cards
      const card = document.createElement('div');
      card.style.cssText = 'background: white; border: 1px solid var(--border-color); border-radius: 16px; padding: 20px; box-shadow: 0 4px 12px rgba(0,0,0,0.02);';
      card.innerHTML = `
        <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 8px;">
          <h3 style="font-weight: 700; font-size: 1.1rem;">${data.title}</h3>
          <span style="background: var(--primary); color: white; padding: 4px 12px; border-radius: 20px; font-size: 0.75rem; font-weight: 600;">Active</span>
        </div>
        <p style="color: var(--text-secondary); font-size: 0.9rem; margin-bottom: 12px;"><i class="ph ph-map-pin"></i> ${data.location || 'Non précisé'} • ${data.contractType || 'CDI'}</p>
        <p style="color: var(--text-secondary); font-size: 0.85rem; margin-bottom: 16px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;">${data.description || 'Aucune description.'}</p>
        <div style="display: flex; justify-content: space-between; align-items: center; border-top: 1px solid var(--border-color); padding-top: 16px;">
          <button class="btn btn-secondary share-offer-btn" data-id="${oppId}" style="padding: 6px 12px; font-size: 0.85rem; display: flex; align-items: center; gap: 4px;">
            <i class="ph ph-link"></i> Partager
          </button>
          <button class="btn btn-primary view-pipeline-btn" data-id="${oppId}" style="padding: 6px 12px; font-size: 0.85rem;">Voir le pipeline</button>
        </div>
      `;
      grid.appendChild(card);
    });
    
    // Add event listeners to "Partager" buttons
    document.querySelectorAll('.share-offer-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const oppId = (e.currentTarget as HTMLElement).getAttribute('data-id');
        if (oppId) {
          const shareUrl = `${window.location.origin}/apply.html?id=${oppId}`;
          navigator.clipboard.writeText(shareUrl).then(() => {
            const toast = document.getElementById('toastNotification');
            if (toast) {
              toast.style.display = 'flex';
              setTimeout(() => { toast.style.display = 'none'; }, 3000);
            }
          });
        }
      });
    });

    snapshot.forEach(doc => {
      const oppId = doc.id;
      if (isFirst) {
        currentOfferId = oppId;
        selector.value = oppId;
        loadPipeline(oppId);
        isFirst = false;
      }
    });

    selector.addEventListener('change', (e) => {
      if (e.target.value) {
        currentOfferId = e.target.value;
        loadPipeline(currentOfferId);
      }
    });

    document.querySelectorAll('.view-pipeline-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        const id = e.target.getAttribute('data-id');
        currentOfferId = id;
        selector.value = id;
        document.querySelector('[data-target="pipelineView"]').click();
        loadPipeline(id);
      });
    });

  } catch (error) {
    console.error("Error loading offers:", error);
  }
}

async function loadPipeline(oppId) {
  console.log("Loading pipeline for offer:", oppId);
  
  // Clear columns and show loading state
  ['col-new', 'col-evaluating', 'col-interview', 'col-hired'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = '<div style="padding: 16px; color: var(--text-secondary); text-align: center; font-size: 0.875rem;">Chargement...</div>';
  });

  try {
    const applicantsRef = subcollection(doc(db, 'opportunities', oppId), 'applicants');
    const snapshot = await getDocs(applicantsRef);

    let applicantsData = [];

    if (snapshot.empty) {
      console.log("No applicants found.");
      // Optionnel : afficher "Aucun candidat" dans les colonnes
    } else {
      snapshot.forEach(d => {
        applicantsData.push({ id: d.id, ...d.data() });
      });
    }

    renderPipelineCards(applicantsData);

  } catch (error) {
    console.error("Error loading pipeline:", error);
  }
}

function renderPipelineCards(candidates) {
  const counts = { new: 0, evaluating: 0, interview: 0, hired: 0 };

  // Clear loading text first
  ['col-new', 'col-evaluating', 'col-interview', 'col-hired'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.innerHTML = '';
  });

  candidates.forEach(cand => {
    const status = cand.status || 'new';
    if(counts[status] !== undefined) counts[status]++;
    
    const colId = `col-${status}`;
    const colEl = document.getElementById(colId);
    
    if (colEl) {
      const card = document.createElement('div');
      card.className = 'kanban-card';
      card.setAttribute('data-id', cand.id);
      
      // Badge color based on score
      let scoreColor = '#10B981'; // Green
      if (cand.score < 80) scoreColor = '#F59E0B'; // Orange
      if (cand.score < 60) scoreColor = '#EF4444'; // Red

      card.innerHTML = `
        <div class="kanban-card-title">${cand.name}</div>
        <div class="kanban-card-subtitle">${cand.role || 'Candidat'}</div>
        <div class="kanban-card-footer">
          <span style="display: flex; align-items: center; gap: 4px; font-weight: 500; color: var(--text-secondary)">
            <i class="ph ph-calendar-blank"></i> Il y a 2h
          </span>
          <button class="btn-icon view-cand-btn" data-id="${cand.id}" title="Voir Fiche" style="padding: 4px;">
            <i class="ph ph-eye"></i>
          </button>
        </div>
      `;
      colEl.appendChild(card);
    }
  });

  // Update counts
  document.getElementById('count-new').textContent = counts.new;
  document.getElementById('count-evaluating').textContent = counts.evaluating;
  document.getElementById('count-interview').textContent = counts.interview;
  document.getElementById('count-hired').textContent = counts.hired;
}

function updateCandidateStatus(candidateId, newStatus) {
  console.log(`Update ${candidateId} status to ${newStatus} in Firebase...`);
  // Re-calculate counts
  const columns = ['new', 'evaluating', 'interview', 'hired'];
  columns.forEach(status => {
    const col = document.getElementById(`col-${status}`);
    if (col) {
      const count = col.querySelectorAll('.kanban-card').length;
      document.getElementById(`count-${status}`).textContent = count;
    }
  });

  // Update in Firestore
  if (currentOfferId && candidateId) {
    try {
      const applicantDoc = doc(db, 'opportunities', currentOfferId, 'applicants', candidateId);
      updateDoc(applicantDoc, {
        status: newStatus,
        updatedAt: serverTimestamp()
      });
      console.log("Firestore updated successfully.");
    } catch (err) {
      console.error("Error updating document in Firestore:", err);
      alert("Erreur lors de la mise à jour du statut.");
    }
  }
}

// Slide-over logic
document.addEventListener('click', (e) => {
  const target = e.target as HTMLElement;
  const btn = target.closest('.view-cand-btn');
  if (btn) {
    const candidateId = btn.getAttribute('data-id');
    if (candidateId) {
      openCandidateSlideOver(candidateId);
    }
  }
});

const slideOverOverlay = document.getElementById('candidateSlideOver');
const slideOverContent = document.querySelector('.slide-over-content') as HTMLElement | null;
const closeSlideOverBtn = document.getElementById('closeSlideOverBtn');

async function openCandidateSlideOver(candidateId: string, applicantData?: any) {
  if (!slideOverOverlay || !slideOverContent) return;
  slideOverOverlay.style.display = 'block';
  // Small delay for CSS transition
  setTimeout(() => {
    slideOverContent.style.transform = 'translateX(0)';
  }, 10);
  
  const contentEl = document.getElementById('candidateDetailsContent');
  if (contentEl) {
    contentEl.innerHTML = `
      <div style="text-align: center; padding: 40px;">
        <i class="ph ph-spinner ph-spin text-3xl text-primary"></i>
        <p style="margin-top: 12px; color: var(--text-secondary);">Chargement du profil...</p>
      </div>
    `;
  }
  
  try {
    let talent: any = null;
    // Essayons de récupérer depuis la base globale
    const userDoc = await getDoc(doc(db, 'users', candidateId));
    if (userDoc.exists()) {
      talent = userDoc.data();
    } else if (applicantData) {
      // Candidat externe (n'est pas dans users, mais dans applicants)
      talent = applicantData;
    }
    
    if (!contentEl) return;
    
    if (!talent) {
      contentEl.innerHTML = `<p style="color: var(--danger); padding: 24px;">Candidat introuvable.</p>`;
      return;
    }
    
    const initial = (talent.name || talent.displayName || 'C').charAt(0).toUpperCase();
    const title = talent.professionalTitle || talent.currentRole || 'Candidat';
    const location = [talent.city, talent.country].filter(Boolean).join(', ') || 'Non renseigné';
    const email = talent.email || applicantData?.email;
    const phone = talent.phone || applicantData?.phone;
    const cvUrl = talent.cvUrl || applicantData?.cvUrl;
    const portfolioUrl = talent.portfolioUrl || applicantData?.portfolioUrl;
    const message = applicantData?.message;
    
    // Process experiences
    const exps = talent.experiences || [];
    let expHtml = exps.length > 0 ? exps.map(e => `
      <div style="margin-bottom: 12px; border-left: 2px solid var(--border-color); padding-left: 12px;">
        <p style="font-size: 0.95rem; font-weight: 600;">${e.title}</p>
        <p style="font-size: 0.85rem; color: var(--text-secondary);">${e.organization} • ${e.period}</p>
      </div>
    `).join('') : '<p style="color: var(--text-secondary); font-size: 0.85rem;">Aucune expérience renseignée.</p>';

    // Process educations
    const edus = talent.educations || [];
    let eduHtml = edus.length > 0 ? edus.map(e => `
      <div style="margin-bottom: 12px; border-left: 2px solid var(--border-color); padding-left: 12px;">
        <p style="font-size: 0.95rem; font-weight: 600;">${e.title}</p>
        <p style="font-size: 0.85rem; color: var(--text-secondary);">${e.institution} • ${e.period}</p>
      </div>
    `).join('') : '<p style="color: var(--text-secondary); font-size: 0.85rem;">Aucune formation renseignée.</p>';

    // Process portfolio projects
    const projs = talent.portfolioProjects || [];
    let projHtml = projs.length > 0 ? projs.map(p => `
      <div style="background: rgba(0,0,0,0.02); padding: 12px; border-radius: 8px; border: 1px solid var(--border-color); margin-bottom: 8px;">
        <p style="font-size: 0.9rem; font-weight: 600;">${p.title}</p>
        <p style="font-size: 0.85rem; color: var(--text-secondary); margin-top: 4px;">${p.description}</p>
      </div>
    `).join('') : '<p style="color: var(--text-secondary); font-size: 0.85rem;">Aucun projet.</p>';
    
    contentEl.innerHTML = `
      <div style="display: flex; align-items: center; gap: 16px; margin-bottom: 24px;">
        ${talent.photoURL ? `<img src="${talent.photoURL}" style="width: 60px; height: 60px; border-radius: 50%; object-fit: cover; border: 2px solid var(--primary);">` : `<div style="width: 60px; height: 60px; border-radius: 50%; background: var(--primary); color: white; display: flex; align-items: center; justify-content: center; font-size: 1.5rem; font-weight: bold;">${initial}</div>`}
        <div>
          <h3 style="font-size: 1.2rem; font-weight: 700;">${talent.name || 'Candidat Anonyme'}</h3>
          <p style="color: var(--text-secondary);">${title}</p>
        </div>
      </div>
      
      <div style="margin-bottom: 24px;">
        <h4 style="font-weight: 600; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;">
          <i class="ph-fill ph-user" style="color: var(--text-secondary);"></i> Profil
        </h4>
        <div style="background: rgba(0,0,0,0.02); padding: 16px; border-radius: 12px; border: 1px solid var(--border-color);">
          ${location !== 'Non renseigné' ? `<p style="font-size: 0.9rem; color: var(--text-secondary);"><i class="ph ph-map-pin"></i> ${location}</p>` : ''}
          ${email ? `<p style="font-size: 0.9rem; color: var(--text-secondary); margin-top: 8px;"><i class="ph ph-envelope"></i> <a href="mailto:${email}" style="color: var(--primary);">${email}</a></p>` : ''}
          ${phone ? `<p style="font-size: 0.9rem; color: var(--text-secondary); margin-top: 8px;"><i class="ph ph-phone"></i> ${phone}</p>` : ''}
          ${talent.bio ? `<p style="font-size: 0.9rem; margin-top: 12px;">${talent.bio}</p>` : ''}
          ${message ? `<div style="margin-top: 16px; padding-top: 16px; border-top: 1px solid var(--border-color);"><h5 style="font-size: 0.85rem; font-weight: 600; margin-bottom: 4px;">Message joint:</h5><p style="font-size: 0.9rem; font-style: italic;">"${message}"</p></div>` : ''}
        </div>
      </div>

      <div style="margin-bottom: 24px;">
        <h4 style="font-weight: 600; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;">
          <i class="ph-fill ph-file-text" style="color: var(--text-secondary);"></i> CV & Documents
        </h4>
        <div style="background: rgba(0,0,0,0.02); padding: 16px; border-radius: 12px; border: 1px solid var(--border-color);">
          ${cvUrl ? `
            <a href="${cvUrl}" target="_blank" class="btn btn-secondary" style="width: 100%; font-size: 0.85rem; margin-bottom: 12px; display: flex; justify-content: center; gap: 8px;">
              <i class="ph ph-download-simple"></i> Voir / Télécharger le CV
            </a>
          ` : ''}
          ${portfolioUrl ? `
            <a href="${portfolioUrl}" target="_blank" class="btn btn-secondary" style="width: 100%; font-size: 0.85rem; margin-bottom: 12px; display: flex; justify-content: center; gap: 8px;">
              <i class="ph ph-link"></i> Voir le Portfolio (Lien externe)
            </a>
          ` : ''}
          
          ${!cvUrl && !portfolioUrl ? `<p style="font-size: 0.85rem; color: var(--text-secondary); text-align: center;">Aucun document externe fourni.</p>` : ''}

          ${exps.length > 0 || edus.length > 0 ? `
            <hr style="border: none; border-top: 1px solid var(--border-color); margin: 16px 0;">
            <div style="margin-bottom: 16px;">
              <h5 style="font-size: 0.9rem; font-weight: 600; margin-bottom: 8px; color: var(--primary);">Expériences (KAIRO)</h5>
              ${expHtml}
            </div>
            <div>
              <h5 style="font-size: 0.9rem; font-weight: 600; margin-bottom: 8px; color: var(--primary);">Formations (KAIRO)</h5>
              ${eduHtml}
            </div>
          ` : ''}
        </div>
      </div>

      <div style="margin-bottom: 24px;">
        <h4 style="font-weight: 600; margin-bottom: 12px; display: flex; align-items: center; gap: 8px;">
          <i class="ph-fill ph-folder-star" style="color: var(--text-secondary);"></i> Community Portfolio
        </h4>
        <div>
          ${projHtml}
        </div>
      </div>
    `;
  } catch (error) {
    console.error("Error fetching candidate:", error);
    if (contentEl) {
      contentEl.innerHTML = `<p style="color: var(--danger); padding: 24px;">Erreur lors du chargement du profil.</p>`;
    }
  }
}

function closeCandidateSlideOver() {
  if (slideOverContent) slideOverContent.style.transform = 'translateX(100%)';
  setTimeout(() => {
    if (slideOverOverlay) slideOverOverlay.style.display = 'none';
  }, 300); // match transition time
}

if (closeSlideOverBtn) {
  closeSlideOverBtn.addEventListener('click', closeCandidateSlideOver);
}

// Close when clicking outside
if (slideOverOverlay) {
  slideOverOverlay.addEventListener('click', (e) => {
    if (e.target === slideOverOverlay) {
      closeCandidateSlideOver();
    }
  });
}

// Candidathèque Logic
async function loadTalents() {
  const loading = document.getElementById('talentsLoading');
  const grid = document.getElementById('talentsGrid');
  
  if (!loading || !grid) return;
  
  try {
    const usersRef = collection(db, 'users');
    const snapshot = await getDocs(usersRef);
    
    let talents = [];
    snapshot.forEach(doc => {
      const data = doc.data();
      // Filter out agencies/admins
      if (data.role !== 'agency' && data.role !== 'admin') {
        talents.push({ id: doc.id, ...data });
      }
    });

    loading.style.display = 'none';
    grid.innerHTML = '';
    
    if (talents.length === 0) {
      grid.innerHTML = '<p style="grid-column: 1/-1; text-align: center; color: var(--text-secondary);">Aucun talent disponible pour le moment.</p>';
      return;
    }

    talents.forEach(talent => {
      const initial = (talent.name || 'C').charAt(0).toUpperCase();
      const title = talent.professionalTitle || 'Candidat';
      const location = [talent.city, talent.country].filter(Boolean).join(', ') || 'Remote';
      let expCount = talent.experiences ? talent.experiences.length : 0;
      const experienceStr = expCount > 0 ? `${expCount} exp.` : 'Débutant';
      
      const card = document.createElement('div');
      card.style.cssText = 'background: white; border: 1px solid var(--border-color); border-radius: 16px; padding: 24px; text-align: center; box-shadow: 0 4px 12px rgba(0,0,0,0.02); display: flex; flex-direction: column; align-items: center;';
      
      const avatarHtml = talent.photoURL 
        ? `<img src="${talent.photoURL}" style="width: 72px; height: 72px; border-radius: 50%; object-fit: cover; border: 2px solid var(--primary); margin-bottom: 16px;">` 
        : `<div style="width: 72px; height: 72px; border-radius: 50%; background: var(--primary); color: white; display: flex; align-items: center; justify-content: center; font-size: 1.8rem; font-weight: bold; margin-bottom: 16px;">${initial}</div>`;
        
      card.innerHTML = `
        ${avatarHtml}
        <h3 style="font-weight: 700; font-size: 1.1rem; margin-bottom: 4px;">${talent.name || 'Anonyme'}</h3>
        <p style="color: var(--text-secondary); font-size: 0.9rem; margin-bottom: 16px;">${title}</p>
        <div style="display: flex; gap: 8px; margin-bottom: 24px; flex-wrap: wrap; justify-content: center;">
          <span style="background: rgba(0,0,0,0.04); padding: 4px 10px; border-radius: 12px; font-size: 0.75rem; color: var(--text-secondary);"><i class="ph ph-map-pin"></i> ${location}</span>
          <span style="background: rgba(0,0,0,0.04); padding: 4px 10px; border-radius: 12px; font-size: 0.75rem; color: var(--text-secondary);"><i class="ph ph-briefcase"></i> ${experienceStr}</span>
        </div>
        <button class="btn btn-secondary view-cand-btn" data-id="${talent.id}" style="width: 100%;">Voir le profil</button>
      `;
      grid.appendChild(card);
      
      const viewBtn = card.querySelector('.view-cand-btn');
      if (viewBtn) {
        viewBtn.addEventListener('click', () => {
          openCandidateSlideOver(talent.id);
        });
      }
    });

  } catch (error) {
    console.error("Error loading talents:", error);
    loading.innerHTML = '<p style="color: var(--danger);">Erreur lors du chargement des talents.</p>';
  }
}

// Settings Logic
function loadSettings(user, userData) {
  const form = document.getElementById('companySettingsForm') as HTMLFormElement;
  if (!form) return;

  const nameInput = document.getElementById('settingsCompanyName') as HTMLInputElement;
  const emailInput = document.getElementById('settingsCompanyEmail') as HTMLInputElement;
  const webInput = document.getElementById('settingsCompanyWebsite') as HTMLInputElement;
  const descInput = document.getElementById('settingsCompanyDesc') as HTMLTextAreaElement;

  if (nameInput) nameInput.value = userData.companyName || userData.displayName || '';
  if (emailInput) emailInput.value = user.email || '';
  if (webInput) webInput.value = userData.website || '';
  if (descInput) descInput.value = userData.description || '';

  form.addEventListener('submit', async (e) => {
    e.preventDefault();
    const saveBtn = document.getElementById('saveSettingsBtn') as HTMLButtonElement;
    const msg = document.getElementById('settingsSuccessMsg');
    
    if (saveBtn) {
      saveBtn.disabled = true;
      saveBtn.textContent = 'Enregistrement...';
    }
    
    try {
      await updateDoc(doc(db, 'users', user.uid), {
        companyName: nameInput.value,
        displayName: nameInput.value,
        website: webInput.value,
        description: descInput.value,
        updatedAt: serverTimestamp()
      });
      
      // Update topbar instantly
      const topbarName = document.getElementById('topbar-user-name');
      const topbarAvatar = document.getElementById('topbar-user-avatar');
      if (topbarName) topbarName.textContent = nameInput.value;
      if (topbarAvatar && nameInput.value) topbarAvatar.textContent = nameInput.value.charAt(0).toUpperCase();

      if (msg) {
        msg.style.display = 'inline-block';
        setTimeout(() => { msg.style.display = 'none'; }, 3000);
      }
    } catch (error) {
      console.error("Error updating settings:", error);
      alert("Erreur lors de la mise à jour des paramètres.");
    } finally {
      if (saveBtn) {
        saveBtn.disabled = false;
        saveBtn.textContent = 'Enregistrer les modifications';
      }
    }
  });
}
