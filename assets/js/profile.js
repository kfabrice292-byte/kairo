document.addEventListener('DOMContentLoaded', async () => {
    // Show a small loader if possible
    const formContainer = document.querySelector('.form-container');
    if (formContainer) {
        formContainer.style.opacity = '0.5';
        formContainer.style.pointerEvents = 'none';
    }

    let fullUser;
    try {
        fullUser = await API.getCurrentUser();
    } catch (e) {
        console.error("Erreur de récupération du profil", e);
    }
    
    if (!fullUser) {
        window.location.href = 'login.html';
        return;
    }

    if (formContainer) {
        formContainer.style.opacity = '1';
        formContainer.style.pointerEvents = 'auto';
    }

    // Display Avatar and Display Name
    const avatarEl = document.getElementById('userAvatar');
    const displayNameEl = document.getElementById('userDisplayName');
    
    if (avatarEl && fullUser.name) {
        avatarEl.textContent = fullUser.name.charAt(0).toUpperCase();
    }
    if (displayNameEl && fullUser.name) {
        displayNameEl.textContent = fullUser.name;
    }

    // Display Points
    const pointsDisplay = document.getElementById('pointsDisplay');
    if (pointsDisplay) {
        const points = fullUser.points !== undefined ? fullUser.points : 1000;
        pointsDisplay.innerHTML = `${points} <span style="font-size: 1.5rem; font-weight: 600; opacity: 0.8;">pts</span>`;
    }

    // Fill form
    document.getElementById('fullname').value = fullUser.name || '';
    document.getElementById('email').value = fullUser.email || '';
    
    // New fields
    const specialtyInput = document.getElementById('specialty');
    const phoneInput = document.getElementById('phone');
    const cityInput = document.getElementById('city');
    const linkedinInput = document.getElementById('linkedin');
    
    if (specialtyInput) specialtyInput.value = fullUser.specialty || '';
    if (phoneInput) phoneInput.value = fullUser.phone || '';
    if (cityInput) cityInput.value = fullUser.city || '';
    if (linkedinInput) linkedinInput.value = fullUser.linkedin || '';

    // Handle Photo Upload Preview
    const photoInput = document.getElementById('photoInput');
    const avatarPreview = document.getElementById('avatarPreview');
    const avatarPlaceholder = document.getElementById('avatarPlaceholder');
    
    // Load saved photo if exists
    if (fullUser.photoBase64 && avatarPreview) {
        avatarPreview.src = fullUser.photoBase64;
        avatarPreview.style.display = 'block';
        if (avatarPlaceholder) avatarPlaceholder.style.display = 'none';
    }

    if (photoInput && avatarPreview && avatarPlaceholder) {
        photoInput.addEventListener('change', (e) => {
            const file = e.target.files[0];
            if (file) {
                const reader = new FileReader();
                reader.onload = (e) => {
                    avatarPreview.src = e.target.result;
                    avatarPreview.style.display = 'block';
                    avatarPlaceholder.style.display = 'none';
                    // We'll save this base64 string on form submit
                    photoInput.dataset.base64 = e.target.result;
                };
                reader.readAsDataURL(file);
            }
        });
    }

    // Handle profile update
    const form = document.getElementById('profileForm');
    if (form) {
        form.addEventListener('submit', async (e) => {
            e.preventDefault();
            const newName = document.getElementById('fullname').value.trim();
            
            if (newName) {
                const btn = form.querySelector('button[type="submit"]');
                const originalText = btn.textContent;
                btn.textContent = 'Enregistrement...';
                btn.disabled = true;

                const updates = { name: newName };
                if (specialtyInput) updates.specialty = specialtyInput.value.trim();
                if (phoneInput) updates.phone = phoneInput.value.trim();
                if (cityInput) updates.city = cityInput.value.trim();
                if (linkedinInput) updates.linkedin = linkedinInput.value.trim();
                if (photoInput && photoInput.dataset.base64) {
                    updates.photoBase64 = photoInput.dataset.base64;
                }

                try {
                    await API.updateProfile(updates);
                    
                    // Update display name instantly
                    if (displayNameEl) displayNameEl.textContent = newName;
                    
                    const msg = document.getElementById('saveMessage');
                    msg.style.display = 'block';
                    setTimeout(() => msg.style.display = 'none', 3000);
                } catch(err) {
                    console.error(err);
                    alert("Erreur lors de la mise à jour");
                } finally {
                    btn.textContent = originalText;
                    btn.disabled = false;
                }
            }
        });
    }

    // Render History
    const historyList = document.getElementById('historyList');
    if (historyList) {
        if (!fullUser.history || fullUser.history.length === 0) {
            historyList.innerHTML = `
                <div style="text-align: center; padding: 3rem; background: var(--light); border-radius: var(--border-radius-lg); color: var(--gray-dark); border: 2px dashed var(--gray);">
                    <i class="ph ph-folder-open" style="font-size: 3rem; margin-bottom: 1rem; opacity: 0.5;"></i>
                    <p style="font-size: 1.1rem; margin-bottom: 1.5rem;">Vous n'avez généré aucun document pour le moment.</p>
                    <a href="dashboard.html" class="btn btn-primary">Créer mon premier document</a>
                </div>
            `;
        } else {
            historyList.innerHTML = fullUser.history.map(item => `
                <div class="history-item">
                    <div class="history-content">
                        <div class="history-icon">
                            <i class="ph ph-file-pdf"></i>
                        </div>
                        <div class="history-info">
                            <h4>${item.title}</h4>
                            <p><i class="ph ph-calendar-blank"></i> Généré le ${item.date}</p>
                        </div>
                    </div>
                    <div>
                        <button class="btn btn-outline" style="padding: 0.5rem 1.25rem; font-weight: 600;" title="Visualiser / Imprimer (Non disponible dans le MVP)">
                            <i class="ph ph-printer"></i>
                        </button>
                    </div>
                </div>
            `).join('');
        }
    }
});
