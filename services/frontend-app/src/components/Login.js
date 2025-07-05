import React, { useState } from 'react';
import {
    Box,
    Paper,
    Typography,
    Button,
    Container,
    Card,
    CardContent,
    Alert,
    CircularProgress,
    TextField,
    FormControl,
    InputLabel,
    OutlinedInput,
    InputAdornment,
    IconButton
} from '@mui/material';
import { Security, Login as LoginIcon, Visibility, VisibilityOff } from '@mui/icons-material';
import { useAuth } from '../contexts/AuthContext';

const Login = () => {
    const { login, loading } = useAuth();
    const [formData, setFormData] = useState({
        username: '',
        password: ''
    });
    const [showPassword, setShowPassword] = useState(false);
    const [loginLoading, setLoginLoading] = useState(false);
    const [error, setError] = useState('');

    const handleInputChange = (e) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
        setError(''); // Clear error when user types
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoginLoading(true);
        setError('');

        try {
            const result = await login(formData.username, formData.password);
            if (!result.success) {
                setError(result.error || 'Login failed');
            }
        } catch (err) {
            setError('Login failed. Please try again.');
        } finally {
            setLoginLoading(false);
        }
    };

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

                        {error && (
                            <Alert severity="error" sx={{ mb: 3 }}>
                                {error}
                            </Alert>
                        )}

                        <Box component="form" onSubmit={handleSubmit}>
                            <TextField
                                fullWidth
                                label="Username"
                                name="username"
                                value={formData.username}
                                onChange={handleInputChange}
                                margin="normal"
                                required
                                disabled={loginLoading}
                                sx={{ mb: 2 }}
                            />

                            <FormControl fullWidth margin="normal" required>
                                <InputLabel htmlFor="password">Password</InputLabel>
                                <OutlinedInput
                                    id="password"
                                    name="password"
                                    type={showPassword ? 'text' : 'password'}
                                    value={formData.password}
                                    onChange={handleInputChange}
                                    disabled={loginLoading}
                                    endAdornment={
                                        <InputAdornment position="end">
                                            <IconButton
                                                onClick={() => setShowPassword(!showPassword)}
                                                edge="end"
                                            >
                                                {showPassword ? <VisibilityOff /> : <Visibility />}
                                            </IconButton>
                                        </InputAdornment>
                                    }
                                    label="Password"
                                />
                            </FormControl>

                            <Box textAlign="center" mt={3}>
                                <Button
                                    type="submit"
                                    variant="contained"
                                    size="large"
                                    startIcon={loginLoading ? <CircularProgress size={20} /> : <LoginIcon />}
                                    disabled={loginLoading || !formData.username || !formData.password}
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
                                    {loginLoading ? 'Signing In...' : 'Sign In'}
                                </Button>
                            </Box>
                        </Box>

                        <Box mt={4} textAlign="center">
                            <Typography variant="body2" color="text.secondary">
                                Demo Credentials:
                            </Typography>
                            <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                                <strong>User:</strong> user / userpass
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                                <strong>Admin:</strong> admin / adminpass
                            </Typography>
                        </Box>
                    </CardContent>
                </Card>
            </Container>
        </Box>
    );
};

export default Login; 