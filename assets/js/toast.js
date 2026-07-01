class ToastManager {
    constructor() {
        this.container = document.getElementById('toast-container');
        if (!this.container) {
            this.container = document.createElement('div');
            this.container.id = 'toast-container';
            document.body.appendChild(this.container);
        }
        
        // Add CSS if not present
        if (!document.querySelector('link[href*="toast.css"]')) {
            const link = document.createElement('link');
            link.rel = 'stylesheet';
            link.href = 'assets/css/toast.css';
            document.head.appendChild(link);
        }
    }

    show(options) {
        const {
            title = '',
            message,
            type = 'info', // 'success', 'error', 'info', 'warning'
            duration = 4000
        } = options;

        const toast = document.createElement('div');
        toast.className = `toast toast-${type}`;

        let iconClass = 'ph-info';
        if (type === 'success') iconClass = 'ph-check-circle';
        if (type === 'error') iconClass = 'ph-warning-circle';
        if (type === 'warning') iconClass = 'ph-warning';

        toast.innerHTML = `
            <div class="toast-icon">
                <i class="ph-fill ${iconClass}"></i>
            </div>
            <div class="toast-content">
                ${title ? `<span class="toast-title">${title}</span>` : ''}
                <span class="toast-message">${message}</span>
            </div>
            <button class="toast-close">
                <i class="ph ph-x"></i>
            </button>
        `;

        this.container.appendChild(toast);

        // Trigger animation
        requestAnimationFrame(() => {
            toast.classList.add('show');
        });

        // Close button event
        const closeBtn = toast.querySelector('.toast-close');
        closeBtn.addEventListener('click', () => this.remove(toast));

        // Auto remove
        if (duration > 0) {
            setTimeout(() => {
                this.remove(toast);
            }, duration);
        }
    }

    remove(toast) {
        if (!toast.classList.contains('removing')) {
            toast.classList.add('removing');
            toast.classList.remove('show');
            setTimeout(() => {
                if (toast.parentElement) {
                    toast.parentElement.removeChild(toast);
                }
            }, 300);
        }
    }

    success(message, title = 'Succès') {
        this.show({ message, title, type: 'success' });
    }

    error(message, title = 'Erreur') {
        this.show({ message, title, type: 'error', duration: 6000 });
    }

    info(message, title = 'Info') {
        this.show({ message, title, type: 'info' });
    }

    warning(message, title = 'Attention') {
        this.show({ message, title, type: 'warning', duration: 5000 });
    }
}

// Create a global instance
window.Toast = new ToastManager();
export default window.Toast;
