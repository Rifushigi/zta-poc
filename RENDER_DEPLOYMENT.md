# 🚀 Render Deployment Guide

This guide will help you deploy your Zero Trust Architecture PoC on Render.

## 📋 Prerequisites

- GitHub repository with your Zero Trust PoC code
- Render account (free tier available)
- PostgreSQL database (Render's managed service recommended)

## 🎯 Deployment Options

### Option 1: Single Docker Service (Recommended)
**Best for: Demo, testing, small-scale deployments**

- **Service Type**: Web Service
- **Environment**: Docker
- **Complexity**: Low
- **Cost**: Lower

### Option 2: Split Services (Advanced)
**Best for: Production, scalability, team development**

- Frontend: Static Site
- Backend: Web Service (Node.js)
- Database: PostgreSQL (managed)
- Keycloak: Web Service (Docker)
- Monitoring: Separate services

## 🚀 Quick Deployment (Option 1)

### Step 1: Prepare Your Repository

1. **Push your code to GitHub** (if not already done)
2. **Ensure these files are in your root directory**:
   - `docker-compose.render.yml`
   - `Dockerfile.render`
   - `nginx.render.conf`

### Step 2: Create Render Web Service

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Click "New +"** → **"Web Service"**
3. **Connect your GitHub repository**
4. **Configure the service**:

```
Name: zero-trust-poc
Environment: Docker
Region: Choose closest to you
Branch: main (or your default branch)
Root Directory: ./
Build Command: docker-compose -f docker-compose.render.yml build
Start Command: docker-compose -f docker-compose.render.yml up
```

### Step 3: Set Environment Variables

In your Render service settings, add these environment variables:

#### Required Variables:
```bash
# Database (use Render's managed PostgreSQL)
DATABASE_URL=postgresql://username:password@host:port/database

# Keycloak Configuration
KEYCLOAK_URL=https://your-app-name.onrender.com/auth
KEYCLOAK_REALM=zerotrust
KEYCLOAK_CLIENT_ID=frontend-app
KEYCLOAK_CLIENT_SECRET=your-client-secret
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=secure-password
KEYCLOAK_HOSTNAME=your-app-name.onrender.com

# Backend Configuration
BACKEND_URL=https://your-app-name.onrender.com/backend
JWT_SECRET=your-super-secret-jwt-key

# Monitoring URLs
PROMETHEUS_URL=https://your-app-name.onrender.com/monitoring/prometheus
GRAFANA_URL=https://your-app-name.onrender.com/monitoring/grafana
```

#### Optional Variables:
```bash
# PostgreSQL (if using local container)
POSTGRES_USER=backend
POSTGRES_PASSWORD=backendpass
POSTGRES_DB=zerotrust
```

### Step 4: Deploy

1. **Click "Create Web Service"**
2. **Wait for build to complete** (5-10 minutes)
3. **Check logs** for any errors

## 🗄️ Database Setup

### Option A: Render's Managed PostgreSQL (Recommended)

1. **Create PostgreSQL service** in Render dashboard
2. **Copy the connection string** from the service
3. **Set as `DATABASE_URL`** in your web service environment variables

### Option B: Local PostgreSQL Container

The `docker-compose.render.yml` includes a local PostgreSQL container for development.

## 🔐 Keycloak Setup

After deployment:

1. **Access Keycloak**: `https://your-app-name.onrender.com/auth`
2. **Login with admin credentials**:
   - Username: `admin`
   - Password: `securepassword` (or your `KEYCLOAK_ADMIN_PASSWORD`)
3. **Create realm**: `zerotrust`
4. **Create client**: `frontend-app`
5. **Set client secret** and update `KEYCLOAK_CLIENT_SECRET` in Render

## 🌐 Access Your Application

Once deployed, you can access:

- **Main Application**: `https://your-app-name.onrender.com`
- **Keycloak Admin**: `https://your-app-name.onrender.com/auth`
- **Backend API**: `https://your-app-name.onrender.com/backend`
- **API Gateway**: `https://your-app-name.onrender.com/api`
- **Grafana**: `https://your-app-name.onrender.com/monitoring/grafana`
- **Prometheus**: `https://your-app-name.onrender.com/monitoring/prometheus`

## 🔧 Advanced Configuration

### Custom Domain

1. **Add custom domain** in Render service settings
2. **Update `KEYCLOAK_HOSTNAME`** environment variable
3. **Configure DNS** to point to your Render service

### SSL/TLS

Render automatically provides SSL certificates for your service.

### Scaling

- **Free tier**: 750 hours/month, sleeps after 15 minutes of inactivity
- **Paid plans**: Always-on, custom domains, more resources

## 🚨 Troubleshooting

### Common Issues

#### 1. Build Failures
```bash
# Check build logs in Render dashboard
# Common causes:
# - Missing files (Dockerfile.render, nginx.render.conf)
# - Docker syntax errors
# - Memory limits exceeded
```

#### 2. Service Won't Start
```bash
# Check start command logs
# Verify environment variables are set
# Check if all required services are healthy
```

#### 3. Database Connection Issues
```bash
# Verify DATABASE_URL format
# Check if database service is running
# Ensure network connectivity
```

#### 4. Keycloak Configuration
```bash
# Verify KEYCLOAK_URL format
# Check if realm and client exist
# Ensure client secret is correct
```

### Debug Commands

```bash
# Check service health
curl https://your-app-name.onrender.com/health

# Check individual services
curl https://your-app-name.onrender.com/backend/health
curl https://your-app-name.onrender.com/auth/health
```

### Logs

- **Render Dashboard**: View real-time logs
- **Service Logs**: Check individual container logs
- **Nginx Logs**: Check proxy and routing issues

## 📊 Monitoring

### Built-in Monitoring
- **Render Dashboard**: Service health, logs, metrics
- **Grafana**: Custom dashboards for Zero Trust metrics
- **Prometheus**: Application metrics and alerts

### Health Checks
- **Main Service**: `https://your-app-name.onrender.com/health`
- **Backend**: `https://your-app-name.onrender.com/backend/health`
- **Keycloak**: `https://your-app-name.onrender.com/auth/health`

## 🔄 Updates and Maintenance

### Updating Your Application
1. **Push changes** to your GitHub repository
2. **Render automatically rebuilds** and deploys
3. **Monitor deployment** in Render dashboard

### Environment Variable Changes
1. **Update variables** in Render service settings
2. **Redeploy service** to apply changes

### Database Migrations
1. **Backup database** before major changes
2. **Run migrations** through your backend service
3. **Verify data integrity** after deployment

## 💰 Cost Optimization

### Free Tier Limits
- **750 hours/month** (about 31 days)
- **512MB RAM** per service
- **Sleeps after 15 minutes** of inactivity
- **No custom domains**

### Paid Plans
- **Always-on services**
- **Custom domains**
- **More resources**
- **Better performance**

## 🎯 Next Steps

1. **Test all functionality** after deployment
2. **Configure monitoring alerts**
3. **Set up custom domain** (if needed)
4. **Implement CI/CD** for automated deployments
5. **Add security scanning** to your pipeline

## 📞 Support

- **Render Documentation**: https://render.com/docs
- **Render Community**: https://community.render.com
- **Zero Trust PoC Issues**: Check your repository issues

---

**Happy Deploying! 🚀** 