import axios from 'axios';

// Create axios instance
const api = axios.create({
    baseURL: process.env.REACT_APP_API_URL || 'http://localhost:3000',
    timeout: 10000,
});

// Request interceptor to add auth token
api.interceptors.request.use(
    async (config) => {
        // Get token from Keycloak if available
        if (window.keycloak && window.keycloak.token) {
            try {
                await window.keycloak.updateToken(30);
                config.headers.Authorization = `Bearer ${window.keycloak.token}`;
            } catch (error) {
                console.error('Token refresh failed:', error);
                window.keycloak.logout();
            }
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Response interceptor for error handling
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response?.status === 401) {
            // Unauthorized - redirect to login
            if (window.keycloak) {
                window.keycloak.logout();
            }
        }
        return Promise.reject(error);
    }
);

export default api; 