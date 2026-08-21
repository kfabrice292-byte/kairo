import { auth, db } from '../firebase.js';
import { onAuthStateChanged } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';

document.addEventListener('DOMContentLoaded', () => {
    console.log("KAIRO PRO Landing Page - Security Check initialized");
    
    const loader = document.getElementById('security-loader');

    // Authentication Guard for the Landing Page
    onAuthStateChanged(auth, async (user) => {
        if (user) {
            try {
                // Check if user is an agency or admin
                const userDoc = await getDoc(doc(db, 'users', user.uid));
                const userData = userDoc.data();

                if (userData && (userData.role === 'agency' || userData.role === 'admin')) {
                    // User is already an agency customer, redirect them to the ATS backoffice
                    console.log("Agency already authenticated. Redirecting to Backoffice...");
                    window.location.href = 'agencies.html';
                    return;
                }
            } catch (error) {
                console.error("Error checking user role:", error);
            }
        }
        
        // If not logged in, or not an agency, hide the loader and show the landing page
        if (loader) {
            loader.style.opacity = '0';
            setTimeout(() => {
                loader.style.display = 'none';
            }, 500); // Wait for transition
        }
    });
});
