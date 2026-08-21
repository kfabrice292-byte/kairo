document.addEventListener('DOMContentLoaded', async () => {
    const listEl = document.getElementById('opportunitiesList');
    const filters = document.getElementById('filters');

    // Show skeleton loading state
    if (listEl) {
        listEl.innerHTML = `
            <div class="card opp-card skeleton-shimmer" style="height: 180px; border-color: transparent;"></div>
            <div class="card opp-card skeleton-shimmer" style="height: 180px; border-color: transparent; opacity: 0.8;"></div>
            <div class="card opp-card skeleton-shimmer" style="height: 180px; border-color: transparent; opacity: 0.5;"></div>
        `;
    }

    let opportunities = [];
    try {
        opportunities = await API.getOpportunities();
    } catch (e) {
        console.error("Erreur de chargement", e);
        if (listEl) {
            listEl.innerHTML = `
                <div class="empty-state-card" style="text-align: center; padding: 4rem 2rem; background: var(--light); border-radius: var(--border-radius-lg); border: 2px dashed var(--gray);">
                    <i class="ph ph-warning-circle empty-state-illustration" style="font-size: 4rem; color: var(--danger); margin-bottom: 1rem;"></i>
                    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem; color: var(--dark);">Erreur de connexion</h3>
                    <p style="color: var(--gray-dark); margin-bottom: 1.5rem;">Impossible de charger les opportunités. Veuillez vérifier votre connexion.</p>
                    <button class="btn btn-outline" onclick="window.location.reload()">Réessayer</button>
                </div>
            `;
        }
        return;
    }

    const renderOpps = (filterType = 'all') => {
        listEl.innerHTML = '';
        const filtered = filterType === 'all' 
            ? opportunities 
            : opportunities.filter(o => o.type === filterType);
        
        if (filtered.length === 0) {
            listEl.innerHTML = `
                <div class="empty-state-card" style="text-align: center; padding: 4rem 2rem; background: var(--light); border-radius: var(--border-radius-lg); border: 2px dashed var(--gray);">
                    <i class="ph ph-magnifying-glass empty-state-illustration" style="font-size: 4rem; color: var(--primary); margin-bottom: 1rem;"></i>
                    <h3 style="font-size: 1.25rem; font-weight: 700; margin-bottom: 0.5rem; color: var(--dark);">Aucune opportunité trouvée</h3>
                    <p style="color: var(--gray-dark); margin-bottom: 1.5rem;">Nous n'avons trouvé aucune offre pour cette catégorie actuellement.</p>
                    <button class="btn btn-primary" onclick="document.querySelector('.filter-btn[data-filter=\\'all\\']').click()">Voir toutes les offres</button>
                </div>
            `;
            return;
        }

        filtered.forEach(opp => {
            listEl.innerHTML += `
                <div class="card opp-card">
                    <span class="opp-tag">${opp.type}</span>
                    <h3 class="card-title">${opp.title}</h3>
                    <div style="color: var(--dark); font-weight: 500;">${opp.company}</div>
                    <div class="card-desc">📍 ${opp.location}</div>
                    <button class="btn btn-outline" style="margin-top: 1rem; width: 100%;">Postuler</button>
                </div>
            `;
        });
    };

    // Initial render
    renderOpps();

    // Filter logic
    if (filters) {
        filters.addEventListener('click', (e) => {
            if (e.target.classList.contains('filter-btn')) {
                // Remove active class
                document.querySelectorAll('.filter-btn').forEach(btn => btn.classList.remove('active'));
                // Add to clicked
                e.target.classList.add('active');
                
                renderOpps(e.target.dataset.filter);
            }
        });
    }
});
