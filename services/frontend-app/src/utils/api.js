import axios from 'axios';

// Create axios instance for API calls
const api = axios.create({
    baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
    timeout: 10000,
    withCredentials: true, // Include cookies in requests
});

// Request interceptor to handle authentication
api.interceptors.request.use(
    async (config) => {
        // Add any additional headers if needed
        config.headers['Content-Type'] = 'application/json';
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Response interceptor for error handling
api.interceptors.response.use(
    (response) => response,
    async (error) => {
        if (error.response?.status === 401) {
            // Unauthorized - could try to refresh token or redirect to login
            console.log('Unauthorized request, user needs to login');
        }
        return Promise.reject(error);
    }
);

export default api; 