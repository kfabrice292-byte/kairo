import { auth, db } from '../firebase.js';
import { signInAnonymously, onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc, collection, setDoc, serverTimestamp } from 'firebase/firestore';

document.addEventListener('DOMContentLoaded', () => {
  const urlParams = new URLSearchParams(window.location.search);
  const offerId = urlParams.get('id');

  const loadingState = document.getElementById('loadingState');
  const errorState = document.getElementById('errorState');
  const offerDetails = document.getElementById('offerDetails');
  
  if (!offerId) {
    showError();
    return;
  }

  // 1. Sign in anonymously
  onAuthStateChanged(auth, async (user) => {
    if (user) {
      // User is signed in (could be a real user or anonymous)
      await loadOffer(offerId, user.uid);
    } else {
      try {
        await signInAnonymously(auth);
        // onAuthStateChanged will fire again
      } catch (error) {
        console.error("Auth error:", error);
        showError();
      }
    }
  });

  async function loadOffer(id: string, uid: string) {
    try {
      const offerRef = doc(db, 'opportunities', id);
      const offerSnap = await getDoc(offerRef);

      if (!offerSnap.exists()) {
        showError();
        return;
      }

      const data = offerSnap.data();
      populateUI(data);

      // Handle Form
      const applyForm = document.getElementById('applyForm') as HTMLFormElement;
      applyForm.addEventListener('submit', async (e) => {
        e.preventDefault();
        await submitApplication(id, uid, data);
      });

    } catch (error) {
      console.error("Error fetching offer:", error);
      showError();
    }
  }

  function populateUI(data: any) {
    const displayTitle = document.getElementById('displayTitle');
    const displayCompany = document.getElementById('displayCompany');
    const displayContract = document.getElementById('displayContract');
    const displayLocation = document.getElementById('displayLocation');
    const displayDesc = document.getElementById('displayDesc');

    if (displayTitle) displayTitle.textContent = data.title;
    if (displayCompany) displayCompany.textContent = data.company || 'Entreprise KAIRO';
    if (displayContract) displayContract.innerHTML = `<i class="ph ph-file-text"></i> ${data.contractType || 'CDI'}`;
    if (displayLocation) displayLocation.innerHTML = `<i class="ph ph-map-pin"></i> ${data.location || 'Non précisé'}`;
    if (displayDesc) displayDesc.textContent = data.description;

    // Show optional fields based on requirements
    if (data.requireCV) {
      const cvField = document.getElementById('cvField');
      if (cvField) {
        cvField.style.display = 'block';
        const input = document.getElementById('candCVUrl') as HTMLInputElement;
        if (input) input.required = true;
      }
    }
    
    if (data.requirePortfolio) {
      const portField = document.getElementById('portfolioField');
      if (portField) {
        portField.style.display = 'block';
        const input = document.getElementById('candPortfolioUrl') as HTMLInputElement;
        if (input) input.required = true;
      }
    }

    if (loadingState) loadingState.style.display = 'none';
    if (offerDetails) offerDetails.style.display = 'block';
  }

  async function submitApplication(offerId: string, uid: string, offerData: any) {
    const btn = document.getElementById('submitApplyBtn') as HTMLButtonElement;
    btn.disabled = true;
    btn.innerHTML = `<i class="ph ph-spinner ph-spin"></i> Envoi en cours...`;

    try {
      const name = (document.getElementById('candName') as HTMLInputElement).value;
      const email = (document.getElementById('candEmail') as HTMLInputElement).value;
      const phone = (document.getElementById('candPhone') as HTMLInputElement).value;
      const cvUrl = (document.getElementById('candCVUrl') as HTMLInputElement)?.value || '';
      const portfolioUrl = (document.getElementById('candPortfolioUrl') as HTMLInputElement)?.value || '';
      const message = (document.getElementById('candMessage') as HTMLTextAreaElement)?.value || '';

      const applicantsRef = doc(collection(db, 'opportunities', offerId, 'applicants'), uid);
      
      await setDoc(applicantsRef, {
        userId: uid,
        name: name,
        email: email,
        phone: phone,
        cvUrl: cvUrl,
        portfolioUrl: portfolioUrl,
        message: message,
        currentRole: 'Candidat externe',
        status: 'new', // Kanban default column
        appliedAt: serverTimestamp()
      });

      // Show success state
      const formContainer = document.getElementById('applyFormContainer');
      const successState = document.getElementById('successState');
      
      if (formContainer) formContainer.style.display = 'none';
      if (successState) successState.style.display = 'block';

    } catch (error) {
      console.error("Error submitting application:", error);
      alert("Une erreur est survenue lors de l'envoi de votre candidature.");
      btn.disabled = false;
      btn.innerHTML = 'Envoyer ma candidature';
    }
  }

  function showError() {
    if (loadingState) loadingState.style.display = 'none';
    if (offerDetails) offerDetails.style.display = 'none';
    if (errorState) errorState.style.display = 'block';
  }
});
