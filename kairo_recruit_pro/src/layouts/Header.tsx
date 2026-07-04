import { Bell, User, LogOut } from "lucide-react";
import { useAuthStore } from "../store/useAuthStore";
import { useNavigate } from "react-router-dom";

export function Header() {
  const { profile, logout } = useAuthStore();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    navigate('/login');
  };

  return (
    <header className="h-16 bg-white dark:bg-slate-950 border-b border-slate-200 dark:border-slate-800 flex items-center justify-between px-6">
      <div className="flex items-center">
        <h2 className="text-lg font-semibold text-slate-800 dark:text-slate-200">Tableau de bord</h2>
      </div>
      <div className="flex items-center space-x-4">
        <button className="p-2 rounded-full text-slate-500 hover:bg-slate-100 dark:hover:bg-slate-900 transition-colors relative">
          <Bell className="w-5 h-5" />
          <span className="absolute top-1.5 right-1.5 w-2 h-2 bg-red-500 rounded-full border border-white dark:border-slate-950"></span>
        </button>
        <div className="flex items-center space-x-3 pl-4 border-l border-slate-200 dark:border-slate-800">
          <div className="flex flex-col items-end">
            <span className="text-sm font-medium">{profile?.name || "Recruteur Pro"}</span>
            <span className="text-xs text-slate-500">{profile?.companyName || "Entreprise"}</span>
          </div>
          <div className="w-9 h-9 rounded-full bg-primary/20 flex items-center justify-center text-primary">
            <User className="w-5 h-5" />
          </div>
          <button 
            onClick={handleLogout}
            className="p-2 ml-2 rounded-full text-slate-500 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-950/30 transition-colors"
            title="Se déconnecter"
          >
            <LogOut className="w-5 h-5" />
          </button>
        </div>
      </div>
    </header>
  );
}
