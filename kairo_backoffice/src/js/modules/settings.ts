// @ts-nocheck
import { doc, getDoc, setDoc } from 'firebase/firestore';
import { db } from '../firebase.js';

const maintenanceInput = document.getElementById('maintenanceMode');
const versionInput = document.getElementById('appVersion');
const emailInput = document.getElementById('contactEmail');

async function loadSettings() {
  try {
    const configDoc = await getDoc(doc(db, 'config', 'global'));
    if (configDoc.exists()) {
      const data = configDoc.data();
      if (maintenanceInput) maintenanceInput.checked = data.maintenanceMode === true;
      if (versionInput) versionInput.value = data.appVersion || '';
      if (emailInput) emailInput.value = data.contactEmail || '';
    }
  } catch (error) {
    console.error("Error loading settings:", error);
  }
}

document.addEventListener('DOMContentLoaded', () => {
  loadSettings();
  
  const saveBtn = document.getElementById('saveBtn');
  if (saveBtn) {
    saveBtn.addEventListener('click', async () => {
      saveBtn.disabled = true;
      saveBtn.innerHTML = '<i class="ph ph-spinner ph-spin"></i> Enregistrement...';
      
      try {
        await setDoc(doc(db, 'config', 'global'), {
          maintenanceMode: maintenanceInput ? maintenanceInput.checked : false,
          appVersion: versionInput ? versionInput.value : '',
          contactEmail: emailInput ? emailInput.value : ''
        }, { merge: true });
        
        alert("Paramètres enregistrés avec succès !");
      } catch (error) {
        console.error("Error saving settings:", error);
        alert("Erreur lors de l'enregistrement.");
      }
      
      saveBtn.disabled = false;
      saveBtn.innerHTML = '<i class="ph ph-floppy-disk"></i> Enregistrer';
    });
  }
});
