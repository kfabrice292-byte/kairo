import { Bell, Lock, User, Moon, Building } from "lucide-react";
import { useAuthStore } from "../store/useAuthStore";
import { useEffect, useState } from "react";

export function Settings() {
  const { profile } = useAuthStore();
  const [isDarkMode, setIsDarkMode] = useState(true);

  useEffect(() => {
    // Simple mock logic for dark mode toggle UI
    const isDark = document.documentElement.classList.contains('dark');
    setIsDarkMode(isDark);
  }, []);

  const toggleDarkMode = () => {
    if (isDarkMode) {
      document.documentElement.classList.remove('dark');
    } else {
      document.documentElement.classList.add('dark');
    }
    setIsDarkMode(!isDarkMode);
  };

  return (
    <div className="h-full flex flex-col overflow-y-auto pb-8">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Paramètres</h1>
        <p className="text-slate-500 dark:text-slate-400">Gérez votre compte et vos préférences.</p>
      </div>
      
      <div className="max-w-4xl grid grid-cols-1 md:grid-cols-3 gap-8">
        
        {/* Navigation Sidebar for settings (Visual only) */}
        <div className="space-y-1">
          <button className="w-full flex items-center px-4 py-3 bg-primary/10 text-primary dark:bg-primary/20 dark:text-primary-light rounded-lg font-medium transition-colors">
            <User className="w-5 h-5 mr-3" />
            Mon Profil
          </button>
          <button className="w-full flex items-center px-4 py-3 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg font-medium transition-colors">
            <Building className="w-5 h-5 mr-3" />
            Entreprise
          </button>
          <button className="w-full flex items-center px-4 py-3 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg font-medium transition-colors">
            <Bell className="w-5 h-5 mr-3" />
            Notifications
          </button>
          <button className="w-full flex items-center px-4 py-3 text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 rounded-lg font-medium transition-colors">
            <Lock className="w-5 h-5 mr-3" />
            Sécurité
          </button>
        </div>

        {/* Content Area */}
        <div className="md:col-span-2 space-y-6">
          
          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">Informations Personnelles</h3>
              <p className="text-sm text-slate-500 mt-1">Modifiez les informations publiques de votre profil recruteur.</p>
            </div>
            <div className="p-6 space-y-4">
              <div className="flex items-center space-x-6">
                <div className="w-20 h-20 bg-slate-100 dark:bg-slate-800 rounded-full flex items-center justify-center text-2xl font-bold text-slate-400">
                  {profile?.name?.charAt(0).toUpperCase()}
                </div>
                <div>
                  <button className="px-4 py-2 bg-white dark:bg-slate-800 border border-slate-200 dark:border-slate-700 text-sm font-medium rounded-lg hover:bg-slate-50 dark:hover:bg-slate-700 transition-colors">
                    Changer d'avatar
                  </button>
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Nom complet</label>
                  <input type="text" defaultValue={profile?.name} className="w-full px-3 py-2 border border-slate-300 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-950 text-slate-900 dark:text-white" />
                </div>
                <div>
                  <label className="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1">Email professionnel</label>
                  <input type="email" defaultValue={profile?.email} disabled className="w-full px-3 py-2 border border-slate-200 dark:border-slate-800 rounded-lg bg-slate-50 dark:bg-slate-900 text-slate-500" />
                </div>
              </div>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 rounded-xl border border-slate-200 dark:border-slate-800 shadow-sm overflow-hidden">
            <div className="p-6 border-b border-slate-100 dark:border-slate-800">
              <h3 className="text-lg font-bold text-slate-900 dark:text-white">Préférences d'Affichage</h3>
              <p className="text-sm text-slate-500 mt-1">Personnalisez votre expérience sur Kaïro Pro.</p>
            </div>
            <div className="p-6">
              <div className="flex items-center justify-between">
                <div className="flex items-center">
                  <Moon className="w-5 h-5 text-slate-400 mr-3" />
                  <div>
                    <h4 className="font-medium text-slate-900 dark:text-white">Mode Sombre</h4>
                    <p className="text-sm text-slate-500">Basculez entre le thème clair et sombre.</p>
                  </div>
                </div>
                <button 
                  onClick={toggleDarkMode}
                  className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${isDarkMode ? 'bg-primary' : 'bg-slate-300 dark:bg-slate-700'}`}
                >
                  <span className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${isDarkMode ? 'translate-x-6' : 'translate-x-1'}`} />
                </button>
              </div>
            </div>
          </div>

        </div>
      </div>
    </div>
  );
}
