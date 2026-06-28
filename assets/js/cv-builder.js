document.addEventListener('DOMContentLoaded', () => {
    const cvSheet = document.getElementById('cvSheet');

    const renderCV = (data) => {
        let educationHtml = data.education.map(edu => `<div class="cv-item"><div class="cv-item-title">${edu}</div></div>`).join('');
        let experienceHtml = data.experience.map(exp => `<div class="cv-item"><div class="cv-item-title">${exp}</div></div>`).join('');
        let skillsHtml = data.skills.length ? `<div class="cv-item">${data.skills.join(' â€¢ ')}</div>` : '';

        cvSheet.innerHTML = `
            <div class="cv-header-info">
                <div class="cv-name">${data.name || 'Ton Nom'}</div>
                <div class="cv-contact">
                    ${data.email ? `ðŸ“§ ${data.email}` : ''} 
                    ${data.phone ? ` | ðŸ“± ${data.phone}` : ''}
                </div>
            </div>
            
            ${educationHtml ? `
            <div class="cv-section">
                <div class="cv-section-title">Formation</div>
                ${educationHtml}
            </div>` : ''}

            ${experienceHtml ? `
            <div class="cv-section">
                <div class="cv-section-title">ExpÃ©rience Professionnelle</div>
                ${experienceHtml}
            </div>` : ''}

            ${skillsHtml ? `
            <div class="cv-section">
                <div class="cv-section-title">CompÃ©tences</div>
                ${skillsHtml}
            </div>` : ''}
        `;
    };

    // Initialize Chatbot with the render callback
    window.kairoChatbot = new Chatbot(renderCV);
});

