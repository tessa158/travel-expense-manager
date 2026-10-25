import { Navigate, Route, Routes } from 'react-router-dom';
import {
  BarChart3, Bell, FileText, Gauge, LayoutDashboard, ListChecks, Map, ReceiptText, ScrollText, Settings, Tags, Users, Wallet,
} from 'lucide-react';
import { useAuth } from './context/AuthContext';
import Layout from './components/Layout';
import ProtectedRoute from './components/ProtectedRoute';
import Loader from './components/Loader';
import Login from './pages/auth/Login';
import Register from './pages/auth/Register';
import AdminLogin from './pages/auth/AdminLogin';
import Dashboard from './pages/user/Dashboard';
import Trips from './pages/user/Trips';
import Expenses from './pages/user/Expenses';
import Budget from './pages/user/Budget';
import Groups from './pages/user/Groups';
import Reports from './pages/user/Reports';
import Notifications from './pages/user/Notifications';
import AdminDashboard from './pages/admin/AdminDashboard';
import AdminUsers from './pages/admin/AdminUsers';
import AdminCategories from './pages/admin/AdminCategories';
import AdminAudit from './pages/admin/AdminAudit';
import AdminSettings from './pages/admin/AdminSettings';

const userNav = [
  { to: '/dashboard', label: 'Dashboard', icon: LayoutDashboard },
  { to: '/trips', label: 'Trips', icon: Map },
  { to: '/expenses', label: 'Expenses', icon: ReceiptText },
  { to: '/budget', label: 'Budget', icon: Gauge },
  { to: '/groups', label: 'Group splits', icon: Users },
  { to: '/reports', label: 'Reports', icon: FileText },
  { to: '/notifications', label: 'Notifications', icon: Bell },
];
const adminNav = [
  { to: '/admin', label: 'Overview', icon: BarChart3, end: true },
  { to: '/admin/users', label: 'Users', icon: Users },
  { to: '/admin/categories', label: 'Categories', icon: Tags },
  { to: '/admin/audit', label: 'Audit logs', icon: ScrollText },
  { to: '/admin/settings', label: 'Settings', icon: Settings },
];

function Home() {
  const { user, loading } = useAuth();
  if (loading) return <Loader />;
  if (!user) return <Navigate to="/login" replace />;
  return <Navigate to={user.role === 'admin' ? '/admin' : '/dashboard'} replace />;
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<Home />} />
      <Route path="/login" element={<Login />} />
      <Route path="/register" element={<Register />} />
      <Route path="/admin/login" element={<AdminLogin />} />

      <Route element={<ProtectedRoute role="user"><Layout nav={userNav} subtitle="Manager" showBell /></ProtectedRoute>}>
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/trips" element={<Trips />} />
        <Route path="/expenses" element={<Expenses />} />
        <Route path="/budget" element={<Budget />} />
        <Route path="/groups" element={<Groups />} />
        <Route path="/reports" element={<Reports />} />
        <Route path="/notifications" element={<Notifications />} />
      </Route>

      <Route element={<ProtectedRoute role="admin"><Layout nav={adminNav} subtitle="Admin console" /></ProtectedRoute>}>
        <Route path="/admin" element={<AdminDashboard />} />
        <Route path="/admin/users" element={<AdminUsers />} />
        <Route path="/admin/categories" element={<AdminCategories />} />
        <Route path="/admin/audit" element={<AdminAudit />} />
        <Route path="/admin/settings" element={<AdminSettings />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
