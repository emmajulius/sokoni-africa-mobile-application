# Sokoni Africa - Multi-Vendor Marketplace

A comprehensive multi-vendor marketplace application designed to facilitate seamless e-commerce transactions across Africa. The platform allows users to register as buyers or sellers, post products, make orders, and perform transactions using both local currency and in-app currency.

## 🚀 Project Overview

Sokoni Africa is a full-stack e-commerce platform that empowers small and medium businesses to reach wider audiences while providing a secure, reliable, and scalable digital commerce environment.

### Technology Stack

- **Frontend**: Flutter (Android/iOS mobile platforms and web PWA support)
- **Backend**: FastAPI with JWT authentication
- **Admin Dashboard**: Analytics, reporting, and user management
- **Payment Integration**: Flutterwave (test mode) supporting TZS, KES, NGN
- **API Integrations**: Products, orders, wallet, and payment processing

## 📋 Scope of Implementation

The project includes:

- ✅ Flutter frontend with cross-platform support (Android, iOS, Web PWA)
- ✅ FastAPI backend with comprehensive API endpoints
- ✅ Admin dashboard for analytics, reporting, and user management
- ✅ API integrations (authentication, products, orders, wallet, payments)
- ✅ Bash automation scripts for setup, testing, deployment, and API demos
- ✅ Security features including JWT authentication and API rate limiting
- ✅ Functional mobile app, admin dashboard, and web PWA

## ✨ Key Achievements

### Codebase Exploration & Documentation
- Full exploration and documentation of frontend, backend, and admin modules
- Detailed record of implemented features, completed improvements, and pending items

### Backend & API Integrations
- ✅ JWT authentication with secure token flow
- ✅ Product, order, and wallet modules fully integrated
- ✅ Flutterwave payments integrated in test mode: supports TZS, KES, NGN

### Admin Dashboard
- ✅ Complete analytics and reporting functionality
- ✅ User and product management features implemented

### Bash Automation Scripts
- ✅ Scripts for setup, frontend/backend start, testing, build, and API demonstration
- ✅ Realistic terminal examples for all operations

### Live Auctions
- ✅ Database-driven auction logic implemented
- ✅ Real-time state persistence without polling or WebSockets

### Security & Performance
- ✅ Token refresh logic implemented to avoid session expiry interruptions
- ✅ API security hardening: rate limits, input sanitization, HTTPS enforcement, login throttling
- ✅ Service worker & PWA manifest improved for faster mobile load times and offline reliability
- ✅ Modular frontend code for maintainability

## ⏳ Outstanding / Pending Items

- ⏸️ Paid Twilio SMS OTP integration for full password reset workflow
- ⏸️ Paid Flutterwave gateway for full payment workflow

## 🛠️ Bash Automation Scripts

All scripts are located in `scripts/` and use `#!/usr/bin/env bash` with `set -euo pipefail` for cross-platform compatibility.

### Available Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `setup.sh` | Complete project setup (Flutter + Python deps) | `bash scripts/setup.sh` |
| `start-frontend.sh` | Start Flutter development server | `bash scripts/start-frontend.sh` |
| `start-backend.sh` | Start FastAPI backend server | `bash scripts/start-backend.sh` |
| `dev_servers.sh` | Start both frontend and backend together | `bash scripts/dev_servers.sh` |
| `test.sh` | Run all tests (Flutter + backend) | `bash scripts/test.sh` |
| `build.sh` | Build production releases | `bash scripts/build.sh` |
| `api-demo.sh` | Interactive API endpoint demonstrations | `bash scripts/api-demo.sh` |
| `quality_checks.sh` | Run code quality checks | `bash scripts/quality_checks.sh` |
| `bootstrap.sh` | Quick dependency installation | `bash scripts/bootstrap.sh` |

### Realistic Terminal Examples

#### Example 1: Clone and Setup Repository

```bash
$ git clone https://github.com/emmajulius/sokoni-africa-app.git
Cloning into 'sokoni-africa-app'...
...
$ cd sokoni-africa-app

$ bash scripts/setup.sh
 Setting up Sokoni Africa App...
Checking Flutter installation...
✓ Found: Flutter 3.24.0 • channel stable
Checking Python installation...
✓ Found: Python 3.11.5
Installing Flutter dependencies...
✓ Flutter dependencies installed
Setting up Python virtual environment...
✓ Virtual environment created
✓ Virtual environment activated
Upgrading pip...
✓ pip upgraded
Installing Python dependencies...
✓ Python dependencies installed
Checking environment configuration...
  .env file not found. Please create a .env file in africa_sokoni_app_backend/
 Setup complete!
```

#### Example 2: Start Backend Server

```bash
$ bash scripts/start-backend.sh
 Starting FastAPI backend server...
 Server running on http://0.0.0.0:8000
```

#### Example 3: Start Frontend Development Server

```bash
$ bash scripts/start-frontend.sh
 Launching Flutter app on Chrome...
✓ Built build\web (15.2s)
```

#### Example 4: Run All Tests

```bash
$ bash scripts/test.sh
 Running Flutter & backend tests...
✓ All Flutter tests passed
✓ All backend tests passed
```

#### Example 5: Build for Production

```bash
$ bash scripts/build.sh
 Building Sokoni Africa App...
✓ Web build output: build/web/
✓ Android APK: build/app/outputs/flutter-apk/app-release.apk
```

#### Example 6: API Demo Requests

```bash
$ bash scripts/api-demo.sh

# GET /api/products
curl -X GET "http://localhost:8000/api/products?limit=5"

# POST /api/auth/register
curl -X POST "http://localhost:8000/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"username":"demo_user","full_name":"Demo User","email":"demo@example.com","phone":"+255712345678","password":"SecurePass123!"}'
```

#### Example 7: Run Both Servers Simultaneously

```bash
$ bash scripts/dev_servers.sh
 Starting backend and frontend servers together...
```

## 📦 Final Deliverables Summary

### ✅ Completed

- Flutter mobile app (Android/iOS) & web PWA support
- FastAPI backend with JWT authentication
- Admin dashboard with analytics & reporting
- API integrations for products, orders, wallet, and Flutterwave test payments
- Modularized frontend code
- Bash automation scripts (setup, dev, test, build, API demo)
- Live auctions implemented
- Token refresh logic and API security hardening

### ⏸️ Pending

- Paid Twilio SMS OTP integration for password reset
- Paid Flutterwave gateway for live implementation

## 🎯 Conclusion

The Sokoni Africa App is fully functional, scalable, and production-ready for Android/iOS and web. All core marketplace features, automation scripts, and admin functionality are implemented. Only paid Twilio OTP and paid Flutterwave integration remains pending.

## 📚 Additional Documentation

- [API Documentation](API_DOCUMENTATION.md)
- [Project Report](SOKONI_AFRICA_APP_REPORT.md)

