import React from 'react';
import { Outlet, Link, useNavigate, useLocation } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { FiUsers, FiHome, FiLogOut, FiBriefcase, FiTruck, FiMap, FiCreditCard, FiDollarSign } from 'react-icons/fi';

const Layout = () => {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  const menuItems = [
    { path: '/dashboard', icon: FiHome, label: 'Dashboard' },
    { path: '/users', icon: FiUsers, label: 'Users' },
    { path: '/bus-owners', icon: FiBriefcase, label: 'Bus Owners' },
    { path: '/buses', icon: FiTruck, label: 'Buses' },
    { path: '/routes', icon: FiMap, label: 'Routes' },
    { path: '/tickets', icon: FiCreditCard, label: 'Tickets' },
    { path: '/transactions', icon: FiDollarSign, label: 'Transactions' },
  ];

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Sidebar */}
      <div className="fixed inset-y-0 left-0 w-64 bg-white shadow-lg">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-2xl font-bold text-gray-900">Swift Transit</h1>
          <p className="text-sm text-gray-600 mt-1">Admin Panel</p>
        </div>

        <nav className="p-4">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center px-4 py-3 mb-2 rounded-lg transition-colors ${
                  isActive
                    ? 'bg-blue-50 text-blue-600 font-medium'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <Icon className="w-5 h-5 mr-3" />
                {item.label}
              </Link>
            );
          })}
        </nav>

        <div className="absolute bottom-0 left-0 right-0 p-4 border-t border-gray-200">
          <div className="mb-3 px-4">
            <p className="text-sm font-medium text-gray-900">{admin?.username || 'Admin'}</p>
            <p className="text-xs text-gray-600">System Administrator</p>
          </div>
          <button
            onClick={handleLogout}
            className="flex items-center w-full px-4 py-3 text-gray-700 hover:bg-red-50 hover:text-red-600 rounded-lg transition-colors"
          >
            <FiLogOut className="w-5 h-5 mr-3" />
            Logout
          </button>
        </div>
      </div>

      {/* Main Content */}
      <div className="ml-64">
        <div className="p-8">
          <Outlet />
        </div>
      </div>
    </div>
  );
};

export default Layout;
