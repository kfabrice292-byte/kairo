import { MessageSquare } from "lucide-react";

export function Messages() {
  return (
    <div className="h-full flex flex-col">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-slate-900 dark:text-white mb-2">Messagerie</h1>
        <p className="text-slate-500 dark:text-slate-400">Échangez directement avec vos candidats.</p>
      </div>
      
      <div className="flex-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl overflow-hidden flex shadow-sm">
        {/* Chat List */}
        <div className="w-1/3 border-r border-slate-200 dark:border-slate-800 flex flex-col">
          <div className="p-4 border-b border-slate-200 dark:border-slate-800 bg-slate-50 dark:bg-slate-950/50">
            <input 
              type="text" 
              placeholder="Rechercher une conversation..." 
              className="w-full px-3 py-2 bg-white dark:bg-slate-900 border border-slate-300 dark:border-slate-700 rounded-lg text-sm focus:outline-none focus:ring-1 focus:ring-primary"
            />
          </div>
          <div className="flex-1 flex flex-col items-center justify-center text-slate-400 p-8 text-center">
            <MessageSquare className="w-12 h-12 mb-3 opacity-50" />
            <p>Aucune conversation pour le moment.</p>
            <p className="text-sm mt-1">Contactez un candidat depuis son profil pour démarrer un échange.</p>
          </div>
        </div>

        {/* Chat Area */}
        <div className="flex-1 flex flex-col items-center justify-center bg-slate-50 dark:bg-slate-950/30 text-slate-400">
          <MessageSquare className="w-16 h-16 mb-4 opacity-20" />
          <h3 className="text-lg font-medium text-slate-600 dark:text-slate-300">Vos Messages</h3>
          <p className="text-sm text-slate-500 max-w-sm text-center mt-2">
            Sélectionnez une conversation sur la gauche pour commencer à discuter avec un candidat.
          </p>
        </div>
      </div>
    </div>
  );
}
