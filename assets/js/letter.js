document.addEventListener('DOMContentLoaded', () => {
    const user = Storage.getUser();
    if (!user) {
        window.location.href = 'login.html';
        return;
    }

    const letterForm = document.getElementById('letterForm');
    const letterSheet = document.getElementById('letterSheet');
    const downloadBtn = document.getElementById('downloadLetterBtn');

    letterForm.addEventListener('submit', (e) => {
        e.preventDefault();

        const company = document.getElementById('company').value;
        const position = document.getElementById('position').value;
        const motivation = document.getElementById('motivation').value;
        const highlight = document.getElementById('highlight').value;
        
        const date = new Date().toLocaleDateString('fr-FR');

        letterSheet.innerHTML = `
            <div style="margin-bottom: 2rem;">
                <strong>${user.name}</strong><br>
                ${user.email}<br>
            </div>
            
            <div style="text-align: right; margin-bottom: 2rem;">
                <strong>Ã€ l'attention du Responsable Recrutement</strong><br>
                ${company}<br>
                Date: ${date}
            </div>

            <div style="margin-bottom: 1.5rem; font-weight: bold;">
                Objet : Candidature pour le poste de ${position}
            </div>

            <div style="margin-bottom: 1rem;">Madame, Monsieur,</div>

            <div style="margin-bottom: 1rem; line-height: 1.6;">
                C'est avec un grand intÃ©rÃªt que je vous soumets ma candidature pour le poste de ${position} au sein de ${company}. 
                ${motivation}
            </div>

            <div style="margin-bottom: 1rem; line-height: 1.6;">
                Au cours de mon parcours, j'ai eu l'opportunitÃ© de dÃ©velopper mes compÃ©tences. ${highlight} 
                Je suis convaincu(e) que ces acquis me permettront de contribuer efficacement Ã  vos projets.
            </div>

            <div style="margin-bottom: 1rem; line-height: 1.6;">
                Je me tiens Ã  votre entiÃ¨re disposition pour un entretien afin de vous dÃ©tailler mes motivations de vive voix.
            </div>

            <div style="margin-bottom: 2rem;">
                Dans cette attente, je vous prie d'agrÃ©er, Madame, Monsieur, l'expression de mes salutations distinguÃ©es.
            </div>

            <div style="text-align: right;">
                <strong>${user.name}</strong>
            </div>
        `;
    });

    if (downloadBtn) {
        downloadBtn.addEventListener('click', async () => {
            // Check if letter generated
            if (letterSheet.innerText.includes('Remplis le formulaire')) {
                alert("Veuillez d'abord gÃ©nÃ©rer la lettre.");
                return;
            }

            const originalText = downloadBtn.textContent;
            downloadBtn.textContent = 'GÃ©nÃ©ration...';
            downloadBtn.disabled = true;

            try {
                const canvas = await html2canvas(letterSheet, { scale: 2, useCORS: true, logging: false });
                const imgData = canvas.toDataURL('image/png');
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                const pdfWidth = pdf.internal.pageSize.getWidth();
                const pdfHeight = (canvas.height * pdfWidth) / canvas.width;
                pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
                pdf.save(`Lettre_${company.replace(/\s+/g, '_')}.pdf`);
            } catch (error) {
                console.error(error);
                alert("Erreur lors de l'export PDF");
            } finally {
                downloadBtn.textContent = originalText;
                downloadBtn.disabled = false;
            }
        });
    }
});

