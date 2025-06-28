import React from 'react';
import {
    Box,
    Paper,
    Typography,
    Button,
    Container,
    Card,
    CardContent,
    Alert,
    CircularProgress
} from '@mui/material';
import { Security, Login as LoginIcon } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';

const Login = () => {
    const { login, loading } = useAuth();

    if (loading) {
        return (
            <Box
                display="flex"
                justifyContent="center"
                alignItems="center"
                minHeight="100vh"
                bgcolor="background.default"
            >
                <CircularProgress size={60} />
            </Box>
        );
    }

    return (
        <Box
            minHeight="100vh"
            display="flex"
            alignItems="center"
            bgcolor="background.default"
            sx={{
                background: 'linear-gradient(135deg, #0a0a0a 0%, #1a1a1a 100%)'
            }}
        >
            <Container maxWidth="sm">
                <Card
                    elevation={8}
                    sx={{
                        borderRadius: 3,
                        background: 'rgba(26, 26, 26, 0.9)',
                        backdropFilter: 'blur(10px)',
                        border: '1px solid rgba(255, 255, 255, 0.1)'
                    }}
                >
                    <CardContent sx={{ p: 4 }}>
                        <Box textAlign="center" mb={4}>
                            <Security
                                sx={{
                                    fontSize: 60,
                                    color: 'primary.main',
                                    mb: 2
                                }}
                            />
                            <Typography variant="h4" component="h1" gutterBottom>
                                Zero Trust
                            </Typography>
                            <Typography variant="body1" color="text.secondary">
                                Secure Authentication Portal
                            </Typography>
                        </Box>

                        <Alert severity="info" sx={{ mb: 3 }}>
                            This application demonstrates Zero Trust Architecture principles including
                            identity-based access control, policy enforcement, and secure authentication.
                        </Alert>

                        <Box textAlign="center">
                            <Button
                                variant="contained"
                                size="large"
                                startIcon={<LoginIcon />}
                                onClick={login}
                                sx={{
                                    py: 1.5,
                                    px: 4,
                                    fontSize: '1.1rem',
                                    borderRadius: 2,
                                    textTransform: 'none',
                                    boxShadow: 3,
                                    '&:hover': {
                                        boxShadow: 6,
                                        transform: 'translateY(-2px)'
                                    }
                                }}
                            >
                                Sign In with Keycloak
                            </Button>
                        </Box>

                        <Box mt={4} textAlign="center">
                            <Typography variant="body2" color="text.secondary">
                                Demo Credentials:
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                                <strong>User:</strong> user / password123
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                                <strong>Admin:</strong> admin / admin123
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Container>
        </Box>
    );
};

export default Login; 