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
            paymentModal.classList.add('active');
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
        payNowBtn.addEventListener('click', () => {
            // Simulate Payment Processing
            const originalText = payNowBtn.innerHTML;
            payNowBtn.innerHTML = "Traitement du paiement...";
            payNowBtn.disabled = true;

            setTimeout(() => {
                paymentModal.classList.remove('active');
                
                // --- Points & History Logic ---
                const currentUser = Storage.getUser();
                if (currentUser) {
                    let users = Storage.get('kairo_users_db') || [];
                    const userIndex = users.findIndex(u => u.email === currentUser.email);
                    
                    if (userIndex !== -1) {
                        // Déduire les points (ex: 100 points pour un pack complet)
                        users[userIndex].points = Math.max(0, (users[userIndex].points || 1000) - 100);
                        
                        // Enregistrer dans l'historique
                        const selectedDocs = Storage.get('kairo_selected_docs') || [];
                        const docsLabels = {
                            'cv': 'CV Professionnel',
                            'motivation': 'Lettre de Motivation',
                            'stage': 'Demande de Stage'
                        };
                        const docNames = selectedDocs.map(d => docsLabels[d] || d).join(' + ');
                        
                        if (!users[userIndex].history) users[userIndex].history = [];
                        
                        users[userIndex].history.unshift({
                            title: `Pack : ${docNames}`,
                            date: new Date().toLocaleDateString('fr-FR'),
                            id: Date.now()
                        });
                        
                        Storage.set('kairo_users_db', users);
                        Storage.setUser({ ...currentUser, points: users[userIndex].points });
                    }
                }
                // --- Fin Points & History ---

                // Hide preview, show success
                previewView.style.display = 'none';
                successView.style.display = 'block';
                successView.classList.add('active');

                // Trigger ATS-friendly PDF generation via Print Dialog
                // On met un léger délai pour laisser le temps au DOM de s'afficher
                setTimeout(() => {
                    downloadAllDocs();
                }, 500);

                payNowBtn.innerHTML = originalText;
                payNowBtn.disabled = false;

            }, 1500);
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
