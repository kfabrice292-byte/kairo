import { Link, useLocation } from "react-router-dom";
import { LayoutDashboard, Users, Briefcase, MessageSquare, Settings } from "lucide-react";

export function Sidebar() {
  const location = useLocation();

  const links = [
    { name: "Tableau de bord", path: "/", icon: LayoutDashboard },
    { name: "Recherche de talents", path: "/search", icon: Users },
    { name: "Gestion des offres", path: "/jobs", icon: Briefcase },
    { name: "Candidatures", path: "/pipeline", icon: Users },
    { name: "Messages", path: "/messages", icon: MessageSquare },
    { name: "Paramètres", path: "/settings", icon: Settings },
  ];

  return (
    <aside className="w-64 bg-white/40 backdrop-blur-md border-r border-white/50 flex flex-col z-20 shadow-lg shadow-slate-200/20">
      <div className="h-20 flex items-center justify-center px-6 border-b border-white/50">
        <div className="inline-flex items-center gap-2">
          <span className="w-3 h-3 rounded-full bg-orange-500 shadow-sm shadow-orange-500/50"></span>
          <h1 className="text-2xl font-black text-slate-800 tracking-tight">Kaïro Pro</h1>
        </div>
      </div>
      <nav className="flex-1 overflow-y-auto py-6">
        <ul className="space-y-2 px-4">
          {links.map((link) => {
            const Icon = link.icon;
            const isActive = location.pathname === link.path;
            return (
              <li key={link.path}>
                <Link
                  to={link.path}
                  className={`flex items-center px-4 py-3 rounded-2xl text-sm font-bold transition-all ${
                    isActive
                      ? "bg-gradient-to-r from-orange-500 to-orange-600 text-white shadow-md shadow-orange-500/20 translate-x-1"
                      : "text-slate-500 hover:text-slate-800 hover:bg-white/60 hover:translate-x-1"
                  }`}
                >
                  <Icon className={`w-5 h-5 mr-3 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                  {link.name}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </aside>
  );
}
