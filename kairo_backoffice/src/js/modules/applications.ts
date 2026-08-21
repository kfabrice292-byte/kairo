// @ts-nocheck
import { collection, getDocs, doc, updateDoc, query, orderBy, limit, getDoc } from 'firebase/firestore';
import { db } from '../firebase.js';

let applications = [];
const tableBody = document.getElementById('applicationsTableBody');
const searchInput = document.getElementById('searchInput');

// ATS Scoring Logic
function calculateATSScore(candidate, jobTitle) {
    if (!candidate || !jobTitle) return 0;
    
    let score = 0;
    const jobWords = jobTitle.toLowerCase().split(/[\s,;-]+/).filter(w => w.length > 2);
    const candidateText = [
        candidate.headline || '',
        candidate.bio || '',
        ...(candidate.skills || []).map(s => s.name || s)
    ].join(' ').toLowerCase();

    if (jobWords.length === 0) return 50;

    let matches = 0;
    jobWords.forEach(word => {
        if (candidateText.includes(word)) matches++;
    });

    score = Math.round((matches / jobWords.length) * 100);
    // Base minimum pour le prototype
    if (score < 40) score = 40 + Math.floor(Math.random() * 20); 
    if (score > 100) score = 100;
    return score;
}

async function loadApplications() {
  if (!tableBody) return;
  
  try {
    const q = query(collection(db, 'applications'), orderBy('addedAt', 'desc'), limit(100));
    const snapshot = await getDocs(q);
    
    applications = [];
    
    for (let document of snapshot.docs) {
      const data = document.data();
      let jobTitle = 'Offre inconnue';
      let companyName = 'Inconnue';
      
      if (data.jobId) {
        try {
          const jobSnap = await getDoc(doc(db, 'opportunities', data.jobId));
          if (jobSnap.exists()) {
            jobTitle = jobSnap.data().title || jobTitle;
            companyName = jobSnap.data().company || companyName;
          }
        } catch(e) {}
      }
      
      applications.push({ 
          id: document.id, 
          jobTitle, 
          companyName, 
          ...data,
          atsScore: calculateATSScore(data.candidate, jobTitle)
      });
    }
    
    // Tri automatique par ATS Score décroissant
    applications.sort((a, b) => b.atsScore - a.atsScore);
    
    renderApplications(applications);
  } catch (error) {
    console.error("Error loading applications:", error);
    
    // Fallback if index missing
    try {
        const fallbackQ = query(collection(db, 'applications'), limit(100));
        const fallbackSnap = await getDocs(fallbackQ);
        applications = [];
        for (let document of fallbackSnap.docs) {
            const data = document.data();
            let jobTitle = 'Offre inconnue';
            let companyName = 'Inconnue';
            if (data.jobId) {
                try {
                const jobSnap = await getDoc(doc(db, 'opportunities', data.jobId));
                if (jobSnap.exists()) {
                    jobTitle = jobSnap.data().title || jobTitle;
                    companyName = jobSnap.data().company || companyName;
                }
                } catch(e) {}
            }
            applications.push({ 
                id: document.id, 
                jobTitle, 
                companyName, 
                ...data,
                atsScore: calculateATSScore(data.candidate, jobTitle)
            });
        }
        applications.sort((a, b) => b.atsScore - a.atsScore);
        renderApplications(applications);
    } catch(e) {
        tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des candidatures.</td></tr>`;
    }
  }
}

function renderApplications(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucune candidature trouvée.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    const candidate = item.candidate || {};
    const avatar = candidate.photoUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(candidate.name || 'C')}&background=random`;
    const date = item.addedAt ? new Date(item.addedAt.seconds * 1000).toLocaleDateString('fr-FR') : 'Inconnue';
    
    let atsColor = 'var(--success)';
    if (item.atsScore < 70) atsColor = 'var(--warning)';
    if (item.atsScore < 50) atsColor = 'var(--danger)';

    return `
      <tr>
        <td>
          <div class="user-cell">
            <img src="${avatar}" alt="Avatar" class="user-cell-avatar">
            <div class="user-cell-info">
              <a href="user-detail.html?id=${item.candidateId}" class="user-cell-name font-medium hover:text-primary transition-colors" style="text-decoration: none;">
                ${candidate.name || 'Candidat inconnu'}
              </a>
              <span class="user-cell-email text-xs text-tertiary">${candidate.headline || 'Pas de titre'}</span>
              <div style="margin-top: 6px;">
                <span class="badge" style="background-color: ${atsColor}20; color: ${atsColor}; font-size: 0.7rem; padding: 2px 6px;">
                  <i class="ph ph-magic-wand"></i> Match : ${item.atsScore}%
                </span>
              </div>
            </div>
          </div>
        </td>
        <td>
          <div class="font-medium" style="max-width: 200px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;">
            ${item.jobTitle}
          </div>
        </td>
        <td>${item.companyName}</td>
        <td>${date}</td>
        <td>
          <select class="form-control status-select" data-id="${item.id}" style="padding: 4px 8px; height: auto; width: 120px; font-size: 0.8rem; background-color: var(--bg-card);">
            <option value="new" ${item.status === 'new' ? 'selected' : ''}>À traiter</option>
            <option value="review" ${item.status === 'review' ? 'selected' : ''}>En revue</option>
            <option value="interview" ${item.status === 'interview' ? 'selected' : ''}>Entretien</option>
            <option value="rejected" ${item.status === 'rejected' ? 'selected' : ''}>Refusé</option>
            <option value="hired" ${item.status === 'hired' ? 'selected' : ''}>Embauché</option>
          </select>
        </td>
        <td>
          <div class="actions-cell">
            <a href="user-detail.html?id=${item.candidateId}" class="btn-icon text-primary" title="Voir Smart CV">
              <i class="ph ph-file-text"></i>
            </a>
            ${(item.status === 'interview' || item.status === 'hired') && candidate.email ? `
            <a href="mailto:${candidate.email}?subject=Suite à votre candidature : ${encodeURIComponent(item.jobTitle)}&body=Bonjour ${encodeURIComponent(candidate.name || '')},%0D%0A%0D%0ANous avons le plaisir de vous informer que votre profil a retenu notre attention pour le poste de ${encodeURIComponent(item.jobTitle)}.%0D%0A" class="btn-icon" style="color: var(--warning);" title="Envoyer un Email">
              <i class="ph ph-envelope"></i>
            </a>` : ''}
            ${(item.status === 'interview' || item.status === 'hired') && candidate.phone ? `
            <a href="https://wa.me/${candidate.phone.replace(/[^0-9]/g, '')}?text=Bonjour ${encodeURIComponent(candidate.name || '')}, suite à votre candidature pour le poste de ${encodeURIComponent(item.jobTitle)}, nous souhaiterions échanger avec vous." target="_blank" class="btn-icon" style="color: var(--success);" title="Contacter sur WhatsApp">
              <i class="ph ph-whatsapp-logo"></i>
            </a>` : ''}
          </div>
        </td>
      </tr>
    `;
  }).join('');
  
  attachEventListeners();
}

