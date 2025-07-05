import React, { createContext, useContext, useState, useEffect } from 'react';
import Keycloak from 'keycloak-js';

const AuthContext = createContext();

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};

export const AuthProvider = ({ children }) => {
    const [keycloak, setKeycloak] = useState(null);
    const [isAuthenticated, setIsAuthenticated] = useState(false);
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        const initKeycloak = async () => {
            const kc = new Keycloak({
                url: process.env.REACT_APP_KEYCLOAK_URL || 'http://localhost:8082/auth',
                realm: process.env.REACT_APP_KEYCLOAK_REALM || 'zero-trust',
                clientId: process.env.REACT_APP_KEYCLOAK_CLIENT_ID || 'myapp',
                checkLoginIframe: false,
                silentCheckSsoRedirectUri: null,
                enableLogging: true,
                onLoad: 'login-required',
                checkLoginIframeInterval: 0
            });

            try {
                const authenticated = await kc.init({
                    onLoad: 'login-required',
                    checkLoginIframe: false
                });

                setKeycloak(kc);
                setIsAuthenticated(authenticated);

                if (authenticated) {
                    const userInfo = await kc.loadUserInfo();
                    setUser({
                        id: userInfo.sub,
                        username: userInfo.preferred_username,
                        email: userInfo.email,
                        name: userInfo.name,
                        roles: kc.tokenParsed?.realm_access?.roles || []
                    });
                }
            } catch (error) {
                console.error('Keycloak initialization failed:', error);
            } finally {
                setLoading(false);
            }
        };

        initKeycloak();
    }, []);

    const login = () => {
        if (keycloak) {
            keycloak.login();
        }
    };

    const logout = () => {
        if (keycloak) {
            keycloak.logout();
        }
    };

    const getToken = async () => {
        if (keycloak) {
            try {
                await keycloak.updateToken(30);
                return keycloak.token;
            } catch (error) {
                console.error('Token refresh failed:', error);
                logout();
                return null;
            }
        }
        return null;
    };

    const value = {
        keycloak,
        isAuthenticated,
        user,
        loading,
        login,
        logout,
        getToken
    };

    return (
        <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>
    );
}; 