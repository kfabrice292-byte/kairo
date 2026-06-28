document.addEventListener('DOMContentLoaded', async () => {
    // Basic auth check for MVP
    const currentUser = await API.getCurrentUser();
    if (!currentUser) {
        window.location.href = 'login.html';
        return;
    }

    const usersTableBody = document.getElementById('usersTableBody');
    const totalUsersEl = document.getElementById('totalUsers');
    const totalOppsEl = document.getElementById('totalOpps');
    const oppForm = document.getElementById('oppForm');

    // Show loading state
    if (usersTableBody) usersTableBody.innerHTML = `<tr><td colspan="4" style="text-align: center; color: var(--gray-dark);">Chargement des données...</td></tr>`;

    // Load Data
    let users = [];
    let opportunities = [];
    try {
        [users, opportunities] = await Promise.all([
            API.getAllUsers(),
            API.getOpportunities()
        ]);
    } catch (e) {
        console.error("Erreur chargement données", e);
    }

    const updateStats = () => {
        totalUsersEl.textContent = users.length;
        totalOppsEl.textContent = opportunities.length;
    };

    const renderUsers = () => {
        if (users.length === 0) {
            usersTableBody.innerHTML = `<tr><td colspan="4" style="text-align: center; color: var(--gray-dark);">Aucun utilisateur inscrit.</td></tr>`;
            return;
        }

        usersTableBody.innerHTML = users.map(user => {
            const points = user.points !== undefined ? user.points : 1000;
            const historyCount = user.history ? user.history.length : 0;
            
            return `
                <tr>
                    <td style="font-weight: 600;">${user.name}</td>
                    <td style="color: var(--gray-dark);">${user.email}</td>
                    <td><span class="badge" style="background: rgba(249, 115, 22, 0.1); color: var(--primary);">${points} pts</span></td>
                    <td>${historyCount} document(s)</td>
                </tr>
            `;
        }).join('');
    };

    // Form Submission for New Opportunity
    if (oppForm) {
        oppForm.addEventListener('submit', async (e) => {
            e.preventDefault();

            const newOpp = {
                title: document.getElementById('oppTitle').value.trim(),
                company: document.getElementById('oppCompany').value.trim(),
                type: document.getElementById('oppType').value,
                location: document.getElementById('oppLocation').value.trim()
            };

            if (newOpp.title && newOpp.company && newOpp.location) {
                const btn = oppForm.querySelector('button[type="submit"]');
                const originalText = btn.textContent;
                btn.textContent = 'Publication...';
                btn.disabled = true;

                try {
                    const savedOpp = await API.publishOpportunity(newOpp);
                    opportunities.unshift(savedOpp);
                    
                    // Update UI
                    updateStats();
                    
                    // Show success
                    const msg = document.getElementById('oppMessage');
                    msg.style.display = 'block';
                    oppForm.reset();
                    
                    setTimeout(() => {
                        msg.style.display = 'none';
                    }, 3000);
                } catch(err) {
                    console.error("Erreur lors de la publication", err);
                    alert("Erreur lors de la publication de l'opportunité.");
                } finally {
                    btn.textContent = originalText;
                    btn.disabled = false;
                }
            }
        });
    }

    // Initialize Page
    updateStats();
    renderUsers();
});
