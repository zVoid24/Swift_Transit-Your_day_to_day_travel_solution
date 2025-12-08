import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FiEdit2, FiTrash2, FiPlus } from 'react-icons/fi';

const BusOwners = () => {
  const [owners, setOwners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [showModal, setShowModal] = useState(false);
  const [editingOwner, setEditingOwner] = useState(null);
  const [formData, setFormData] = useState({ username: '', password: '' });

  useEffect(() => {
    fetchOwners();
  }, [page]);

  const fetchOwners = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`http://localhost:8080/admin/bus-owners?page=${page}&page_size=20`);
      setOwners(response.data.bus_owners || []);
      setTotalPages(response.data.total_pages || 1);
    } catch (error) {
      console.error('Failed to fetch bus owners:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = () => {
    setEditingOwner(null);
    setFormData({ username: '', password: '' });
    setShowModal(true);
  };

  const handleEdit = (owner) => {
    setEditingOwner(owner);
    setFormData({ username: owner.username, password: '' });
    setShowModal(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      if (editingOwner) {
        await axios.put(`http://localhost:8080/admin/bus-owners/${editingOwner.id}`, formData);
      } else {
        await axios.post('http://localhost:8080/admin/bus-owners', formData);
      }
      setShowModal(false);
      fetchOwners();
    } catch (error) {
      console.error('Failed to save bus owner:', error);
      alert('Failed to save bus owner');
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this bus owner?')) return;
    try {
      await axios.delete(`http://localhost:8080/admin/bus-owners/${id}`);
      fetchOwners();
    } catch (error) {
      console.error('Failed to delete bus owner:', error);
      alert('Failed to delete bus owner');
    }
  };

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-3xl font-bold text-gray-900">Bus Owners</h1>
        <button
          onClick={handleCreate}
          className="flex items-center px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
        >
          <FiPlus className="w-4 h-4 mr-2" />
          Add Bus Owner
        </button>
      </div>

      {loading ? (
        <div className="text-center py-12"><p className="text-gray-600">Loading...</p></div>
      ) : (
        <>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Username</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Created At</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Actions</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {owners.map((owner) => (
                  <tr key={owner.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{owner.id}</td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{owner.username}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{new Date(owner.created_at).toLocaleDateString()}</td>
                    <td className="px-6 py-4 text-sm">
                      <button onClick={() => handleEdit(owner)} className="text-blue-600 hover:text-blue-800 mr-3">
                        <FiEdit2 className="w-4 h-4" />
                      </button>
                      <button onClick={() => handleDelete(owner.id)} className="text-red-600 hover:text-red-800">
                        <FiTrash2 className="w-4 h-4" />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          <div className="flex items-center justify-between mt-6">
            <button
              onClick={() => setPage(p => Math.max(1, p - 1))}
              disabled={page === 1}
              className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
            >
              Previous
            </button>
            <span className="text-sm text-gray-600">Page {page} of {totalPages}</span>
            <button
              onClick={() => setPage(p => Math.min(totalPages, p + 1))}
              disabled={page === totalPages}
              className="px-4 py-2 bg-white border border-gray-300 rounded-lg text-sm font-medium text-gray-700 hover:bg-gray-50 disabled:opacity-50"
            >
              Next
            </button>
          </div>
        </>
      )}

      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
          <div className="bg-white rounded-lg p-6 max-w-md w-full">
            <h2 className="text-xl font-bold text-gray-900 mb-4">
              {editingOwner ? 'Edit Bus Owner' : 'Add Bus Owner'}
            </h2>
            <form onSubmit={handleSubmit} className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Username</label>
                <input
                  type="text"
                  value={formData.username}
                  onChange={(e) => setFormData({ ...formData, username: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  required
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">
                  Password {editingOwner && '(leave blank to keep current)'}
                </label>
                <input
                  type="password"
                  value={formData.password}
                  onChange={(e) => setFormData({ ...formData, password: e.target.value })}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500"
                  required={!editingOwner}
                />
              </div>
              <div className="flex gap-3 mt-6">
                <button type="submit" className="flex-1 bg-blue-600 text-white font-semibold py-2 rounded-lg hover:bg-blue-700">
                  {editingOwner ? 'Update' : 'Create'}
                </button>
                <button type="button" onClick={() => setShowModal(false)} className="flex-1 bg-gray-200 text-gray-700 font-semibold py-2 rounded-lg hover:bg-gray-300">
                  Cancel
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

export default BusOwners;
