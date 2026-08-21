import { auth, db } from '../firebase.js';
import { 
    signInWithEmailAndPassword, 
    createUserWithEmailAndPassword,
    onAuthStateChanged
} from 'firebase/auth';
import { doc, setDoc, getDoc, serverTimestamp } from 'firebase/firestore';

document.addEventListener('DOMContentLoaded', () => {
    
    // Auto-redirect if already logged in and agency
    onAuthStateChanged(auth, async (user) => {
        if (user) {
            const userDoc = await getDoc(doc(db, 'users', user.uid));
            const userData = userDoc.data();
            if (userData && (userData.role === 'agency' || userData.role === 'admin')) {
                window.location.href = 'agencies.html';
            }
        }
    });

    let isLogin = true;

    const form = document.getElementById('auth-form') as HTMLFormElement;
    const title = document.getElementById('auth-title') as HTMLElement;
    const subtitle = document.getElementById('auth-subtitle') as HTMLElement;
    const signupFields = document.getElementById('signup-fields') as HTMLElement;
    const companyInput = document.getElementById('company-name') as HTMLInputElement;
    const emailInput = document.getElementById('email') as HTMLInputElement;
    const passwordInput = document.getElementById('password') as HTMLInputElement;
    const submitBtn = document.getElementById('submit-btn') as HTMLElement;
    const toggleBtn = document.getElementById('toggle-btn') as HTMLElement;
    const toggleText = document.getElementById('toggle-text') as HTMLElement;
    const errorDiv = document.getElementById('auth-error') as HTMLElement;

    // Toggle Login / Register
    toggleBtn.addEventListener('click', (e) => {
        e.preventDefault();
        isLogin = !isLogin;
        errorDiv.style.display = 'none';

        if (isLogin) {
            title.textContent = 'Espace Entreprise';
            subtitle.textContent = 'Connectez-vous pour accéder à votre ATS.';
            signupFields.style.display = 'none';
            companyInput.required = false;
            submitBtn.textContent = 'Se connecter';
            toggleText.textContent = 'Pas encore de compte ?';
            toggleBtn.textContent = "S'inscrire";
        } else {
            title.textContent = 'Créer un compte';
            subtitle.textContent = 'Rejoignez KAIRO PRO et recrutez mieux.';
            signupFields.style.display = 'block';
            companyInput.required = true;
            submitBtn.textContent = "S'inscrire";
            toggleText.textContent = 'Déjà un compte ?';
            toggleBtn.textContent = 'Se connecter';
        }
    });

    // Form Submit Handler
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        
        const email = emailInput.value.trim();
        const password = passwordInput.value;
        const company = companyInput.value.trim();

        submitBtn.textContent = 'Veuillez patienter...';
        (submitBtn as HTMLButtonElement).disabled = true;
        errorDiv.style.display = 'none';

        try {
            if (isLogin) {
                // LOGIN
                const userCredential = await signInWithEmailAndPassword(auth, email, password);
                
                // Verify if it's really an agency
                const userDoc = await getDoc(doc(db, 'users', userCredential.user.uid));
                const userData = userDoc.data();
                
                if (!userData || (userData.role !== 'agency' && userData.role !== 'admin')) {
                    throw new Error('not-agency');
                }

                window.location.href = 'agencies.html';

            } else {
                // REGISTER
                const userCredential = await createUserWithEmailAndPassword(auth, email, password);
                const user = userCredential.user;
                
                const agencyType = (document.querySelector('input[name="agencyType"]:checked') as HTMLInputElement)?.value || 'company';

                // Create Firestore document with agency role
                await setDoc(doc(db, 'users', user.uid), {
                    email: user.email,
                    displayName: company || 'Nouvelle Entreprise',
                    companyName: company || 'Nouvelle Entreprise',
                    role: 'agency',
                    agencyType: agencyType,
                    createdAt: serverTimestamp()
                });

                window.location.href = 'agencies.html';
            }
        } catch (error: any) {
            console.error("Auth Error:", error);
            errorDiv.style.display = 'block';
            
            if (error.message === 'not-agency') {
                errorDiv.textContent = "Ce compte n'est pas autorisé à accéder à l'espace Entreprise.";
                auth.signOut();
            } else if (error.code === 'auth/email-already-in-use') {
                errorDiv.textContent = "Cet email est déjà utilisé.";
            } else if (error.code === 'auth/wrong-password' || error.code === 'auth/user-not-found' || error.code === 'auth/invalid-credential') {
                errorDiv.textContent = "Email ou mot de passe incorrect.";
            } else {
                errorDiv.textContent = "Une erreur est survenue. Veuillez réessayer.";
            }
        } finally {
            submitBtn.textContent = isLogin ? 'Se connecter' : "S'inscrire";
            (submitBtn as HTMLButtonElement).disabled = false;
        }
    });
});
