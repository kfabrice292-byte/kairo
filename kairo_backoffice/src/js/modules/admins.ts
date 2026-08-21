// @ts-nocheck
import { db, functions } from '../firebase.js';
import { collection, query, where, getDocs, doc, deleteDoc, updateDoc } from 'firebase/firestore';
import { httpsCallable } from 'firebase/functions';

let adminsList = [];

document.addEventListener('DOMContentLoaded', () => {
  const addBtn = document.getElementById('addBtn');
  const addModal = document.getElementById('addModal');
  const closeModalBtn = document.getElementById('closeModalBtn');
  const cancelBtn = document.getElementById('cancelBtn');
  const addForm = document.getElementById('addForm');
  const modalTitle = document.getElementById('modalTitle');
  const saveBtn = document.getElementById('saveBtn');

  // Modal logic
  const openModal = () => {
    addForm.reset();
    document.getElementById('editAdminId').value = '';
    modalTitle.textContent = 'Inviter un Administrateur';
    document.getElementById('emailGroup').style.display = 'block';
    document.getElementById('passwordGroup').style.display = 'block';
    document.getElementById('adminEmail').required = true;
    document.getElementById('adminPassword').required = true;
    saveBtn.innerHTML = '<i class="ph-bold ph-paper-plane-tilt"></i> Envoyer l\'invitation';
    addModal.classList.add('active');
  };

  const closeModal = () => {
    addModal.classList.remove('active');
  };

  if (addBtn) addBtn.addEventListener('click', openModal);
  if (closeModalBtn) closeModalBtn.addEventListener('click', closeModal);
  if (cancelBtn) cancelBtn.addEventListener('click', closeModal);

  // Load admins
  loadAdmins();

  // Form submit
  if (addForm) {
    addForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      saveBtn.disabled = true;
      saveBtn.textContent = 'Enregistrement...';

      const editId = document.getElementById('editAdminId').value;
      const name = document.getElementById('adminName').value;
      
      const permissionCheckboxes = document.querySelectorAll('input[name="permissions"]:checked');
      const permissions = Array.from(permissionCheckboxes).map(cb => cb.value);

      try {
        if (editId) {
          // UPDATE EXISTING ADMIN
          await updateDoc(doc(db, 'users', editId), {
            name: name,
            permissions: permissions
          });
          alert('Autorisations mises à jour avec succès.');
        } else {
          // CREATE NEW ADMIN
          const email = document.getElementById('adminEmail').value;
          const password = document.getElementById('adminPassword').value;

          const createAdminAccount = httpsCallable(functions, 'createAdminAccount');
          await createAdminAccount({
            email: email,
            password: password,
            name: name,
            permissions: permissions
          });
          
          alert('Invitation envoyée ! Le compte a été créé avec succès.');
        }

        closeModal();
        loadAdmins();
      } catch (error) {
        console.error('Erreur:', error);
        alert('Erreur: ' + error.message);
      } finally {
        saveBtn.disabled = false;
        saveBtn.innerHTML = '<i class="ph-bold ph-paper-plane-tilt"></i> Enregistrer';
      }
    });
  }
});

async function loadAdmins() {
  const tbody = document.getElementById('adminsTableBody');
  if (!tbody) return;

  try {
    const q = query(collection(db, 'users'), where('role', '==', 'admin'));
    const snapshot = await getDocs(q);
    
    // We also want to fetch super_admin to show them in the list (but maybe not editable)
    const qSuper = query(collection(db, 'users'), where('role', '==', 'super_admin'));
    const snapshotSuper = await getDocs(qSuper);

    adminsList = [];
    snapshot.forEach(doc => adminsList.push({ id: doc.id, ...doc.data() }));
    snapshotSuper.forEach(doc => adminsList.push({ id: doc.id, ...doc.data() }));

    renderTable();
  } catch (error) {
    console.error('Erreur chargement admins:', error);
    tbody.innerHTML = `<tr><td colspan="5" class="text-error text-center py-4">Erreur: ${error.message}</td></tr>`;
  }
}

