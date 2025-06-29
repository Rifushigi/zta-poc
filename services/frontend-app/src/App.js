import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline, Box } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Components
import Layout from './components/Layout';
import Login from './components/Login';
import Dashboard from './components/Dashboard';
import DataManagement from './components/DataManagement';
import AdminPanel from './components/AdminPanel';
import SecurityOverview from './components/SecurityOverview';

// Context
import { AuthProvider, useAuth } from './contexts/AuthContext';

// Create theme
const theme = createTheme({
    palette: {
        mode: 'dark',
        primary: {
            main: '#2196f3',
        },
        secondary: {
            main: '#f50057',
        },
        background: {
            default: '#0a0a0a',
            paper: '#1a1a1a',
        },
    },
    typography: {
        fontFamily: 'Roboto, Arial, sans-serif',
    },
});

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
const ProtectedRoute = ({ children, requiredRoles = [] }) => {
    const { isAuthenticated, user, loading } = useAuth();

    if (loading) {
        return <div>Loading...</div>;
    }

    if (!isAuthenticated) {
        return <Navigate to="/login" replace />;
    }

    if (requiredRoles.length > 0 && !requiredRoles.some(role => user?.roles?.includes(role))) {
        return <Navigate to="/dashboard" replace />;
    }

    return children;
};

// Main App Component
function AppContent() {
    const { isAuthenticated } = useAuth();

    return (
        <Router>
            <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
                <CssBaseline />
                <Routes>
                    <Route path="/login" element={
                        isAuthenticated ? <Navigate to="/dashboard" replace /> : <Login />
                    } />
                    <Route path="/" element={
                        <ProtectedRoute>
                            <Layout />
                        </ProtectedRoute>
                    }>
                        <Route index element={<Navigate to="/dashboard" replace />} />
                        <Route path="dashboard" element={<Dashboard />} />
                        <Route path="data" element={<DataManagement />} />
                        <Route path="admin" element={
                            <ProtectedRoute requiredRoles={['admin']}>
                                <AdminPanel />
                            </ProtectedRoute>
                        } />
                        <Route path="security" element={
                            <ProtectedRoute requiredRoles={['admin', 'security']}>
                                <SecurityOverview />
                            </ProtectedRoute>
                        } />
                    </Route>
                </Routes>
            </Box>
        </Router>
    );
}

// Root App Component
function App() {
    return (
        <QueryClientProvider client={queryClient}>
            <ThemeProvider theme={theme}>
                <AuthProvider>
                    <AppContent />
                </AuthProvider>
            </ThemeProvider>
        </QueryClientProvider>
    );
}

export default App; 