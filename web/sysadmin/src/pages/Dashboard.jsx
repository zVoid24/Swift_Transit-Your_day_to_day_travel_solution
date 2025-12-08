import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiUsers, FiBriefcase, FiTruck, FiMap, FiCreditCard, FiDollarSign } from 'react-icons/fi';

const Dashboard = () => {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetchStats();
  }, []);

  const fetchStats = async () => {
    try {
      const response = await axios.get('http://localhost:8080/admin/dashboard/stats');
      setStats(response.data);
    } catch (error) {
      console.error('Failed to fetch stats:', error);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return <div className="text-center py-12"><p className="text-gray-600">Loading...</p></div>;
  }

  const statCards = [
    { label: 'Total Users', value: stats?.total_users || 0, icon: FiUsers, color: 'blue' },
    { label: 'Total Bus Owners', value: stats?.total_bus_owners || 0, icon: FiBriefcase, color: 'green' },
    { label: 'Total Buses', value: stats?.total_buses || 0, icon: FiTruck, color: 'purple' },
    { label: 'Total Routes', value: stats?.total_routes || 0, icon: FiMap, color: 'orange' },
    { label: 'Total Tickets', value: stats?.total_tickets || 0, icon: FiCreditCard, color: 'pink' },
    { label: 'Total Revenue', value: `৳${stats?.total_revenue?.toFixed(2) || 0}`, icon: FiDollarSign, color: 'emerald' },
    { label: "Today's Tickets", value: stats?.today_tickets || 0, icon: FiCreditCard, color: 'indigo' },
    { label: "Today's Revenue", value: `৳${stats?.today_revenue?.toFixed(2) || 0}`, icon: FiDollarSign, color: 'teal' },
  ];

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((stat, index) => {
          const Icon = stat.icon;
          return (
            <div key={index} className="bg-white p-6 rounded-lg shadow-sm border border-gray-200 hover:shadow-md transition-shadow">
              <div className="flex items-center justify-between mb-2">
                <h3 className="text-sm font-medium text-gray-600">{stat.label}</h3>
                <Icon className={`w-5 h-5 text-${stat.color}-600`} />
              </div>
              <p className="text-3xl font-bold text-gray-900">{stat.value}</p>
            </div>
          );
        })}
      </div>

      <div className="bg-white p-6 rounded-lg shadow-sm border border-gray-200">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">System Overview</h2>
        <p className="text-gray-600">
          Welcome to the Swift Transit Admin Panel. Use the sidebar to navigate through different sections and manage the system.
        </p>
      </div>
    </div>
  );
};

export default Dashboard;
