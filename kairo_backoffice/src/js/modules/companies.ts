// @ts-nocheck
import { collection, getDocs, deleteDoc, doc, addDoc, query, orderBy, Timestamp } from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { db, storage } from '../firebase.js';

let companies = [];
const tableBody = document.getElementById('companiesTableBody');
const searchInput = document.getElementById('searchInput');

// Modal
const addModal = document.getElementById('addModal');
const addBtn = document.getElementById('addBtn');
const closeModalBtn = document.getElementById('closeModalBtn');
const cancelBtn = document.getElementById('cancelBtn');
const addForm = document.getElementById('addForm');
const submitFormBtn = document.getElementById('submitFormBtn');

async function loadCompanies() {
  if (!tableBody) return;
  
  try {
    const q = query(collection(db, 'companies'), orderBy('createdAt', 'desc'));
    const snapshot = await getDocs(q);
    
    companies = [];
    snapshot.forEach((doc) => {
      companies.push({ id: doc.id, ...doc.data() });
    });
    
    renderCompanies(companies);
  } catch (error) {
    console.error("Error loading companies:", error);
    // If it fails, maybe the collection doesn't exist yet or index is missing, fallback to unordered query
    try {
        const fallbackQ = query(collection(db, 'companies'));
        const fallbackSnap = await getDocs(fallbackQ);
        companies = [];
        fallbackSnap.forEach((doc) => {
          companies.push({ id: doc.id, ...doc.data() });
        });
        renderCompanies(companies);
    } catch(e) {
        tableBody.innerHTML = `<tr><td colspan="5" class="text-center text-danger">Erreur lors du chargement des entreprises.</td></tr>`;
    }
  }
}

function renderCompanies(data) {
  if (data.length === 0) {
    tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 2rem;">Aucune entreprise trouvée.</td></tr>`;
    return;
  }
  
  tableBody.innerHTML = data.map(item => {
    const avatar = item.logoUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(item.name || 'C')}&background=random`;
    return `
      <tr>
        <td>
          <div class="user-cell">
            <img src="${avatar}" alt="Logo" class="user-cell-avatar" style="border-radius: 8px;">
            <div class="user-cell-info">
              <span class="user-cell-name font-medium">${item.name || 'Sans nom'}</span>
            </div>
          </div>
        </td>
        <td><span class="badge" style="background-color: var(--primary-transparent); color: var(--primary);">${item.sector || 'Général'}</span></td>
        <td>${item.location || 'Non spécifié'}</td>
        <td>${item.website ? `<a href="${item.website}" target="_blank" class="text-primary hover:underline">Visiter</a>` : '-'}</td>
        <td>
          ${item.status === 'suspended' 
            ? '<span class="badge" style="background-color: var(--danger-transparent); color: var(--danger);">Suspendu</span>' 
            : '<span class="badge" style="background-color: var(--success-transparent); color: var(--success);">Actif</span>'}
        </td>
        <td>
          <div class="actions-cell">
            <button class="btn-icon text-warning suspend-btn" data-id="${item.id}" data-status="${item.status || 'active'}" title="Suspendre/Activer">
              <i class="ph ${item.status === 'suspended' ? 'ph-play' : 'ph-pause'}"></i>
            </button>
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

  const suspendBtns = document.querySelectorAll('.suspend-btn');
  suspendBtns.forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const id = e.currentTarget.dataset.id;
      const currentStatus = e.currentTarget.dataset.status;
      const newStatus = currentStatus === 'suspended' ? 'active' : 'suspended';
      const actionTxt = newStatus === 'suspended' ? 'suspendre' : 'réactiver';
      
      if (confirm(`Voulez-vous vraiment ${actionTxt} ce compte ?`)) {
        try {
          const { updateDoc, doc } = await import('firebase/firestore');
          await updateDoc(doc(db, 'companies', id), { status: newStatus });
          const item = companies.find(c => c.id === id);
          if(item) item.status = newStatus;
          renderCompanies(companies);
        } catch (error) {
          console.error("Error updating status:", error);
          alert("Erreur lors de la mise à jour.");
        }
      }
    });
  });

  const deleteBtns = document.querySelectorAll('.delete-btn');
  deleteBtns.forEach(btn => {
    btn.addEventListener('click', async (e) => {
      const id = e.currentTarget.dataset.id;
      if (confirm("Êtes-vous sûr de vouloir supprimer cette entreprise ?")) {
        try {
          await deleteDoc(doc(db, 'companies', id));
          companies = companies.filter(c => c.id !== id);
          renderCompanies(companies);
        } catch (error) {
          console.error("Error deleting company:", error);
          alert("Erreur lors de la suppression.");
        }
      }
    });
  });
}

function openModal() {
  if(addModal) addModal.style.display = 'flex';
}

function closeModal() {
  if(addModal) {
    addModal.style.display = 'none';
    addForm.reset();
  }
}

document.addEventListener('DOMContentLoaded', () => {
  loadCompanies();
  
  const refreshBtn = document.getElementById('refreshBtn');
  if (refreshBtn) {
    refreshBtn.addEventListener('click', () => {
      tableBody.innerHTML = `<tr><td colspan="5" style="text-align: center; padding: 3rem;"><i class="ph ph-spinner ph-spin text-2xl text-primary"></i></td></tr>`;
      loadCompanies();
    });
  }

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      const term = e.target.value.toLowerCase();
      const filtered = companies.filter(c => c.name && c.name.toLowerCase().includes(term));
      renderCompanies(filtered);
    });
  }

  // Modal logic
  if (addBtn) addBtn.addEventListener('click', openModal);
  if (closeModalBtn) closeModalBtn.addEventListener('click', closeModal);
  if (cancelBtn) cancelBtn.addEventListener('click', closeModal);
  
  if (addModal) {
    addModal.addEventListener('click', (e) => {
      if(e.target === addModal) closeModal();
    });
  }

  // Add preview listener
  const compLogoFile = document.getElementById('compLogoFile');
  const compLogoUrl = document.getElementById('compLogoUrl');
  const imagePreviewContainer = document.getElementById('imagePreviewContainer');
  const imagePreview = document.getElementById('imagePreview');
  
  if (compLogoFile) {
    compLogoFile.addEventListener('change', (e) => {
      if (e.target.files.length > 0) {
        imagePreview.src = URL.createObjectURL(e.target.files[0]);
        imagePreviewContainer.style.display = 'block';
      } else if (!compLogoUrl.value) {
        imagePreviewContainer.style.display = 'none';
      }
    });
  }

  if (addForm) {
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      submitFormBtn.disabled = true;
      submitFormBtn.innerHTML = '<i class="ph ph-spinner ph-spin"></i> Enregistrement...';

      try {
        let finalImageUrl = compLogoUrl.value;
        if (compLogoFile && compLogoFile.files.length > 0) {
          const file = compLogoFile.files[0];
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

        const newCompany = {
          name: document.getElementById('compName').value,
          sector: document.getElementById('compSector').value,
          location: document.getElementById('compLocation').value,
          website: document.getElementById('compWebsite').value,
          logoUrl: finalImageUrl,
          description: document.getElementById('compDesc').value,
          isVerified: true,
          createdAt: Timestamp.now()
        };

        const docRef = await addDoc(collection(db, 'companies'), newCompany);
        companies.unshift({ id: docRef.id, ...newCompany });
        renderCompanies(companies);
        closeModal();
      } catch (error) {
        console.error("Error adding company:", error);
        alert("Erreur lors de la création.");
      } finally {
        submitFormBtn.disabled = false;
        submitFormBtn.innerHTML = 'Enregistrer';
      }
    });
  }
});
