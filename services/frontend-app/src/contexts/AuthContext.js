import React, { createContext, useContext, useState, useEffect } from 'react';
import axios from 'axios';

const AuthContext = createContext();

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider = ({ children }) => {
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    // Configure axios to include credentials (cookies)
    const api = axios.create({
        baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
        withCredentials: true,
        timeout: 10000,
    });

    // Check authentication status on mount
    useEffect(() => {
        checkAuth();
    }, []);

    const checkAuth = async () => {
        try {
            const response = await api.get('/auth/me');
            setUser(response.data.user);
            setIsAuthenticated(true);
        } catch (error) {
            console.log('Not authenticated:', error.message);
            setUser(null);
            setIsAuthenticated(false);
        } finally {
            setLoading(false);
        }
    };

    const login = async (username, password) => {
        try {
            const response = await api.post('/auth/login', { username, password });
            setUser(response.data.user);
            setIsAuthenticated(true);
            return { success: true };
        } catch (error) {
            console.error('Login failed:', error.response?.data || error.message);
            return {
                success: false,
                error: error.response?.data?.error || 'Login failed'
            };
        }
    };

    const logout = async () => {
        try {
            await api.post('/auth/logout');
        } catch (error) {
            console.error('Logout error:', error);
        } finally {
            setUser(null);
            setIsAuthenticated(false);
        }
    };

    const refreshToken = async () => {
        try {
            await api.post('/auth/refresh');
            await checkAuth(); // Re-check auth status
            return true;
        } catch (error) {
            console.error('Token refresh failed:', error);
            setUser(null);
            setIsAuthenticated(false);
            return false;
        }
    };

    const value = {
        isAuthenticated,
        user,
        loading,
        login,
        logout,
        refreshToken,
        checkAuth
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
}; 