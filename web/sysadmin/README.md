# Swift Transit - System Admin Panel

Complete administrative control panel for managing the Swift Transit system.

## Features

- **User Management**: View, edit, delete users, adjust balances
- **Authentication**: Secure admin login with JWT
- **Responsive Design**: Clean, professional interface
- **Pagination**: Efficient handling of large datasets

## Setup Instructions

### 1. Run Database Migration

The admin table migration will be automatically applied when you restart the backend:

```bash
cd backend
go run main.go
```

### 2. Create Admin Credentials

Run the admin creation script to insert the admin user into the database:

```bash
cd backend
go run cmd/create_admin/main.go
```

**Default Credentials:**

- Username: `admin`
- Password: `admin123`

⚠️ **IMPORTANT**: Change the password in production!

### 3. Start the Admin Panel

```bash
cd web/sysadmin
npm start
```

The admin panel will be available at `http://localhost:3000`

## Usage

1. Navigate to `http://localhost:3000`
2. Login with admin credentials
3. Use the sidebar to navigate between sections
4. Manage users, view analytics, and control the system

## API Endpoints

### Authentication

- `POST /admin/auth/login` - Admin login

### User Management

- `GET /admin/users?page=1&page_size=20` - List users (paginated)
- `GET /admin/users/{id}` - Get user details
- `PUT /admin/users/{id}` - Update user
- `DELETE /admin/users/{id}` - Delete user

## Security

- Admin credentials are hashed using bcrypt
- All admin routes require JWT authentication
- No registration endpoint (admins must be created via script)
- Passwords are never returned in API responses

## Future Enhancements

Additional admin features can be added:

- Bus owner management
- Bus management
- Route management
- Ticket management
- Transaction management
- System-wide analytics dashboard

## Tech Stack

**Backend:**

- Go
- PostgreSQL
- JWT Authentication
- bcrypt for password hashing

**Frontend:**

- React
- React Router
- Axios
- Tailwind CSS
- React Icons
