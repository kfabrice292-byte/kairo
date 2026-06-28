document.addEventListener('DOMContentLoaded', async () => {
    const listEl = document.getElementById('opportunitiesList');
    const filters = document.getElementById('filters');

    // Show loading state
    if (listEl) {
        listEl.innerHTML = `<div style="text-align: center; padding: 2rem; color: var(--gray-dark);">
            <i class="ph ph-spinner-gap" style="font-size: 2rem; animation: spin 1s linear infinite; margin-bottom: 1rem; color: var(--primary);"></i><br>
            Chargement des opportunités...
        </div>`;
    }

    let opportunities = [];
    try {
        opportunities = await API.getOpportunities();
    } catch (e) {
        console.error("Erreur de chargement", e);
        if (listEl) listEl.innerHTML = '<p>Erreur lors du chargement des opportunités.</p>';
        return;
    }

    const renderOpps = (filterType = 'all') => {
        listEl.innerHTML = '';
        const filtered = filterType === 'all' 
            ? opportunities 
            : opportunities.filter(o => o.type === filterType);
        
        if (filtered.length === 0) {
            listEl.innerHTML = '<p>Aucune opportunité trouvée pour cette catégorie.</p>';
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