function attachEventListeners() {
  const statusSelects = document.querySelectorAll('.status-select');
  statusSelects.forEach(select => {
    select.addEventListener('change', async (e) => {
        const id = e.target.dataset.id;
        const newStatus = e.target.value;
        try {
            await updateDoc(doc(db, 'applications', id), {
                status: newStatus
            });
            const index = applications.findIndex(a => a.id === id);
            if(index > -1) {
                applications[index].status = newStatus;
                
                // Communication automatique
                if (newStatus === 'interview' || newStatus === 'hired') {
                   const candidate = applications[index].candidate;
                   if (candidate && candidate.phone) {
                       if(confirm("Statut mis à jour !\nVoulez-vous notifier automatiquement le candidat sur WhatsApp ?")) {
                           window.open(`https://wa.me/${candidate.phone.replace(/[^0-9]/g, '')}?text=Bonjour ${encodeURIComponent(candidate.name || '')}, suite à votre candidature pour le poste de ${encodeURIComponent(applications[index].jobTitle)}, nous souhaiterions échanger avec vous.`, '_blank');
                       }
                   }
                }
                
                // Re-render pour afficher les boutons d'action si besoin
                renderApplications(applications);
            }
        } catch(error) {
            alert("Erreur lors de la mise à jour du statut");
        }
    });
  });
}

document.addEventListener('DOMContentLoaded', () => {
  loadApplications();
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadApplications();
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const term = e.target.value.toLowerCase();
      const filtered = applications.filter(a => {
          const candidateName = a.candidate?.name || '';
          return candidateName.toLowerCase().includes(term) || a.jobTitle.toLowerCase().includes(term);
      });
      renderApplications(filtered);
    });
  }
});
