# Swift Transit

## Your Day-to-Day Travel Solution

Swift Transit is a full-stack, real-time public bus transit management and ticketing platform built for modern urban transportation. The system connects passengers, bus drivers, fleet owners, and system administrators through a unified ecosystem of mobile applications, web portals, and a high-performance backend server.

The platform enables passengers to discover routes, purchase tickets, track buses in real time, and pay via integrated payment gateways or digital wallets. Bus drivers broadcast live GPS positions, validate passenger QR codes, and manage boarding workflows. Fleet owners gain access to deep operational and revenue analytics. System administrators maintain complete oversight of the entire platform from a dedicated management console.

---

## Table of Contents

- [System Overview](#system-overview)
- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Features](#features)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Installation and Setup](#installation-and-setup)
  - [Backend Server](#backend-server)
  - [Passenger Web Portal](#passenger-web-portal)
  - [System Admin Panel](#system-admin-panel)
  - [Passenger Mobile Application](#passenger-mobile-application)
  - [Bus Driver Mobile Application](#bus-driver-mobile-application)
- [Environment Configuration](#environment-configuration)
- [Database Overview](#database-overview)
- [API Structure](#api-structure)
- [Running in Production](#running-in-production)
- [Contributing](#contributing)
- [License](#license)

---

## System Overview

Swift Transit is organized around four primary actors:

**Passengers** — End users who search for routes, purchase tickets with QR code delivery, track buses in real time via map, manage a digital wallet, and receive PDF ticket downloads.

**Bus Drivers** — Authenticated devices that broadcast live GPS coordinates over WebSocket, scan passenger QR codes for validation, and manage boarding and over-travel detection workflows.

**Bus Owners / Fleet Operators** — Managers who register and configure buses, assign routes (bidirectional up/down variants), and access comprehensive operational and revenue analytics dashboards.

**System Administrators** — Privileged users who manage the entire platform including users, bus owners, buses, routes, tickets, and transactions from a dedicated admin console.

---

## Architecture

The backend follows a clean layered architecture with clear separation between the HTTP transport layer, domain services, and data access repositories.

```
HTTP Request
     |
     v
Middleware (logging, CORS, JWT authentication)
     |
     v
REST Handler (per actor: user, bus, bus_owner, admin, route, ticket, transaction)
     |
     v
Domain Service (business rules: fare calculation, ticket limits, validation)
     |
     v
Repository (data access via sqlx and PostgreSQL)
     |
     v
Infrastructure (PostgreSQL/PostGIS, Redis, RabbitMQ, SSLCommerz payment gateway)
```

**Asynchronous Ticket Processing** — Ticket purchase requests are published to a RabbitMQ queue. Background workers consume these messages to generate QR codes, produce PDF tickets, initiate payment flows, and mark tickets as paid after payment confirmation. This decouples the HTTP request from the long-running ticket creation pipeline.

**Real-Time Location Broadcasting** — A WebSocket hub handles bidirectional communication. Bus devices publish GPS coordinates, and the hub fans these updates out to all passenger clients subscribed to that route.

**Redis for State Management** — Redis stores transient ticket processing state, idempotency keys, and payment session data to prevent duplicate operations and enable resilient retry logic.

---

## Technology Stack

### Backend

| Component          | Technology                        | Version       |
|--------------------|-----------------------------------|---------------|
| Language           | Go                                | 1.24.6        |
| HTTP Framework     | Standard Library net/http         | —             |
| Database           | PostgreSQL with PostGIS extension | 14+           |
| Cache              | Redis                             | 6+            |
| Message Queue      | RabbitMQ                          | 3.12+         |
| ORM / Query        | sqlx                              | 1.4.0         |
| WebSocket          | Gorilla WebSocket                 | 1.5.3         |
| PDF Generation     | go-pdf/fpdf                       | 0.9.0         |
| QR Code            | skip2/go-qrcode                   | latest        |
| Payment Gateway    | SSLCommerz                        | —             |
| Environment Loader | godotenv                          | 1.5.1         |
| Migrations         | rubenv/sql-migrate                | 1.8.0         |

### Frontend — Web (React)

| Component        | Technology         | Version   |
|------------------|--------------------|-----------|
| Framework        | React              | 19.2.1    |
| Routing          | React Router DOM   | 7.10.1    |
| Styling          | Tailwind CSS       | 3.4.18    |
| Charts           | Recharts           | 3.5.1     |
| HTTP Client      | Axios              | 1.13.2    |
| Icons            | React Icons        | 5.5.0     |
| Build Tool       | react-scripts      | 5.0.1     |

### Frontend — Mobile (Flutter)

| Component          | Technology           | Version        |
|--------------------|----------------------|----------------|
| Framework          | Flutter              | 3.9.2          |
| State Management   | Provider             | 6.1.5          |
| Maps               | Flutter Map          | 6.1.0          |
| Location Services  | Geolocator           | 11.0.0 / 13.0.1|
| WebSocket          | web_socket_channel   | 3.0.1          |
| QR Scanning        | mobile_scanner       | 6.0.4          |
| HTTP Client        | http                 | 1.2.0          |
| Local Storage      | shared_preferences   | 2.2.2          |
| Fonts              | google_fonts         | 6.2.1          |
| Web View           | webview_flutter      | 4.8.0          |

---

## Features

### Passenger Features

- Account registration with OTP-based mobile verification and email confirmation
- Password management including reset via OTP workflow
- Route search and bus discovery with geographic stop information
- Real-time bus location tracking via WebSocket-powered map view
- Ticket purchase with automatic QR code and PDF generation
- Payment via integrated SSLCommerz payment gateway
- Digital wallet with balance management and top-up functionality
- RFID card support for contactless payment at boarding
- Ticket cancellation and automated refund processing
- Over-travel detection with automatic fare adjustment
- User profile management

### Bus Driver Features

- Secure device authentication and registration
- Live GPS location broadcasting to passenger map feeds
- QR code ticket scanning and validation at boarding
- Route assignment with bidirectional route variant support (up/down)
- Over-travel detection and passenger charge processing

### Bus Owner / Fleet Operator Features

- Bus registration and fleet management (up to 10 buses per owner)
- Route configuration with up and down variant assignment
- Operational analytics: active ticket counts, check-in statistics, over-travel events
- Revenue analytics: ticket sales reports, per-route earnings, historical revenue trends
- Payment completion metrics and refund/cancellation tracking
- Fleet utilization reporting

### System Administrator Features

- Complete system management dashboard with platform-wide statistics
- User management: create, view, edit, delete accounts and adjust wallet balances
- Bus owner management: full lifecycle management of fleet operator accounts
- Bus management: registration, status, and route assignment
- Route management: create and configure routes with geographic stop data
- Ticket analytics: platform-wide ticket and payment reporting
- Transaction tracking and audit

---

## Project Structure

```
Swift_Transit/
├── backend/                          # Go backend server
│   ├── cmd/                          # Application entry points
│   │   ├── serve.go                  # Main server bootstrap
│   │   └── create_admin/             # Admin account creation utility
│   ├── config/                       # Environment configuration loader
│   ├── rest/                         # HTTP transport layer
│   │   ├── handlers/                 # Request handlers per actor
│   │   │   ├── admin/
│   │   │   ├── bus/
│   │   │   ├── bus_owner/
│   │   │   ├── route/
│   │   │   ├── ticket/
│   │   │   ├── transaction/
│   │   │   └── user/
│   │   ├── middlewares/              # JWT auth, CORS, logging
│   │   ├── handler.go                # Handler initialization
│   │   └── server.go                 # HTTP server and route registration
│   ├── domain/                       # Business logic interfaces
│   ├── user/                         # User domain service
│   ├── bus/                          # Bus domain service
│   ├── bus_owner/                    # Bus owner domain service
│   ├── route/                        # Route domain service
│   ├── ticket/                       # Ticket domain service and workers
│   ├── transaction/                  # Transaction domain service
│   ├── admin/                        # Admin domain service
│   ├── repo/                         # Data access repositories
│   ├── model/                        # Data model definitions
│   ├── db_queries/                   # SQL query definitions
│   ├── infra/                        # Infrastructure adapters
│   │   ├── db/                       # PostgreSQL connection and migration
│   │   ├── redis/                    # Redis client setup
│   │   ├── rabbitmq/                 # RabbitMQ connection
│   │   └── payment/                  # SSLCommerz payment gateway adapter
│   ├── location/                     # WebSocket hub for real-time GPS
│   ├── utils/                        # Shared utilities
│   ├── migrations/                   # SQL migration files (16 versioned files)
│   ├── route_demo/                   # Sample route GeoJSON data for testing
│   ├── main.go                       # Application entry point
│   ├── go.mod                        # Go module definition
│   ├── go.sum                        # Dependency checksums
│   ├── .env.example                  # Environment variable template
│   └── ARCHITECTURE.md               # Detailed architecture documentation
│
├── web/
│   ├── swifttransit/                 # Passenger web portal (React)
│   │   ├── src/
│   │   │   ├── pages/                # Dashboard, Login, BusManagement
│   │   │   ├── App.js
│   │   │   └── index.js
│   │   ├── tailwind.config.js
│   │   └── package.json
│   └── sysadmin/                     # System admin panel (React)
│       ├── src/
│       │   ├── context/              # AuthContext for global auth state
│       │   ├── components/           # Reusable layout components
│       │   ├── pages/                # Login, Dashboard, Users, Buses, Routes,
│       │   │                         # BusOwners, Tickets, Transactions
│       │   ├── App.js
│       │   └── index.js
│       ├── tailwind.config.js
│       └── package.json
│
└── app/
    ├── swifttransit/                 # Passenger Flutter mobile app
    │   ├── lib/
    │   ├── pubspec.yaml
    │   └── android/ ios/ web/
    └── swifttransit_bus/             # Bus driver Flutter mobile app
        ├── lib/
        ├── pubspec.yaml
        └── android/ ios/ web/
```

---

## Prerequisites

Before setting up Swift Transit, ensure the following software is installed and running on your system.

### Required for Backend

| Requirement     | Minimum Version | Notes                                    |
|-----------------|-----------------|------------------------------------------|
| Go              | 1.24.6          | Available at https://go.dev/dl/          |
| PostgreSQL      | 14              | Must include the PostGIS extension       |
| PostGIS         | 3.x             | Geographic extension for PostgreSQL      |
| Redis           | 6.0             | For caching and session state            |
| RabbitMQ        | 3.12            | For async ticket processing queue        |
| Git             | Any             | For cloning the repository               |

### Required for Web Frontend

| Requirement | Minimum Version | Notes                    |
|-------------|-----------------|--------------------------|
| Node.js     | 18.x LTS        | Includes npm             |
| npm         | 9.x             | Bundled with Node.js     |

### Required for Mobile Applications

| Requirement   | Minimum Version | Notes                                           |
|---------------|-----------------|-------------------------------------------------|
| Flutter SDK   | 3.9.2           | Available at https://docs.flutter.dev/get-started/install |
| Dart SDK      | Bundled         | Included with Flutter                           |
| Android SDK   | API 21+         | For Android builds (via Android Studio)         |
| Xcode         | 14+             | For iOS builds (macOS only)                     |

---

## Installation and Setup

### Backend Server

**Step 1: Navigate to the backend directory**

```bash
cd backend
```

**Step 2: Create the environment configuration file**

Copy the example environment file and populate it with your configuration values. Refer to the [Environment Configuration](#environment-configuration) section for a description of each variable.

```bash
cp .env.example .env
```

Open `.env` in your editor and configure all required values including database credentials, Redis address, RabbitMQ URL, SSLCommerz API keys, and Gmail credentials for email notifications.

**Step 3: Install Go dependencies**

```bash
go mod download
```

**Step 4: Set up the PostgreSQL database**

Create the database and enable the PostGIS extension.

```sql
CREATE DATABASE swift_transit;
\c swift_transit
CREATE EXTENSION IF NOT EXISTS postgis;
```

Database migrations run automatically when the server starts. No manual migration step is required.

**Step 5: Start the backend server**

```bash
go run main.go
```

The server will:
- Load configuration from `.env`
- Connect to PostgreSQL and run pending migrations
- Connect to Redis and RabbitMQ
- Start background ticket processing workers
- Initialize the WebSocket hub
- Register all HTTP routes
- Start listening on the configured port (default: `8080`)

**Step 6: Create the initial administrator account**

In a separate terminal, run the admin creation utility:

```bash
cd backend
go run cmd/create_admin/main.go
```

Follow the prompts to set the administrator username and password.

---

### Passenger Web Portal

**Step 1: Navigate to the passenger web directory**

```bash
cd web/swifttransit
```

**Step 2: Install dependencies**

```bash
npm install
```

**Step 3: Start the development server**

```bash
npm start
```

The application will open at `http://localhost:3000`.

**Step 4: Build for production**

```bash
npm run build
```

The optimized production build will be output to the `build/` directory.

---

### System Admin Panel

**Step 1: Navigate to the admin panel directory**

```bash
cd web/sysadmin
```

**Step 2: Install dependencies**

```bash
npm install
```

**Step 3: Start the development server**

```bash
npm start
```

If the passenger web portal is already running on port 3000, set a different port:

```bash
PORT=3001 npm start
```

The admin panel will be available at `http://localhost:3001`.

**Step 4: Build for production**

```bash
npm run build
```

---

### Passenger Mobile Application

**Step 1: Navigate to the passenger app directory**

```bash
cd app/swifttransit
```

**Step 2: Install Flutter dependencies**

```bash
flutter pub get
```

**Step 3: Verify Flutter setup**

```bash
flutter doctor
```

Resolve any issues reported by Flutter Doctor before proceeding.

**Step 4: Run on a connected device or emulator**

```bash
flutter run
```

To target a specific device:

```bash
flutter devices          # List available devices
flutter run -d <device_id>
```

**Step 5: Build release APK (Android)**

```bash
flutter build apk --release
```

The APK will be located at `build/app/outputs/flutter-apk/app-release.apk`.

**Step 6: Build for iOS (macOS only)**

```bash
flutter build ios --release
```

---

### Bus Driver Mobile Application

**Step 1: Navigate to the bus driver app directory**

```bash
cd app/swifttransit_bus
```

**Step 2: Install Flutter dependencies**

```bash
flutter pub get
```

**Step 3: Run on a connected device or emulator**

```bash
flutter run
```

**Step 4: Build release APK (Android)**

```bash
flutter build apk --release
```

---

## Environment Configuration

The backend server requires a `.env` file located inside the `backend/` directory. Copy `backend/.env.example` to `backend/.env` and set each variable as described below.

### Application Settings

| Variable          | Description                                             | Example Value       |
|-------------------|---------------------------------------------------------|---------------------|
| `SERVICE_NAME`    | Display name of the service                             | `Swift Transit`     |
| `HTTP_PORT`       | Port the HTTP server listens on                         | `8080`              |
| `SECRET`          | Secret key used for signing JWT tokens                  | A long random string|
| `VERSION`         | Application version string                              | `1.0.0`             |
| `PUBLIC_BASE_URL` | Publicly accessible base URL for payment callbacks      | `https://your-domain.com` |

### PostgreSQL Database

| Variable          | Description                         | Example Value  |
|-------------------|-------------------------------------|----------------|
| `HOST`            | PostgreSQL server hostname          | `localhost`    |
| `USER`            | PostgreSQL username                 | `postgres`     |
| `PORT`            | PostgreSQL port                     | `5432`         |
| `NAME`            | Database name                       | `swift_transit`|
| `PASSWORD`        | PostgreSQL password                 | your password  |
| `ENABLE_SSL_MODE` | Enable SSL for database connections | `false`        |

### Redis Cache

| Variable         | Description                | Example Value |
|------------------|----------------------------|---------------|
| `REDIS_ADDRESS`  | Redis server hostname      | `localhost`   |
| `REDIS_PORT`     | Redis server port          | `6379`        |
| `REDIS_PASSWORD` | Redis password (if any)    | `""`          |
| `REDIS_DB`       | Redis database index       | `0`           |

### RabbitMQ Message Queue

| Variable        | Description                            | Example Value                          |
|-----------------|----------------------------------------|----------------------------------------|
| `RABBITMQ_URL`  | Full AMQP connection string            | `amqp://guest:guest@localhost:5672/`   |

### Payment Gateway (SSLCommerz)

| Variable           | Description                              | Example Value  |
|--------------------|------------------------------------------|----------------|
| `STORE_ID`         | SSLCommerz merchant store ID             | your store ID  |
| `STORE_PASSWORD`   | SSLCommerz merchant store password       | your password  |
| `IS_SANDBOX`       | Use sandbox environment for testing      | `true`         |

Set `IS_SANDBOX` to `false` in production with live SSLCommerz credentials.

### Email Notifications

| Variable          | Description                                             | Example Value                      |
|-------------------|---------------------------------------------------------|------------------------------------|
| `GMAIL`           | Gmail address used to send OTP and notification emails  | `youremail@gmail.com`              |
| `GMAIL_PASSWORD`  | Gmail App Password (not your account password)          | 16-character app-specific password |

To generate a Gmail App Password, enable two-factor authentication on the Gmail account and generate a dedicated App Password from Google Account Security settings.

---

## Database Overview

Swift Transit uses PostgreSQL 14+ with the PostGIS geographic extension. The schema is version-controlled via 16 sequential SQL migration files in `backend/migrations/`. Migrations execute automatically on server startup.

### Core Tables

**users** — Registered passenger accounts with wallet balances, RFID card linkage, and National ID verification.

**bus_credentials** — Bus device authentication records storing hashed passwords, route assignments (bidirectional up/down variant route IDs), and bus owner linkage.

**bus_owners** — Fleet operator accounts with hashed credentials.

**admins** — System administrator accounts with bcrypt-hashed passwords.

**routes** — Geographic route definitions stored as PostGIS LineString geometries.

**stops** — Route stops with ordering, point geometry for the stop location, and polygon geometry defining the stop service area.

**tickets** — Complete ticket lifecycle records including fare, payment status, payment method, QR code data, validation status, batch processing ID, and cancellation timestamp.

**transactions** — Wallet and payment transaction ledger tracking all monetary movements (credits, debits, purchases, refunds).

---

## API Structure

The backend exposes a RESTful HTTP API organized by actor. All protected endpoints require a valid JWT token in the `Authorization` header.

### User and Authentication Endpoints

| Method | Path                      | Description                           | Auth Required |
|--------|---------------------------|---------------------------------------|---------------|
| POST   | /user                     | Initiate passenger registration       | No            |
| POST   | /user/verify              | Verify registration OTP               | No            |
| POST   | /auth/login               | Passenger login                       | No            |
| POST   | /auth/forgot-password     | Initiate password reset               | No            |
| POST   | /auth/verify-otp          | Verify password reset OTP             | No            |
| POST   | /auth/reset-password      | Complete password reset               | No            |
| GET    | /user                     | Retrieve user profile                 | Yes           |
| PUT    | /user                     | Update user profile                   | Yes           |
| POST   | /auth/change-password     | Change account password               | Yes           |
| GET    | /user/rfid                | Get RFID card status                  | Yes           |
| POST   | /user/rfid/toggle         | Enable or disable RFID                | Yes           |

### Route Endpoints

| Method | Path        | Description                      | Auth Required |
|--------|-------------|----------------------------------|---------------|
| POST   | /route      | Create a new route               | Admin         |
| GET    | /route      | List or search routes            | No            |
| GET    | /route/:id  | Get route details                | No            |

### Ticket Endpoints

| Method | Path                   | Description                           | Auth Required |
|--------|------------------------|---------------------------------------|---------------|
| POST   | /ticket                | Purchase a ticket                     | Yes           |
| GET    | /ticket                | Get passenger tickets                 | Yes           |
| GET    | /ticket/:id            | Get specific ticket details           | Yes           |
| DELETE | /ticket/:id            | Cancel a ticket                       | Yes           |
| GET    | /ticket/download/:id   | Download PDF ticket                   | Yes           |

### Transaction Endpoints

| Method | Path               | Description                      | Auth Required |
|--------|--------------------|----------------------------------|---------------|
| POST   | /transaction/recharge | Initiate wallet recharge      | Yes           |
| GET    | /transaction       | Get transaction history          | Yes           |

### Bus Endpoints

| Method | Path                  | Description                           | Auth Required |
|--------|-----------------------|---------------------------------------|---------------|
| POST   | /bus/login            | Bus device login                      | No            |
| POST   | /bus/register         | Register a bus device                 | Bus Owner     |
| POST   | /bus/validate-ticket  | Validate a scanned passenger ticket   | Bus Auth      |
| WS     | /ws/bus               | WebSocket for GPS publishing          | Bus Auth      |

### Bus Owner Endpoints

| Method | Path                         | Description                       | Auth Required |
|--------|------------------------------|-----------------------------------|---------------|
| POST   | /bus-owner/login             | Bus owner login                   | No            |
| GET    | /bus-owner/buses             | List owned buses                  | Yes           |
| GET    | /bus-owner/analytics/ops     | Operational analytics             | Yes           |
| GET    | /bus-owner/analytics/revenue | Revenue analytics                 | Yes           |

### Admin Endpoints

| Method | Path                | Description                              | Auth Required |
|--------|---------------------|------------------------------------------|---------------|
| POST   | /admin/login        | Admin login                              | No            |
| GET    | /admin/users        | List all users                           | Admin         |
| PUT    | /admin/users/:id    | Update user (including balance)          | Admin         |
| DELETE | /admin/users/:id    | Delete user                              | Admin         |
| GET    | /admin/buses        | List all buses                           | Admin         |
| GET    | /admin/bus-owners   | List all bus owners                      | Admin         |
| GET    | /admin/routes       | List all routes                          | Admin         |
| GET    | /admin/tickets      | Ticket analytics                         | Admin         |
| GET    | /admin/transactions | Transaction tracking                     | Admin         |

### WebSocket

| Path         | Description                                               |
|--------------|-----------------------------------------------------------|
| /ws/passenger | Passenger subscribes to real-time bus location updates   |
| /ws/bus       | Bus device publishes live GPS coordinates                 |

---

## Running in Production

The following considerations apply when deploying Swift Transit to a production environment.

**JWT Secret** — Replace the default `SECRET` value in `.env` with a long, cryptographically random string. This key signs all authentication tokens. If it is exposed or weak, the system is compromised.

**SSLCommerz** — Set `IS_SANDBOX=false` and replace sandbox credentials with live production credentials obtained from your SSLCommerz merchant account.

**PUBLIC_BASE_URL** — Set this to the actual publicly reachable URL of your backend server. SSLCommerz uses this to send payment status callbacks. It must be reachable from the internet and cannot be localhost.

**Gmail App Password** — Create a dedicated Gmail account for the service and generate a specific App Password. Do not use a personal Gmail account password directly.

**Database** — Use a managed PostgreSQL service or a dedicated server with regular backups. Ensure PostGIS is installed. Use SSL connections by setting `ENABLE_SSL_MODE=true` and providing appropriate certificates.

**Redis** — Use a password-protected Redis instance in production. Set `REDIS_PASSWORD` accordingly.

**RabbitMQ** — Replace the default guest credentials with a dedicated user. The `RABBITMQ_URL` should reflect the correct credentials and host.

**Build the backend binary**

```bash
cd backend
go build -o swift_transit_server main.go
./swift_transit_server
```

**Build frontend assets**

```bash
# Passenger web portal
cd web/swifttransit
npm run build

# Admin panel
cd web/sysadmin
npm run build
```

Serve the resulting `build/` directories via a static file server such as Nginx or Apache. Configure a reverse proxy to forward API requests to the Go backend.

---

## Contributing

Contributions are welcome. Please follow the steps below:

1. Fork the repository on GitHub.
2. Create a feature branch from the default branch: `git checkout -b feature/your-feature-name`.
3. Make your changes with clear, focused commits.
4. Ensure all existing functionality continues to work correctly.
5. Open a pull request with a clear description of the changes and the problem they solve.

Please keep pull requests focused and avoid combining unrelated changes in a single submission.

---

## License

This project is intended for academic and demonstration purposes. Please review the repository for any explicit license file. If no license is specified, all rights remain with the original authors.