function renderTable() {
  const tbody = document.getElementById('adminsTableBody');
  if (adminsList.length === 0) {
    tbody.innerHTML = '<tr><td colspan="5" class="text-center text-secondary py-8">Aucun administrateur trouvé.</td></tr>';
    return;
  }

  tbody.innerHTML = '';
  
  adminsList.forEach(admin => {
    const tr = document.createElement('tr');
    
    const isSuper = admin.role === 'super_admin';
    const roleBadge = isSuper 
      ? '<span class="badge bg-warning text-white">Super Admin</span>'
      : '<span class="badge" style="background: var(--bg-dark); border: 1px solid var(--border-color);">Admin</span>';
      
    const perms = isSuper 
      ? '<em>Tous les accès</em>'
      : (admin.permissions || []).map(p => `<span class="badge" style="font-size:0.7rem; background:rgba(255,255,255,0.05); margin-right:4px;">${p}</span>`).join('');
      
    let date = '-';
    if (admin.createdAt) {
      if (typeof admin.createdAt.toDate === 'function') {
        date = admin.createdAt.toDate().toLocaleDateString('fr-FR');
      } else if (admin.createdAt.seconds) {
        date = new Date(admin.createdAt.seconds * 1000).toLocaleDateString('fr-FR');
      } else if (admin.createdAt._seconds) {
        date = new Date(admin.createdAt._seconds * 1000).toLocaleDateString('fr-FR');
      } else {
        date = new Date(admin.createdAt).toLocaleDateString('fr-FR');
      }
    }

    const actions = isSuper ? '-' : `
      <div class="flex gap-2">
        <button class="btn-icon" onclick="editAdmin('${admin.id}')" title="Modifier les accès">
          <i class="ph ph-pencil-simple text-primary"></i>
        </button>
        <button class="btn-icon" onclick="removeAdmin('${admin.id}')" title="Révoquer l'accès">
          <i class="ph ph-trash text-error"></i>
        </button>
      </div>
    `;

    tr.innerHTML = `
      <td>
        <div class="font-medium">${admin.name || 'Inconnu'}</div>
        <div class="text-sm text-secondary">${admin.email}</div>
      </td>
      <td>${roleBadge}</td>
      <td style="max-width: 250px; flex-wrap: wrap; display: flex; gap: 4px;">${perms}</td>
      <td>${date}</td>
      <td>${actions}</td>
    `;
    
    tbody.appendChild(tr);
  });
}

window.editAdmin = (id) => {
  const admin = adminsList.find(a => a.id === id);
  if (!admin) return;

  const addModal = document.getElementById('addModal');
  document.getElementById('addForm').reset();
  
  document.getElementById('editAdminId').value = admin.id;
  document.getElementById('adminName').value = admin.name || '';
  
  // Hide email and password for editing
  document.getElementById('emailGroup').style.display = 'none';
  document.getElementById('passwordGroup').style.display = 'none';
  document.getElementById('adminEmail').required = false;
  document.getElementById('adminPassword').required = false;

  // Set permissions
  const permissionCheckboxes = document.querySelectorAll('input[name="permissions"]');
  permissionCheckboxes.forEach(cb => {
    cb.checked = (admin.permissions || []).includes(cb.value);
  });

  document.getElementById('modalTitle').textContent = 'Modifier les accès';
  document.getElementById('saveBtn').innerHTML = '<i class="ph-bold ph-floppy-disk"></i> Enregistrer';
  
  addModal.classList.add('active');
};

window.removeAdmin = async (id) => {
  if (confirm("Êtes-vous sûr de vouloir révoquer l'accès à cet administrateur ? (Son compte Authentication devra être supprimé manuellement dans Firebase)")) {
    try {
      await updateDoc(doc(db, 'users', id), {
        role: 'user', // Rétrograder à utilisateur simple
        permissions: []
      });
      alert('Accès révoqué avec succès.');
      loadAdmins();
    } catch (error) {
      console.error(error);
      alert('Erreur: ' + error.message);
    }
  }
};
