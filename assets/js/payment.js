document.addEventListener('DOMContentLoaded', () => {
    
    // Modal Logic
    const triggerPaymentBtn = document.getElementById('triggerPaymentBtn');
    const paymentModal = document.getElementById('paymentModal');
    const payNowBtn = document.getElementById('payNowBtn');
    const cancelPayment = document.getElementById('cancelPayment');
    
    // Views
    const previewView = document.getElementById('previewView');
    const successView = document.getElementById('successView');
    const redownloadBtn = document.getElementById('redownloadBtn');

    if (triggerPaymentBtn) {
        triggerPaymentBtn.addEventListener('click', () => {
            const currentUser = Storage.getUser();
            if (currentUser && currentUser.isPremium) {
                // Bypass payment if premium
                previewView.style.display = 'none';
                successView.style.display = 'block';
                successView.classList.add('active');
                setTimeout(() => {
                    downloadAllDocs();
                }, 500);
            } else {
                paymentModal.classList.add('active');
            }
        });
    }

    if (cancelPayment) {
        cancelPayment.addEventListener('click', (e) => {
            e.preventDefault();
            paymentModal.classList.remove('active');
        });
    }

    const downloadAllDocs = () => {
        // Pour garantir un PDF 100% vectoriel, texte sélectionnable (ATS-friendly),
        // nous utilisons l'API d'impression native du navigateur configurée via @media print.
        
        const selectedDocs = Storage.get('kairo_selected_docs') || [];
        const originalActive = document.querySelector('.tab-content.active');
        
        // 1. Rendre tous les documents sélectionnés visibles pour l'impression
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        selectedDocs.forEach(doc => {
            const sheet = document.getElementById(`tab-${doc}`);
            if (sheet) sheet.classList.add('active');
        });

        // 2. Déclencher la fenêtre d'impression (L'utilisateur choisit "Enregistrer au format PDF")
        window.print();

        // 3. Restaurer l'affichage normal
        document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
        if (originalActive) {
            originalActive.classList.add('active');
        } else if (selectedDocs.length > 0) {
            document.getElementById(`tab-${selectedDocs[0]}`).classList.add('active');
        }
    };

    if (payNowBtn) {
        payNowBtn.addEventListener('click', async () => {
            const currentUser = Storage.getUser();
            if (!currentUser) {
                window.showToast("Utilisateur non connecté");
                return;
            }

            const modalContent = document.querySelector('#paymentModal .modal-content') || paymentModal;
            
            modalContent.innerHTML = `
                <div class="p-6">
                    <div class="flex justify-between items-center mb-6">
                        <h3 class="text-xl font-bold text-slate-900">Paiement Mobile Money</h3>
                        <button id="closePaymentModal" class="text-slate-400 hover:text-slate-600">
                            <i class="ph-bold ph-x text-xl"></i>
                        </button>
                    </div>
                    <p class="text-slate-500 mb-4">Renseignez vos informations pour payer 350 FCFA</p>
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
                            <input type="tel" id="ashtechPhone" value="${currentUser.phone || ''}" placeholder="Ex: 0700000000" class="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                        </div>
                        <div id="ashtechError" class="text-red-500 text-sm hidden"></div>
                        <button id="ashtechSubmitBtn" class="w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition shadow-lg shadow-blue-500/30 flex justify-center items-center gap-2">
                            Payer 350 FCFA
                        </button>
                    </div>
                </div>
            `;

            document.getElementById('closePaymentModal').addEventListener('click', () => {
                paymentModal.classList.remove('active');
                window.location.reload(); // Reload pour restaurer l'état original du modal
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
                    // Les fonctions onCall() Firebase attendent un format JSON spécifique: { "data": { ... } }
                    const CLOUD_FUNCTION_URL = "https://us-central1-kairo-522c2.cloudfunctions.net/initiatePayment"; 
                    
                    const response = await fetch(CLOUD_FUNCTION_URL, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({
                            data: {
                                uid: currentUser.uid,
                                productId: "cv_export",
                                phone: phone,
                                operator: operator,
                                country_code: country
                            }
                        })
                    });

                    // Les fonctions onCall() renvoient la réponse sous { "result": { ... } }
                    const rawData = await response.json();
                    const data = rawData.result ? rawData.result.data : rawData.data;
                    const status = rawData.result ? rawData.result.status : response.status;
                    
                    if (status === 202) {
                        if (data.flow === 'wave') {
                            modalContent.innerHTML = `
                                <div class="p-6 text-center">
                                    <div class="w-16 h-16 bg-blue-50 text-blue-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                                        <i class="ph-fill ph-qr-code text-4xl"></i>
                                    </div>
                                    <h3 class="text-xl font-bold text-slate-900 mb-2">Paiement Wave</h3>
                                    <p class="text-slate-500 mb-4">Ouvrez l'application Wave pour confirmer le paiement.</p>
                                    <a href="${data.wave_url}" target="_blank" class="block w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 mb-2">Ouvrir Wave</a>
                                    <button id="paymentSuccessBtn" class="w-full py-3 bg-slate-100 text-slate-700 rounded-xl font-bold">J'ai payé</button>
                                </div>
                            `;
                        } else {
                            modalContent.innerHTML = `
                                <div class="p-6 text-center">
                                    <div class="w-16 h-16 bg-green-50 text-green-500 rounded-2xl flex items-center justify-center mx-auto mb-4">
                                        <i class="ph-fill ph-device-mobile text-4xl"></i>
                                    </div>
                                    <h3 class="text-xl font-bold text-slate-900 mb-2">Vérifiez votre téléphone</h3>
                                    <p class="text-slate-500 mb-4">Veuillez valider le paiement sur votre téléphone portable.</p>
                                    <button id="paymentSuccessBtn" class="w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700">J'ai validé</button>
                                </div>
                            `;
                        }
                        
                        document.getElementById('paymentSuccessBtn').addEventListener('click', () => {
                            paymentModal.classList.remove('active');
                            previewView.style.display = 'none';
                            successView.style.display = 'block';
                            successView.classList.add('active');
                            setTimeout(() => { downloadAllDocs(); }, 500);
                        });
                        
                    } else if (status === 400 && data.error === 'otp_required') {
                        modalContent.innerHTML = `
                            <div class="p-6 text-center">
                                <h3 class="text-xl font-bold text-slate-900 mb-2">Validation OTP</h3>
                                <p class="text-slate-500 mb-4">
                                    ${data.ussd_code ? 'Veuillez composer le <strong>' + data.ussd_code + '</strong> sur votre téléphone pour obtenir votre code.' : 'Un code OTP vous a été envoyé par SMS.'}
                                </p>
                                <input type="number" id="ashtechOtp" placeholder="Code OTP" class="w-full px-4 py-2 bg-slate-50 border border-slate-200 rounded-xl mb-4 focus:ring-2 focus:ring-blue-500 outline-none transition-all">
                                <div id="otpError" class="text-red-500 text-sm hidden mb-4"></div>
                                <button id="validateOtpBtn" class="w-full py-3 bg-blue-600 text-white rounded-xl font-bold hover:bg-blue-700 transition">Valider</button>
                            </div>
                        `;
                        
                        document.getElementById('validateOtpBtn').addEventListener('click', async () => {
                            const otpVal = document.getElementById('ashtechOtp').value.trim();
                            if (!otpVal) return;
                            
                            const otpBtn = document.getElementById('validateOtpBtn');
                            otpBtn.innerHTML = '<i class="ph-bold ph-spinner animate-spin"></i> Validation...';
                            otpBtn.disabled = true;
                            
                            try {
                                const otpRes = await fetch(CLOUD_FUNCTION_URL, {
                                    method: "POST",
                                    headers: { "Content-Type": "application/json" },
                                    body: JSON.stringify({
                                        data: {
                                            uid: currentUser.uid,
                                            productId: "cv_export",
                                            phone: phone,
                                            operator: operator,
                                            country_code: country,
                                            otp: otpVal,
                                            reference: data.reference
                                        }
                                    })
                                });
                                const rawOtpData = await otpRes.json();
                                const otpData = rawOtpData.result ? rawOtpData.result.data : rawOtpData.data;
                                const otpStatus = rawOtpData.result ? rawOtpData.result.status : otpRes.status;

                                if (otpStatus === 202) {
                                    paymentModal.classList.remove('active');
                                    previewView.style.display = 'none';
                                    successView.style.display = 'block';
                                    successView.classList.add('active');
                                    setTimeout(() => { downloadAllDocs(); }, 500);
                                } else {
                                    document.getElementById('otpError').textContent = otpData.message || 'Erreur OTP';
                                    document.getElementById('otpError').classList.remove('hidden');
                                    otpBtn.innerHTML = 'Valider';
                                    otpBtn.disabled = false;
                                }
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
                    submitBtn.innerHTML = 'Payer 350 FCFA';
                    submitBtn.disabled = false;
                }
            });
    }

    if (redownloadBtn) {
        redownloadBtn.addEventListener('click', () => {
            // On s'assure que previewView est visible pendant l'impression 
            // car @media print cache les éléments invisibles du DOM.
            successView.style.display = 'none';
            previewView.style.display = 'flex';
            
            downloadAllDocs();
            
            previewView.style.display = 'none';
            successView.style.display = 'block';
        });
    }
});
