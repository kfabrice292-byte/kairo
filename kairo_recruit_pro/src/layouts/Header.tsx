import { Bell, User, LogOut, Download } from "lucide-react";
import { useAuthStore } from "../store/useAuthStore";
import { useNavigate } from "react-router-dom";
import { useState, useEffect } from "react";

export function Header() {
  const { profile, logout } = useAuthStore();
  const navigate = useNavigate();
  const [deferredPrompt, setDeferredPrompt] = useState<any>(null);
  const [isInstallable, setIsInstallable] = useState(false);

  useEffect(() => {
    window.addEventListener('beforeinstallprompt', (e) => {
      e.preventDefault();
      setDeferredPrompt(e);
      setIsInstallable(true);
    });
  }, []);

  const handleInstallClick = async () => {
    if (deferredPrompt) {
      deferredPrompt.prompt();
      const { outcome } = await deferredPrompt.userChoice;
      if (outcome === 'accepted') {
        setIsInstallable(false);
      }
      setDeferredPrompt(null);
    }
  };

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <header className="h-20 bg-white/60 backdrop-blur-xl z-20 border-b border-white flex items-center justify-between px-8 sticky top-0 shadow-sm">
      <div className="flex items-center">
        <h2 className="text-2xl font-extrabold text-slate-800 tracking-tight">Espace {profile?.accountType === 'cabinet' ? 'Cabinet' : 'Entreprise'}</h2>
      </div>
      <div className="flex items-center space-x-6">
        
        {/* PWA Install Button (Only for Cabinet) */}
        {profile?.accountType === 'cabinet' && isInstallable && (
          <button 
            onClick={handleInstallClick}
            className="flex items-center gap-2 px-4 py-2 bg-gradient-to-r from-purple-600 to-indigo-600 hover:from-purple-700 hover:to-indigo-700 text-white text-sm font-bold rounded-full shadow-lg shadow-purple-500/30 hover:shadow-purple-500/50 hover:-translate-y-0.5 transition-all"
          >
            <Download size={16} />
            Installer l'App
          </button>
        )}

        <button className="p-2.5 rounded-full text-slate-500 hover:text-orange-500 hover:bg-orange-50 transition-colors relative">
          <Bell className="w-6 h-6" />
          <span className="absolute top-2 right-2 w-2.5 h-2.5 bg-red-500 rounded-full border-2 border-white"></span>
        </button>

        <div className="flex items-center space-x-4 pl-6 border-l border-slate-200">
          <div className="flex flex-col items-end">
            <span className="text-sm font-bold text-slate-800">{profile?.name || "Recruteur Pro"}</span>
            <span className="text-xs font-medium text-orange-500 uppercase tracking-wider">{profile?.companyName || "Entreprise"}</span>
          </div>
          <div className="w-11 h-11 rounded-xl bg-gradient-to-br from-orange-100 to-orange-200 flex items-center justify-center text-orange-600 shadow-inner">
            <User className="w-6 h-6" />
          </div>
          <button 
            onClick={handleLogout}
            className="p-2.5 ml-2 rounded-full text-slate-400 hover:text-red-500 hover:bg-red-50 transition-colors"
            title="Se déconnecter"
          >
            <LogOut className="w-6 h-6" />
          </button>
        </div>
      </div>
    </header>
  );
}
