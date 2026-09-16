import { HashRouter, Routes, Route, Navigate } from "react-router-dom";
import { DashboardLayout } from "./layouts/DashboardLayout";
import { Dashboard } from "./pages/Dashboard";
import { Login } from "./pages/auth/Login";
import { Register } from "./pages/auth/Register";
import { Search } from "./pages/Search";
import { Jobs } from "./pages/Jobs";
import { Pipeline } from "./pages/Pipeline";
import { Messages } from "./pages/Messages";
import { Settings } from "./pages/Settings";

import { useAuthStore } from "./store/useAuthStore";

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { user, isInitialized } = useAuthStore();
  
  if (!isInitialized) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  // If no user is logged in, redirect to login (onboarding)
  if (!user) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
};

function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        
        <Route path="/" element={<ProtectedRoute><DashboardLayout /></ProtectedRoute>}>
          <Route index element={<Dashboard />} />
          <Route path="search" element={<Search />} />
          <Route path="jobs" element={<Jobs />} />
          <Route path="pipeline" element={<Pipeline />} />
          <Route path="messages" element={<Messages />} />
          <Route path="settings" element={<Settings />} />
        </Route>
      </Routes>
    </HashRouter>
  );
}

export default App;
