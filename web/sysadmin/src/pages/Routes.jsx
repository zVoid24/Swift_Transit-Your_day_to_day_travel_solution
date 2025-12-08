import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiTrash2 } from 'react-icons/fi';

const Routes = () => {
  const [routes, setRoutes] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    fetchRoutes();
  }, [page]);

  const fetchRoutes = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`http://localhost:8080/admin/routes?page=${page}&page_size=20`);
      setRoutes(response.data.routes || []);
      setTotalPages(response.data.total_pages || 1);
    } catch (error) {
      console.error('Failed to fetch routes:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this route?')) return;
    try {
      await axios.delete(`http://localhost:8080/admin/routes/${id}`);
      fetchRoutes();
    } catch (error) {
      console.error('Failed to delete route:', error);
      alert('Failed to delete route');
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Routes</h1>

      {loading ? (
        <div className="text-center py-12"><p className="text-gray-600">Loading...</p></div>
      ) : (
        <>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Name</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {routes.map((route) => (
                  <tr key={route.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{route.id}</td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{route.name}</td>
                    <td className="px-6 py-4 text-sm">
                      <button onClick={() => handleDelete(route.id)} className="text-red-600 hover:text-red-800">
                        <FiTrash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex items-center justify-between mt-6">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page === 1} className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50">Previous</button>
            <span className="text-sm text-gray-600">Page {page} of {totalPages}</span>
            <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page === totalPages} className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50">Next</button>
          </div>
        </>
      )}
    </div>
  );
};

export default Routes;
