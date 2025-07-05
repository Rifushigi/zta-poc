import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Components
import Login from './components/Login';
import MainApp from './components/MainApp';

// Context
import { AuthProvider, useAuth } from './contexts/AuthContext';

// Create query client
const queryClient = new QueryClient({
    defaultOptions: {
        queries: {
            retry: 1,
            refetchOnWindowFocus: false,
        },
    },
});

// Protected Route Component
const ProtectedRoute = ({ children }) => {
    const { isAuthenticated, loading } = useAuth();

    if (loading) {
        return (
            <div className="flex justify-center items-center min-h-screen bg-gray-900">
                <div className="text-white">Loading...</div>
            </div>
        );
    }

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    return children;
};

// Main App Component
function AppContent() {
    const { isAuthenticated } = useAuth();

    return (
        <Router>
            <div className="min-h-screen bg-gray-900 text-white">
                <Routes>
                    <Route path="/login" element={
                        isAuthenticated ? <Navigate to="/" replace /> : <Login />
                    } />
                    <Route path="/" element={
                        <ProtectedRoute>
                            <MainApp />
                        </ProtectedRoute>
                    } />
                </Routes>
            </div>
        </Router>
    );
}

// Root App Component
function App() {
    return (
        <QueryClientProvider client={queryClient}>
            <AuthProvider>
                <AppContent />
            </AuthProvider>
        </QueryClientProvider>
    );
}

export default App; 