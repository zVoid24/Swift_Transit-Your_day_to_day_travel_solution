import React, { useState, useEffect } from 'react';
import axios from 'axios';

const Tickets = () => {
  const [tickets, setTickets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);

  useEffect(() => {
    fetchTickets();
  }, [page]);

  const fetchTickets = async () => {
    try {
      setLoading(true);
      const response = await axios.get(`http://localhost:8080/admin/tickets?page=${page}&page_size=20`);
      setTickets(response.data.tickets || []);
      setTotalPages(response.data.total_pages || 1);
    } catch (error) {
      console.error('Failed to fetch tickets:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-900 mb-6">Tickets</h1>

      {loading ? (
        <div className="text-center py-12"><p className="text-gray-600">Loading...</p></div>
      ) : (
        <>
          <div className="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">User ID</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Bus</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">From</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">To</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Fare</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Status</th>
                  <th className="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">Date</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {tickets.map((ticket) => (
                  <tr key={ticket.id} className="hover:bg-gray-50">
                    <td className="px-6 py-4 text-sm text-gray-900">{ticket.id}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{ticket.user_id}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{ticket.registration_number}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{ticket.start_destination}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">{ticket.end_destination}</td>
                    <td className="px-6 py-4 text-sm font-semibold text-green-600">৳{ticket.fare}</td>
                    <td className="px-6 py-4 text-sm">
                      <span className={`px-2 py-1 text-xs font-medium rounded-full ${
                        ticket.payment_status === 'paid' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-700'
                      }`}>
                        {ticket.payment_status}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-600">{new Date(ticket.created_at).toLocaleDateString()}</td>
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

export default Tickets;
