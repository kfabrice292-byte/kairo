// @ts-nocheck
import { signInWithEmailAndPassword, onAuthStateChanged, signOut } from 'firebase/auth';
import { doc, getDoc } from 'firebase/firestore';
import { auth, db } from './firebase.js';

// --- Auth State Observer ---
// Automatically check authentication on page load
onAuthStateChanged(auth, async (user) => {
  const isLoginPage = window.location.pathname.includes('login.html');
  
  if (user) {
    // User is logged in, check if they are admin
    try {
      const userDocRef = doc(db, 'users', user.uid);
      const userDoc = await getDoc(userDocRef);
      
      const userData = userDoc.exists() ? userDoc.data() : null;
      const role = userData ? userData.role : null;
      // Legacy admins (created before RBAC) have no permissions array
      const isLegacyAdmin = role === 'admin' && !userData.permissions;
      const isSuperAdmin = role === 'super_admin' || user.email === 'kfabrice292@gmail.com' || isLegacyAdmin;
      const isAdmin = role === 'admin' || isSuperAdmin;
      
      if (isAdmin) {
        // Logged in and is admin
        if (isLoginPage) {
          window.location.href = 'index.html';
        } else {
          // Verify permissions for current page
          const permissions = userData.permissions || [];
          const currentPage = window.location.pathname.split('/').pop().replace('.html', '');
          
          // Pages always accessible to admins
          const allowedBasePages = ['index', 'settings', 'admin'];
          
          if (!isSuperAdmin && currentPage && !allowedBasePages.includes(currentPage)) {
            // Check if they have access to this module
            if (!permissions.includes(currentPage)) {
              window.location.href = 'index.html';
              return;
            }
          }

          // Filter sidebar navigation
          if (!isSuperAdmin) {
            const navItems = document.querySelectorAll('.sidebar-nav .nav-item');
            navItems.forEach(item => {
              const href = item.getAttribute('href').replace('.html', '');
              if (!allowedBasePages.includes(href) && !permissions.includes(href)) {
                item.style.display = 'none'; // Hide unauthorized links
              }
            });
          }

          // Initialize user info on topbar if it exists
          const userNameElement = document.getElementById('topbar-user-name');
          const userAvatarElement = document.getElementById('topbar-user-avatar');
          
          if (userNameElement && userData) {
            userNameElement.textContent = userData.name || (isSuperAdmin ? 'Super Admin' : 'Admin');
          }
          if (userAvatarElement && userData) {
            const name = userData.name || 'A';
            userAvatarElement.textContent = name.charAt(0).toUpperCase();
          }
        }
      } else {
        // Logged in but NOT admin
        await signOut(auth);
        if (!isLoginPage) {
          window.location.href = 'login.html';
        } else {
          showError("Accès refusé. Ce compte n'a pas les droits d'administration.");
        }
      }
    } catch (error) {
      console.error("Error checking admin status:", error);
      if (!isLoginPage) window.location.href = 'login.html';
    }
  } else {
    // No user logged in
    if (!isLoginPage) {
      window.location.href = 'login.html';
    }
  }
});

// --- Login Form Logic ---
const loginForm = document.getElementById('loginForm');
const errorMsg = document.getElementById('errorMessage');
const submitBtn = document.getElementById('submitBtn');

if (loginForm) {
  loginForm.addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const email = document.getElementById('email').value;
    const password = document.getElementById('password').value;
    
    if (!email || !password) return;
    
    // UI state
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="ph ph-spinner ph-spin"></i> Connexion...';
    errorMsg.style.display = 'none';
    
    try {
      await signInWithEmailAndPassword(auth, email, password);
      // onAuthStateChanged will handle the redirect if successful
    } catch (error) {
      console.error("Login error:", error);
      showError("Identifiants incorrects ou erreur de connexion.");
      submitBtn.disabled = false;
      submitBtn.innerHTML = 'Se connecter';
    }
  });
}

function showError(msg) {
  if (errorMsg) {
    errorMsg.textContent = msg;
    errorMsg.style.display = 'block';
  }
}

// --- Logout Logic ---
const logoutBtn = document.getElementById('logoutBtn');
if (logoutBtn) {
  logoutBtn.addEventListener('click', async (e) => {
    e.preventDefault();
    await signOut(auth);
    window.location.href = 'login.html';
  });
}
