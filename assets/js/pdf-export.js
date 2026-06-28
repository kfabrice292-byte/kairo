document.addEventListener('DOMContentLoaded', () => {
    const downloadBtn = document.getElementById('downloadPdfBtn');
    
    if (downloadBtn) {
        downloadBtn.addEventListener('click', async () => {
            const cvSheet = document.getElementById('cvSheet');
            
            // Visual feedback
            const originalText = downloadBtn.textContent;
            downloadBtn.textContent = 'GÃ©nÃ©ration...';
            downloadBtn.disabled = true;

            try {
                // html2canvas config
                const canvas = await html2canvas(cvSheet, {
                    scale: 2, // High resolution
                    useCORS: true,
                    logging: false
                });

                const imgData = canvas.toDataURL('image/png');
                
                // Initialize jsPDF
                const { jsPDF } = window.jspdf;
                const pdf = new jsPDF('p', 'mm', 'a4');
                
                const pdfWidth = pdf.internal.pageSize.getWidth();
                const pdfHeight = (canvas.height * pdfWidth) / canvas.width;
                
                pdf.addImage(imgData, 'PNG', 0, 0, pdfWidth, pdfHeight);
                
                // Trigger download
                const userName = Storage.getUser()?.name || 'CV';
                const filename = `CV_${userName.replace(/\s+/g, '_')}.pdf`;
                pdf.save(filename);

            } catch (error) {
                console.error("Erreur lors de l'export PDF:", error);
                alert("Une erreur est survenue lors de la crÃ©ation du PDF.");
            } finally {
                downloadBtn.textContent = originalText;
                downloadBtn.disabled = false;
            }
        });
    }
});

