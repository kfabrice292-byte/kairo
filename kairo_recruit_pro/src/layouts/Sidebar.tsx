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
    <aside className="w-64 bg-white dark:bg-slate-950 border-r border-slate-200 dark:border-slate-800 flex flex-col">
      <div className="h-16 flex items-center px-6 border-b border-slate-200 dark:border-slate-800">
        <h1 className="text-xl font-bold text-primary">Kaïro Pro</h1>
      </div>
      <nav className="flex-1 overflow-y-auto py-4">
        <ul className="space-y-1 px-3">
          {links.map((link) => {
            const Icon = link.icon;
            const isActive = location.pathname === link.path;
            return (
              <li key={link.path}>
                <Link
                  to={link.path}
                  className={`flex items-center px-3 py-2.5 rounded-lg text-sm font-medium transition-colors ${
                    isActive
                      ? "bg-primary/10 text-primary"
                      : "text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-900"
                  }`}
                >
                  <Icon className="w-5 h-5 mr-3" />
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
