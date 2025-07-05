import React, { useState } from 'react';
import {
    BarChart3,
    Database,
    Shield,
    User,
    LogOut,
    Plus,
    Edit,
    Trash2,
    RefreshCw,
    CheckCircle,
    AlertTriangle,
    XCircle,
    Clock
} from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import api from '../utils/api';

const MainApp = () => {
    const { user, logout } = useAuth();
    const queryClient = useQueryClient();
    const [activeTab, setActiveTab] = useState(0);
    const [anchorEl, setAnchorEl] = useState(null);
    const [openDialog, setOpenDialog] = useState(false);
    const [editingItem, setEditingItem] = useState(null);
    const [formData, setFormData] = useState({ name: '', description: '' });

    // Using centralized API configuration from utils/api.js

    // Fetch data
    const { data, isLoading, error, refetch } = useQuery(
        ['items'],
        async () => {
            const response = await api.get('/api/data?page=1&limit=50');
            return response.data;
        },
        {
            retry: 1,
            onError: (error) => {
                console.error('Failed to fetch data:', error);
            }
        }
    );

    // Fetch admin data
    const { data: adminData, isLoading: adminLoading, error: adminError } = useQuery(
        ['admin-data'],
        async () => {
            const response = await api.get('/api/admin?page=1&limit=50');
            return response.data;
        },
        {
            retry: 1,
            onError: (error) => {
                console.error('Failed to fetch admin data:', error);
            },
            enabled: user?.roles?.includes('admin')
        }
    );

    // Create mutation
    const createMutation = useMutation(
        async (newItem) => {
            const response = await api.post('/api/data', newItem);
            return response.data;
        },
        {
            onSuccess: () => {
                queryClient.invalidateQueries(['items']);
                setOpenDialog(false);
                setFormData({ name: '', description: '' });
            }
        }
    );

    // Update mutation
    const updateMutation = useMutation(
        async (updatedItem) => {
            const response = await api.put(`/api/data/${updatedItem.id}`, updatedItem);
            return response.data;
        },
        {
            onSuccess: () => {
                queryClient.invalidateQueries(['items']);
                setOpenDialog(false);
                setEditingItem(null);
                setFormData({ name: '', description: '' });
            }
        }
    );

    // Delete mutation
    const deleteMutation = useMutation(
        async (id) => {
            await api.delete(`/api/data/${id}`);
        },
        {
            onSuccess: () => {
                queryClient.invalidateQueries(['items']);
            }
        }
    );

    const handleMenuOpen = (event) => {
        setAnchorEl(event.currentTarget);
    };

    const handleMenuClose = () => {
        setAnchorEl(null);
    };

    const handleLogout = () => {
        handleMenuClose();
        logout();
    };

    const handleOpenDialog = (item = null) => {
        if (item) {
            setEditingItem(item);
            setFormData({ name: item.name, description: item.description });
        } else {
            setEditingItem(null);
            setFormData({ name: '', description: '' });
        }
        setOpenDialog(true);
    };

    const handleCloseDialog = () => {
        setOpenDialog(false);
        setEditingItem(null);
        setFormData({ name: '', description: '' });
    };

    const handleSubmit = (e) => {
        e.preventDefault();
        if (editingItem) {
            updateMutation.mutate({ ...editingItem, ...formData });
        } else {
            createMutation.mutate(formData);
        }
    };

    const handleDelete = (id) => {
        if (window.confirm('Are you sure you want to delete this item?')) {
            deleteMutation.mutate(id);
        }
    };

    const getSeverityColor = (severity) => {
        switch (severity) {
            case 'error': return 'text-red-500';
            case 'warning': return 'text-yellow-500';
            case 'info': return 'text-blue-500';
            default: return 'text-gray-500';
        }
    };

    const getSeverityIcon = (severity) => {
        switch (severity) {
            case 'error': return <XCircle className="h-5 w-5 text-red-500" />;
            case 'warning': return <AlertTriangle className="h-5 w-5 text-yellow-500" />;
            case 'info': return <CheckCircle className="h-5 w-5 text-blue-500" />;
            default: return <Clock className="h-5 w-5 text-gray-500" />;
        }
    };

    // Mock system metrics
    const systemMetrics = {
        totalUsers: 15,
        activeUsers: 8,
        totalItems: data?.items?.length || 0,
        systemUptime: '99.9%',
        avgResponseTime: '245ms',
        errorRate: '0.1%'
    };

    // Mock security events
    const securityEvents = [
        { id: 1, event: 'Failed login attempt', user: 'unknown', ip: '192.168.1.100', time: '2 minutes ago', severity: 'warning' },
        { id: 2, event: 'Policy violation', user: 'user1', ip: '192.168.1.101', time: '5 minutes ago', severity: 'error' },
        { id: 3, event: 'Successful login', user: 'admin', ip: '192.168.1.102', time: '10 minutes ago', severity: 'info' },
        { id: 4, event: 'Data access', user: 'user2', ip: '192.168.1.103', time: '15 minutes ago', severity: 'info' }
    ];

    const TabPanel = ({ children, value, index }) => (
        <div hidden={value !== index} className="pt-5">
            {value === index && children}
        </div>
    );

    return (
        <div className="flex flex-col min-h-screen bg-gray-900">
            {/* Header */}
            <header className="bg-gray-800 border-b border-gray-700">
                <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                    <div className="flex justify-between items-center h-16">
                        <div className="flex items-center">
                            <Shield className="h-8 w-8 text-primary-500 mr-3" />
                            <h1 className="text-xl font-semibold text-white">
                                Zero Trust Application
                            </h1>
                        </div>

                        <div className="flex items-center space-x-4">
                            <div className="flex space-x-2">
                                {user?.roles?.map(role => (
                                    <span
                                        key={role}
                                        className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-primary-100 text-primary-800"
                                    >
                                        {role}
                                    </span>
                                ))}
                            </div>
                            <div className="relative">
                                <button
                                    onClick={handleMenuOpen}
                                    className="flex items-center space-x-2 text-gray-300 hover:text-white focus:outline-none"
                                >
                                    <div className="w-8 h-8 bg-primary-600 rounded-full flex items-center justify-center">
                                        <User className="h-5 w-5 text-white" />
                                    </div>
                                </button>

                                {anchorEl && (
                                    <div className="absolute right-0 mt-2 w-48 bg-gray-800 rounded-md shadow-lg py-1 z-50">
                                        <div className="px-4 py-2 text-sm text-gray-400">
                                            {user?.username || 'User'}
                                        </div>
                                        <div className="border-t border-gray-700"></div>
                                        <button
                                            onClick={handleLogout}
                                            className="flex items-center w-full px-4 py-2 text-sm text-gray-300 hover:bg-gray-700"
                                        >
                                            <LogOut className="h-4 w-4 mr-2" />
                                            Logout
                                        </button>
                                    </div>
                                )}
                            </div>
                        </div>
                    </div>
                </div>
            </header>

            {/* Main Content */}
            <main className="flex-1 p-6">
                {/* Tabs */}
                <div className="border-b border-gray-700 mb-6">
                    <nav className="-mb-px flex space-x-8">
                        <button
                            onClick={() => setActiveTab(0)}
                            className={`py-2 px-1 border-b-2 font-medium text-sm ${activeTab === 0
                                ? 'border-primary-500 text-primary-400'
                                : 'border-transparent text-gray-400 hover:text-gray-300 hover:border-gray-300'
                                }`}
                        >
                            <BarChart3 className="h-5 w-5 inline mr-2" />
                            Dashboard
                        </button>
                        <button
                            onClick={() => setActiveTab(1)}
                            className={`py-2 px-1 border-b-2 font-medium text-sm ${activeTab === 1
                                ? 'border-primary-500 text-primary-400'
                                : 'border-transparent text-gray-400 hover:text-gray-300 hover:border-gray-300'
                                }`}
                        >
                            <Database className="h-5 w-5 inline mr-2" />
                            Data Management
                        </button>
                        {user?.roles?.includes('admin') && (
                            <button
                                onClick={() => setActiveTab(2)}
                                className={`py-2 px-1 border-b-2 font-medium text-sm ${activeTab === 2
                                    ? 'border-primary-500 text-primary-400'
                                    : 'border-transparent text-gray-400 hover:text-gray-300 hover:border-gray-300'
                                    }`}
                            >
                                <Shield className="h-5 w-5 inline mr-2" />
                                Admin Panel
                            </button>
                        )}
                    </nav>
                </div>

                {/* Dashboard Tab */}
                <TabPanel value={activeTab} index={0}>
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                        {/* System Overview */}
                        <div className="lg:col-span-2">
                            <div className="bg-gray-800 rounded-lg shadow p-6">
                                <h3 className="text-lg font-medium text-white mb-4">
                                    System Overview
                                </h3>
                                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                                    <div className="text-center p-4">
                                        <div className="text-3xl font-bold text-primary-500">
                                            {systemMetrics.totalUsers}
                                        </div>
                                        <div className="text-sm text-gray-400">
                                            Total Users
                                        </div>
                                    </div>
                                    <div className="text-center p-4">
                                        <div className="text-3xl font-bold text-green-500">
                                            {systemMetrics.activeUsers}
                                        </div>
                                        <div className="text-sm text-gray-400">
                                            Active Users
                                        </div>
                                    </div>
                                    <div className="text-center p-4">
                                        <div className="text-3xl font-bold text-blue-500">
                                            {systemMetrics.totalItems}
                                        </div>
                                        <div className="text-sm text-gray-400">
                                            Total Items
                                        </div>
                                    </div>
                                    <div className="text-center p-4">
                                        <div className="text-3xl font-bold text-green-500">
                                            {systemMetrics.systemUptime}
                                        </div>
                                        <div className="text-sm text-gray-400">
                                            Uptime
                                        </div>
                                    </div>
                                </div>
                            </div>
                        </div>

                        {/* Security Events */}
                        <div className="lg:col-span-1">
                            <div className="bg-gray-800 rounded-lg shadow p-6">
                                <h3 className="text-lg font-medium text-white mb-4">
                                    Recent Security Events
                                </h3>
                                <div className="space-y-3">
                                    {securityEvents.map((event) => (
                                        <div key={event.id} className="flex items-start space-x-3">
                                            <div className="flex-shrink-0 mt-1">
                                                {getSeverityIcon(event.severity)}
                                            </div>
                                            <div className="flex-1 min-w-0">
                                                <p className="text-sm font-medium text-white">
                                                    {event.event}
                                                </p>
                                                <p className="text-xs text-gray-400">
                                                    {event.user} • {event.time}
                                                </p>
                                            </div>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        </div>
                    </div>
                </TabPanel>

                {/* Data Management Tab */}
                <TabPanel value={activeTab} index={1}>
                    <div className="flex justify-between items-center mb-6">
                        <h2 className="text-2xl font-bold text-white">
                            Data Management
                        </h2>
                        <button
                            onClick={() => handleOpenDialog()}
                            className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500"
                        >
                            <Plus className="h-4 w-4 mr-2" />
                            Add New Item
                        </button>
                    </div>

                    {error ? (
                        <div className="rounded-md bg-red-900/50 border border-red-700 p-4 mb-4">
                            <div className="flex">
                                <div className="ml-3">
                                    <h3 className="text-sm font-medium text-red-200">
                                        Failed to load data. Please check your authentication and try again.
                                    </h3>
                                </div>
                            </div>
                        </div>
                    ) : (
                        <div className="bg-gray-800 rounded-lg shadow overflow-hidden">
                            {isLoading ? (
                                <div className="flex justify-center p-8">
                                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
                                </div>
                            ) : (
                                <div className="overflow-x-auto">
                                    <table className="min-w-full divide-y divide-gray-700">
                                        <thead className="bg-gray-700">
                                            <tr>
                                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                    Name
                                                </th>
                                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                    Description
                                                </th>
                                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                    Owner
                                                </th>
                                                <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                    Created
                                                </th>
                                                <th className="px-6 py-3 text-right text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                    Actions
                                                </th>
                                            </tr>
                                        </thead>
                                        <tbody className="bg-gray-800 divide-y divide-gray-700">
                                            {data?.items?.map((item) => (
                                                <tr key={item.id} className="hover:bg-gray-700">
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-white">
                                                        {item.name}
                                                    </td>
                                                    <td className="px-6 py-4 text-sm text-gray-300">
                                                        {item.description}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                                        {item.owner}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                                        {new Date(item.createdAt).toLocaleDateString()}
                                                    </td>
                                                    <td className="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                                                        <button
                                                            onClick={() => handleOpenDialog(item)}
                                                            className="text-primary-400 hover:text-primary-300 mr-3"
                                                        >
                                                            <Edit className="h-4 w-4" />
                                                        </button>
                                                        <button
                                                            onClick={() => handleDelete(item.id)}
                                                            className="text-red-400 hover:text-red-300"
                                                        >
                                                            <Trash2 className="h-4 w-4" />
                                                        </button>
                                                    </td>
                                                </tr>
                                            ))}
                                        </tbody>
                                    </table>
                                </div>
                            )}
                        </div>
                    )}
                </TabPanel>

                {/* Admin Panel Tab */}
                {user?.roles?.includes('admin') && (
                    <TabPanel value={activeTab} index={2}>
                        <div className="flex justify-between items-center mb-6">
                            <h2 className="text-2xl font-bold text-white">
                                Admin Panel
                            </h2>
                            <button
                                onClick={() => refetch()}
                                className="inline-flex items-center px-4 py-2 border border-gray-600 text-sm font-medium rounded-md text-gray-300 bg-gray-700 hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                            >
                                <RefreshCw className="h-4 w-4 mr-2" />
                                Refresh
                            </button>
                        </div>

                        <div className="rounded-md bg-yellow-900/50 border border-yellow-700 p-4 mb-6">
                            <div className="flex">
                                <div className="ml-3">
                                    <h3 className="text-sm font-medium text-yellow-200">
                                        This panel is restricted to administrators only. All actions are logged and audited.
                                    </h3>
                                </div>
                            </div>
                        </div>

                        {adminError ? (
                            <div className="rounded-md bg-red-900/50 border border-red-700 p-4">
                                <div className="flex">
                                    <div className="ml-3">
                                        <h3 className="text-sm font-medium text-red-200">
                                            Failed to load admin data.
                                        </h3>
                                    </div>
                                </div>
                            </div>
                        ) : (
                            <div className="bg-gray-800 rounded-lg shadow overflow-hidden">
                                {adminLoading ? (
                                    <div className="flex justify-center p-8">
                                        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-500"></div>
                                    </div>
                                ) : (
                                    <div className="overflow-x-auto">
                                        <table className="min-w-full divide-y divide-gray-700">
                                            <thead className="bg-gray-700">
                                                <tr>
                                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                        Name
                                                    </th>
                                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                        Description
                                                    </th>
                                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                        Owner
                                                    </th>
                                                    <th className="px-6 py-3 text-left text-xs font-medium text-gray-300 uppercase tracking-wider">
                                                        Created
                                                    </th>
                                                </tr>
                                            </thead>
                                            <tbody className="bg-gray-800 divide-y divide-gray-700">
                                                {adminData?.items?.map((item) => (
                                                    <tr key={item.id} className="hover:bg-gray-700">
                                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-white">
                                                            {item.name}
                                                        </td>
                                                        <td className="px-6 py-4 text-sm text-gray-300">
                                                            {item.description}
                                                        </td>
                                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                                            {item.owner}
                                                        </td>
                                                        <td className="px-6 py-4 whitespace-nowrap text-sm text-gray-300">
                                                            {new Date(item.createdAt).toLocaleDateString()}
                                                        </td>
                                                    </tr>
                                                ))}
                                            </tbody>
                                        </table>
                                    </div>
                                )}
                            </div>
                        )}
                    </TabPanel>
                )}
            </main>

            {/* Add/Edit Dialog */}
            {openDialog && (
                <div className="fixed inset-0 bg-gray-900 bg-opacity-50 flex items-center justify-center p-4 z-50">
                    <div className="bg-gray-800 rounded-lg shadow-xl max-w-md w-full">
                        <div className="px-6 py-4 border-b border-gray-700">
                            <h3 className="text-lg font-medium text-white">
                                {editingItem ? 'Edit Item' : 'Add New Item'}
                            </h3>
                        </div>
                        <form onSubmit={handleSubmit} className="px-6 py-4">
                            <div className="space-y-4">
                                <div>
                                    <label htmlFor="name" className="block text-sm font-medium text-gray-300">
                                        Name
                                    </label>
                                    <input
                                        type="text"
                                        id="name"
                                        value={formData.name}
                                        onChange={(e) => setFormData({ ...formData, name: e.target.value })}
                                        className="mt-1 block w-full px-3 py-2 border border-gray-600 rounded-md shadow-sm bg-gray-700 text-white placeholder-gray-400 focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                                        required
                                    />
                                </div>
                                <div>
                                    <label htmlFor="description" className="block text-sm font-medium text-gray-300">
                                        Description
                                    </label>
                                    <textarea
                                        id="description"
                                        rows={3}
                                        value={formData.description}
                                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                        className="mt-1 block w-full px-3 py-2 border border-gray-600 rounded-md shadow-sm bg-gray-700 text-white placeholder-gray-400 focus:outline-none focus:ring-primary-500 focus:border-primary-500"
                                    />
                                </div>
                            </div>
                            <div className="mt-6 flex justify-end space-x-3">
                                <button
                                    type="button"
                                    onClick={handleCloseDialog}
                                    className="px-4 py-2 border border-gray-600 rounded-md text-sm font-medium text-gray-300 bg-gray-700 hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-gray-500"
                                >
                                    Cancel
                                </button>
                                <button
                                    type="submit"
                                    disabled={!formData.name.trim()}
                                    className="px-4 py-2 border border-transparent rounded-md text-sm font-medium text-white bg-primary-600 hover:bg-primary-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary-500 disabled:opacity-50 disabled:cursor-not-allowed"
                                >
                                    {editingItem ? 'Update' : 'Create'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default MainApp; 