import React from 'react';
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import Users from './pages/Users';
import BusOwners from './pages/BusOwners';
import Buses from './pages/Buses';
import Routes_Page from './pages/Routes';
import Tickets from './pages/Tickets';
import Transactions from './pages/Transactions';
import Layout from './components/Layout';

const PrivateRoute = ({ children }) => {
  const { token, loading } = useAuth();
  
  if (loading) {
    return <div className="min-h-screen flex items-center justify-center">
      <div className="text-gray-600">Loading...</div>
    </div>;
  }
  
  return token ? children : <Navigate to="/login" />;
};

function App() {
  return (
    <AuthProvider>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route path="/" element={<PrivateRoute><Layout /></PrivateRoute>}>
            <Route index element={<Navigate to="/dashboard" />} />
            <Route path="dashboard" element={<Dashboard />} />
            <Route path="users" element={<Users />} />
            <Route path="bus-owners" element={<BusOwners />} />
            <Route path="buses" element={<Buses />} />
            <Route path="routes" element={<Routes_Page />} />
            <Route path="tickets" element={<Tickets />} />
            <Route path="transactions" element={<Transactions />} />
          </Route>
        </Routes>
      </BrowserRouter>
    </AuthProvider>
  );
}

export default App;
