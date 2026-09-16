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

    const premiumBadge = document.getElementById('premiumBadge');
    const upgradePremiumBtn = document.getElementById('upgradePremiumBtn');
    if (premiumBadge && upgradePremiumBtn) {
        if (fullUser.isPremium) {
            premiumBadge.classList.remove('hidden');
            upgradePremiumBtn.classList.add('hidden');
            upgradePremiumBtn.classList.remove('flex');
        } else {
            premiumBadge.classList.add('hidden');
            upgradePremiumBtn.classList.remove('hidden');
            upgradePremiumBtn.classList.add('flex');
        }
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
                <div class="empty-state-card" style="text-align: center; padding: 4rem 2rem; background: var(--light); border-radius: var(--border-radius-lg); border: 2px dashed var(--gray);">
                    <i class="ph ph-folder-open empty-state-illustration" style="font-size: 4rem; color: var(--primary); margin-bottom: 1rem;"></i>
                    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem; color: var(--dark);">Aucun document généré</h3>
                    <p style="color: var(--gray-dark); margin-bottom: 1.5rem;">Vous n'avez pas encore généré de CV ou de lettre de motivation. Commencez dès maintenant !</p>
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

    // --- PREMIUM LOGIC (ASHTECHPAY) ---
    const confirmPremiumBtn = document.getElementById('confirmPremiumBtn');
    const premiumModal = document.getElementById('premiumModal');
    
    // Si l'utilisateur clique sur "Passer Premium" dans le HTML
    if (upgradePremiumBtn && premiumModal) {
        upgradePremiumBtn.addEventListener('click', () => {
            premiumModal.classList.remove('hidden');
        });
    }

    if (confirmPremiumBtn) {
        confirmPremiumBtn.addEventListener('click', async () => {
            const user = Storage.getUser();
            if (!user) return;
            
            document.getElementById('premiumStep1').classList.add('hidden');
            const step2 = document.getElementById('premiumStep2');
            step2.classList.remove('hidden');
            
            // Afficher le formulaire AshtechPay
            step2.innerHTML = `
                <h3 class="text-xl font-bold text-slate-900 mb-2">Paiement Mobile Money</h3>
                <p class="text-slate-500 mb-4">Renseignez vos informations pour payer 1000 FCFA</p>
                <div class="space-y-4 text-left">
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-1">Pays</label>
                        <select id="ashtechCountry" class="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                            <option value="CI">Côte d'Ivoire</option>
                            <option value="SN">Sénégal</option>
                            <option value="CM">Cameroun</option>
                            <option value="BF">Burkina Faso</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-1">Opérateur</label>
                        <select id="ashtechOperator" class="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                            <option value="Orange Money">Orange Money</option>
                            <option value="MTN Mobile Money">MTN Mobile Money</option>
                            <option value="Moov Money">Moov Money</option>
                            <option value="Wave">Wave</option>
                            <option value="Free Money">Free Money</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-sm font-medium text-slate-700 mb-1">Numéro de téléphone</label>
                        <input type="tel" id="ashtechPhone" value="${user.phone || ''}" placeholder="Ex: 0700000000" class="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                    </div>
                    <div id="ashtechError" class="text-red-500 text-sm hidden"></div>
                    <button id="ashtechSubmitBtn" class="w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition shadow-lg shadow-blue-500/30 flex justify-center items-center gap-2">
                        Payer 1000 FCFA
                    </button>
                    <button id="ashtechCancelBtn" class="w-full py-3 bg-slate-100 text-slate-700 rounded-xl font-bold hover:bg-slate-200 transition mt-2">
                        Annuler
                    </button>
                </div>
            `;

            document.getElementById('ashtechCancelBtn').addEventListener('click', () => {
                premiumModal.classList.add('hidden');
                document.getElementById('premiumStep1').classList.remove('hidden');
                step2.classList.add('hidden');
            });

            const submitBtn = document.getElementById('ashtechSubmitBtn');
            submitBtn.addEventListener('click', async () => {
                const phone = document.getElementById('ashtechPhone').value.trim();
                const operator = document.getElementById('ashtechOperator').value;
                const country = document.getElementById('ashtechCountry').value;
                const errorDiv = document.getElementById('ashtechError');
                
                if (!phone) {
                    errorDiv.textContent = 'Veuillez entrer votre numéro de téléphone';
                    errorDiv.classList.remove('hidden');
                    return;
                }
                
                errorDiv.classList.add('hidden');
                submitBtn.innerHTML = '<i class="ph-bold ph-spinner animate-spin"></i> Traitement...';
                submitBtn.disabled = true;

                try {
                    const result = await API.initiatePayment('premium_monthly', phone, operator, country);
                    const response = { status: result.status };
                    const data = result.data;
                    
                    if (response.status === 202) {
                        if (data.flow === 'wave') {
                            step2.innerHTML = `
                                <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                                    <i class="ph-fill ph-qr-code text-4xl"></i>
                                </div>
                                <h3 class="text-xl font-bold text-slate-900 mb-2">Paiement Wave</h3>
                                <p class="text-slate-500 mb-4">Ouvrez l'application Wave pour confirmer le paiement.</p>
                                <a href="${data.wave_url}" target="_blank" class="block w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 text-center mb-2">Ouvrir Wave</a>
                                <button onclick="document.getElementById('premiumModal').classList.add('hidden')" class="w-full py-3 bg-slate-100 text-slate-700 rounded-xl font-bold">Fermer</button>
                            `;
                        } else {
                            step2.innerHTML = `
                                <div class="w-16 h-16 bg-green-50 text-green-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                                    <i class="ph-fill ph-device-mobile text-4xl"></i>
                                </div>
                                <h3 class="text-xl font-bold text-slate-900 mb-2">Vérifiez votre téléphone</h3>
                                <p class="text-slate-500 mb-4">Veuillez valider le paiement sur votre téléphone portable. Votre compte sera mis à jour automatiquement.</p>
                                <button onclick="document.getElementById('premiumModal').classList.add('hidden')" class="w-full py-3 bg-slate-100 text-slate-700 rounded-xl font-bold">Fermer</button>
                            `;
                        }
                    } else if (response.status === 400 && data.error === 'otp_required') {
                        step2.innerHTML = `
                            <h3 class="text-xl font-bold text-slate-900 mb-2">Validation OTP</h3>
                            <p class="text-slate-500 mb-4">
                                ${data.ussd_code ? 'Veuillez composer le <strong>' + data.ussd_code + '</strong> sur votre téléphone pour obtenir votre code.' : 'Un code OTP vous a été envoyé par SMS.'}
                            </p>
                            <input type="number" id="ashtechOtp" placeholder="Code OTP" class="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl mb-4 focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                            <div id="otpError" class="text-red-500 text-sm hidden mb-4"></div>
                            <button id="validateOtpBtn" class="w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition">
                                Valider
                            </button>
                        `;
                        
                        document.getElementById('validateOtpBtn').addEventListener('click', async () => {
                            const otpVal = document.getElementById('ashtechOtp').value.trim();
                            if (!otpVal) return;
                            
                            const otpBtn = document.getElementById('validateOtpBtn');
                            otpBtn.innerHTML = '<i class="ph-bold ph-spinner animate-spin"></i> Validation...';
                            otpBtn.disabled = true;
                            
                            try {
                                // MOCK: Normalement on appellerait une autre fonction onCall pour valider l'OTP
                                // Pour l'instant on affiche juste une attente
                                step2.innerHTML = `
                                    <div class="w-16 h-16 bg-green-50 text-green-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                                        <i class="ph-fill ph-check-circle text-4xl"></i>
                                    </div>
                                    <h3 class="text-xl font-bold text-slate-900 mb-2">En attente</h3>
                                    <p class="text-slate-500 mb-4">OTP envoyé. Votre compte sera mis à jour automatiquement dès réception du Webhook.</p>
                                    <button onclick="document.getElementById('premiumModal').classList.add('hidden')" class="w-full py-3 bg-slate-100 text-slate-700 rounded-xl font-bold">Fermer</button>
                                `;
                            } catch (e) {
                                document.getElementById('otpError').textContent = 'Erreur réseau';
                                document.getElementById('otpError').classList.remove('hidden');
                                otpBtn.innerHTML = 'Valider';
                                otpBtn.disabled = false;
                            }
                        });
                    } else {
                        throw new Error(data.message || data.error || "Erreur de paiement");
                    }
                } catch (error) {
                    console.error("Erreur de paiement:", error);
                    errorDiv.textContent = error.message;
                    errorDiv.classList.remove('hidden');
                    submitBtn.innerHTML = 'Payer 1000 FCFA';
                    submitBtn.disabled = false;
                }
            });
        });
    }
});
