import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import { CssBaseline, Box } from '@mui/material';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

// Components
import Login from './components/Login';
import MainApp from './components/MainApp';

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
const ProtectedRoute = ({ children }) => {
    const { isAuthenticated, loading } = useAuth();

    if (loading) {
        return (
            <Box display="flex" justifyContent="center" alignItems="center" minHeight="100vh">
                <div>Loading...</div>
            </Box>
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
            <Box sx={{ display: 'flex', flexDirection: 'column', minHeight: '100vh' }}>
                <CssBaseline />
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