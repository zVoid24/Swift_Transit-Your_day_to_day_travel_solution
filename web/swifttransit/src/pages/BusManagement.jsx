import React, { useState, useEffect } from 'react';
import axios from 'axios';

const BusManagement = () => {
  const [buses, setBuses] = useState([]);
  const [routes, setRoutes] = useState([]);
  const [formData, setFormData] = useState({
    registration_number: '',
    password: '',
    route_id_up: '',
    route_id_down: '',
  });
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  const fetchBuses = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get('http://localhost:8080/bus-owner/buses', {
        headers: { Authorization: `Bearer ${token}` },
      });
      setBuses(response.data || []);
    } catch (err) {
      console.error('Failed to fetch buses', err);
    }
  };

  const fetchRoutes = async () => {
    try {
      const token = localStorage.getItem('token');
      const response = await axios.get('http://localhost:8080/bus-owner/routes', {
        headers: { Authorization: `Bearer ${token}` },
      });
      setRoutes(response.data || []);
    } catch (err) {
      console.error('Failed to fetch routes', err);
    }
  };

  useEffect(() => {
    fetchBuses();
    fetchRoutes();
  }, []);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setSuccess('');
    try {
      const token = localStorage.getItem('token');
      await axios.post('http://localhost:8080/bus-owner/buses', {
        ...formData,
        route_id_up: parseInt(formData.route_id_up),
        route_id_down: parseInt(formData.route_id_down),
      }, {
        headers: { Authorization: `Bearer ${token}` },
      });
      setSuccess('Bus registered successfully');
      fetchBuses();
      setFormData({ registration_number: '', password: '', route_id_up: '', route_id_down: '' });
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to register bus');
    }
  };

  // Helper function to get route name by ID
  const getRouteName = (routeId) => {
    const route = routes.find(r => r.id === routeId);
    return route ? route.name : `Route ${routeId}`;
  };

  return (
    <div className="min-h-screen bg-gray-50 p-6">
      <div className="max-w-7xl mx-auto">
        <h1 className="text-3xl font-bold mb-8 text-gray-800">
          Bus Management
        </h1>
        
        {/* Registration Form */}
        <div className="bg-white p-8 rounded-lg shadow-sm border border-gray-200 mb-8">
          <h2 className="text-xl font-semibold mb-6 text-gray-800">
            Register New Bus
          </h2>
          
          {error && (
            <div className="mb-4 p-4 bg-red-50 border-l-4 border-red-500 rounded">
              <p className="text-red-700 font-medium">{error}</p>
            </div>
          )}
          
          {success && (
            <div className="mb-4 p-4 bg-green-50 border-l-4 border-green-500 rounded">
              <p className="text-green-700 font-medium">{success}</p>
            </div>
          )}
          
          <form onSubmit={handleSubmit} className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Registration Number
              </label>
              <input
                type="text"
                placeholder="e.g., DHK-1234"
                value={formData.registration_number}
                onChange={(e) => setFormData({ ...formData, registration_number: e.target.value })}
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none"
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Password
              </label>
              <input
                type="password"
                placeholder="Enter secure password"
                value={formData.password}
                onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none"
                required
              />
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Route Up ↑
              </label>
              <select
                value={formData.route_id_up}
                onChange={(e) => setFormData({ ...formData, route_id_up: e.target.value })}
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none bg-white cursor-pointer"
                required
              >
                <option value="">Select Route Up</option>
                {routes.map((route) => (
                  <option key={route.id} value={route.id}>
                    {route.name} (ID: {route.id})
                  </option>
                ))}
              </select>
            </div>
            
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                Route Down ↓
              </label>
              <select
                value={formData.route_id_down}
                onChange={(e) => setFormData({ ...formData, route_id_down: e.target.value })}
                className="w-full px-4 py-2.5 border border-gray-300 rounded-lg focus:border-blue-500 focus:ring-2 focus:ring-blue-200 transition-all outline-none bg-white cursor-pointer"
                required
              >
                <option value="">Select Route Down</option>
                {routes.map((route) => (
                  <option key={route.id} value={route.id}>
                    {route.name} (ID: {route.id})
                  </option>
                ))}
              </select>
            </div>
            
            <button
              type="submit"
              className="md:col-span-2 bg-blue-600 text-white font-semibold py-3 px-6 rounded-lg hover:bg-blue-700 transition-colors shadow-sm"
            >
              Register Bus
            </button>
          </form>
        </div>

        {/* Available Routes */}
        <div className="bg-white p-8 rounded-lg shadow-sm border border-gray-200 mb-8">
          <h2 className="text-xl font-semibold mb-6 text-gray-800">
            Available Routes
          </h2>
          
          {routes.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <svg className="w-16 h-16 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
              </svg>
              <p className="text-lg">No routes available</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {routes.map((route) => (
                <div
                  key={route.id}
                  className="bg-gray-50 p-6 rounded-lg border border-gray-200 hover:border-gray-300 hover:shadow-sm transition-all"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h3 className="font-bold text-lg text-gray-900 mb-1">{route.name}</h3>
                      <span className="inline-block px-2.5 py-1 bg-blue-100 text-blue-700 text-xs font-medium rounded">
                        ID: {route.id}
                      </span>
                    </div>
                    <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center">
                      <svg className="w-5 h-5 text-blue-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7" />
                      </svg>
                    </div>
                  </div>
                  
                  <div className="mt-4">
                    <div className="flex items-center mb-2">
                      <svg className="w-4 h-4 text-gray-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                      </svg>
                      <strong className="text-sm text-gray-700">Stops:</strong>
                    </div>
                    <div className="max-h-40 overflow-y-auto custom-scrollbar bg-white rounded-lg p-3 border border-gray-200">
                      {route.stops && route.stops.length > 0 ? (
                        <ul className="space-y-2">
                          {route.stops.map((stop, index) => (
                            <li key={stop.id} className="flex items-start text-sm">
                              <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-blue-100 text-blue-700 font-medium text-xs mr-2 flex-shrink-0">
                                {index + 1}
                              </span>
                              <span className="text-gray-700 pt-0.5">{stop.name}</span>
                            </li>
                          ))}
                        </ul>
                      ) : (
                        <p className="text-sm text-gray-500 italic">No stops defined</p>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Registered Buses */}
        <div className="bg-white p-8 rounded-lg shadow-sm border border-gray-200">
          <h2 className="text-xl font-semibold mb-6 text-gray-800">
            Registered Buses
          </h2>
          
          {buses.length === 0 ? (
            <div className="text-center py-12 text-gray-500">
              <svg className="w-16 h-16 mx-auto mb-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
              </svg>
              <p className="text-lg">No buses registered yet</p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
              {buses.map((bus) => (
                <div
                  key={bus.id}
                  className="bg-gray-50 p-6 rounded-lg border border-gray-200 hover:border-gray-300 hover:shadow-sm transition-all"
                >
                  <div className="flex items-start justify-between mb-4">
                    <div>
                      <h3 className="font-bold text-xl text-gray-900 mb-2">{bus.registration_number}</h3>
                      <span className="inline-block px-2.5 py-1 bg-gray-200 text-gray-700 text-xs font-medium rounded">
                        Bus ID: {bus.id}
                      </span>
                    </div>
                    <div className="w-10 h-10 bg-gray-200 rounded-lg flex items-center justify-center">
                      <svg className="w-5 h-5 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7v8a2 2 0 002 2h6M8 7V5a2 2 0 012-2h4.586a1 1 0 01.707.293l4.414 4.414a1 1 0 01.293.707V15a2 2 0 01-2 2h-2M8 7H6a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2v-2" />
                      </svg>
                    </div>
                  </div>
                  
                  <div className="space-y-3">
                    <div className="bg-white rounded-lg p-3 border border-gray-200">
                      <div className="flex items-center mb-1">
                        <svg className="w-4 h-4 text-green-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 10l7-7m0 0l7 7m-7-7v18" />
                        </svg>
                        <span className="text-xs font-medium text-gray-600 uppercase">Route Up</span>
                      </div>
                      <p className="text-sm font-semibold text-gray-900 ml-6">{getRouteName(bus.route_id_up)}</p>
                    </div>
                    
                    <div className="bg-white rounded-lg p-3 border border-gray-200">
                      <div className="flex items-center mb-1">
                        <svg className="w-4 h-4 text-red-600 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 14l-7 7m0 0l-7-7m7 7V3" />
                        </svg>
                        <span className="text-xs font-medium text-gray-600 uppercase">Route Down</span>
                      </div>
                      <p className="text-sm font-semibold text-gray-900 ml-6">{getRouteName(bus.route_id_down)}</p>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

export default BusManagement;
