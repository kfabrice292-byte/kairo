document.addEventListener('DOMContentLoaded', () => {
    // Register Logic
    const registerForm = document.getElementById('registerForm');
    if (registerForm) {
        registerForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const fullname = document.getElementById('fullname').value.trim();
            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value;

            if (fullname && email && password) {
                const btn = registerForm.querySelector('button[type="submit"]');
                const originalText = btn.textContent;
                btn.textContent = 'Création en cours...';
                btn.disabled = true;

                try {
                    await API.register(fullname, email, password);
                    window.location.href = 'dashboard.html';
                } catch (error) {
                    showError(error.message);
                    btn.textContent = originalText;
                    btn.disabled = false;
                }
            }
        });
    }

    // Login Logic
    const loginForm = document.getElementById('loginForm');
    if (loginForm) {
        loginForm.addEventListener('submit', async (e) => {
            e.preventDefault();
            const email = document.getElementById('email').value.trim();
            const password = document.getElementById('password').value;

            if (email && password) {
                const btn = loginForm.querySelector('button[type="submit"]');
                const originalText = btn.textContent;
                btn.textContent = 'Connexion...';
                btn.disabled = true;

                try {
                    await API.login(email, password);
                    window.location.href = 'dashboard.html';
                } catch (error) {
                    showError(error.message);
                    btn.textContent = originalText;
                    btn.disabled = false;
                }
            }
        });
    }

    // Logout Logic
    const logoutBtn = document.getElementById('logoutBtn');
    if (logoutBtn) {
        logoutBtn.addEventListener('click', async (e) => {
            e.preventDefault();
            await API.logout();
            window.location.href = 'index.html';
        });
    }

    function showError(message) {
        const errorEl = document.getElementById('errorMessage');
        if (!errorEl) {
            // Créer le message d'erreur si l'élément n'existe pas
            const div = document.createElement('div');
            div.id = 'errorMessage';
            div.className = 'error-message';
            div.style.color = 'red';
            div.style.textAlign = 'center';
            div.style.marginBottom = '1rem';
            document.querySelector('.auth-form').prepend(div);
        }
        document.getElementById('errorMessage').textContent = message;
        document.getElementById('errorMessage').style.display = 'block';
    }
});
