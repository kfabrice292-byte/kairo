import { HashRouter, Routes, Route } from "react-router-dom";
import { DashboardLayout } from "./layouts/DashboardLayout";
import { Dashboard } from "./pages/Dashboard";
import { Login } from "./pages/auth/Login";
import { Register } from "./pages/auth/Register";
import { Search } from "./pages/Search";
import { Jobs } from "./pages/Jobs";
import { Pipeline } from "./pages/Pipeline";
import { Messages } from "./pages/Messages";
import { Settings } from "./pages/Settings";

function App() {
  return (
    <HashRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/register" element={<Register />} />
        
        <Route path="/" element={<DashboardLayout />}>
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
