# Pool Monitor and Chemical Dispenser API

A Flask-based REST API for monitoring pool water quality and managing chemical dispenser data.

## Features

- Pool water quality monitoring (pH, turbidity, temperature)
- Device management and configuration
- Chemical dispenser data management
- Real-time alerts for critical conditions
- SQLite database with SQLAlchemy ORM

## Installation

1. Navigate to the server directory:
```bash
cd server
```

2. Create and activate virtual environment:
```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. Install dependencies:
```bash
pip install flask flask-cors flask-sqlalchemy python-dotenv
```

4. Run the application:
```bash
python main.py
```

The server will start on http://localhost:5001

## API Endpoints

### Authentication Endpoints

#### User Registration and Login
- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get JWT token
- `GET /api/auth/profile` - Get current user profile (requires auth)
- `PUT /api/auth/profile` - Update user profile (requires auth)
- `PUT /api/auth/change-password` - Change user password (requires auth)
- `GET /api/users` - Get all users (admin only, requires auth)

### Pool Monitor Endpoints

#### Device Data Collection
- `POST /pool/data` - Receive sensor data from ESP32 devices
- `GET /pool/config?device_id=<id>` - Get device configuration

#### Device Management
- `GET /api/devices` - Get all registered devices
- `GET /api/devices/<device_id>` - Get specific device information  
- `PUT /api/devices/<device_id>` - Update device information

#### Device Readings
- `GET /api/devices/<device_id>/readings` - Get sensor readings (limited to 100 records)
  - Query parameters: `limit` (max 100), `hours` (filter by time)
- `GET /api/devices/<device_id>/latest` - Get latest sensor reading

#### Device Configuration
- `GET /api/devices/<device_id>/config` - Get device configuration
- `POST /api/devices/<device_id>/config` - Create device configuration
- `PUT /api/devices/<device_id>/config` - Update device configuration

#### Statistics
- `GET /api/stats/<device_id>` - Get device statistics
  - Query parameters: `hours` (default: 24)

### Chemical Dispensing Jobs Endpoints

#### CRUD Operations for Chemical Dispensing Jobs
- `POST /api/dispensing-jobs` - Create new chemical dispensing job
- `GET /api/dispensing-jobs` - Get PENDING dispensing jobs (limited to 100 records)
  - Query parameters: `limit` (max 100), `device_id` (filter by device)
- `GET /api/dispensing-jobs/<device_id>` - Get dispensing jobs for specific device
  - Query parameters: `limit` (max 100), `status` (default: PENDING)
- `GET /api/dispensing-jobs/all` - Get ALL dispensing jobs for tracking (including completed)
  - Query parameters: `limit` (max 500), `device_id` (filter by device), `status` (filter by status)
- `PUT /api/dispensing-jobs/<record_id>` - Update dispensing job record

### Chemical Dispensing Jobs Data Format

The chemical dispensing system manages the following job data:

```json
{
  "id": 1,
  "device_id": "ESP32_CHEM_001",
  "hcl": 10.0,
  "soda": 12.0,
  "cl": 0.0,
  "al": 0.0,
  "flag": "PENDING",
  "timestamp": "2023-01-01T10:00:00"
}
```

**Fields:**
- `device_id`: Chemical dispensing device identifier (string)
- `hcl`: Hydrochloric acid level (float)
- `soda`: Soda ash level (float) 
- `cl`: Chlorine level (float)
- `al`: Aluminum level (float)
- `flag`: Status flag (string, e.g., "PENDING", "COMPLETED", "ERROR")
- `timestamp`: ISO format timestamp

## API Sample Payloads and Examples

### 1. Authentication Endpoints

#### Register a New User
**POST** `/api/auth/register`

**Request Payload:**
```json
{
  "email": "john.doe@example.com",
  "password": "secure_password123",
  "first_name": "John",
  "last_name": "Doe",
  "role": "user"
}
```

**Sample cURL:**
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "secure_password123",
    "first_name": "John",
    "last_name": "Doe"
  }'
```

**Response:**
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "email": "john.doe@example.com",
    "first_name": "John",
    "last_name": "Doe",
    "role": "user",
    "is_active": true,
    "created_at": "2023-12-16T14:30:00.000000",
    "last_login": null
  },
  "token": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9..."
}
```

#### Login User
**POST** `/api/auth/login`

**Request Payload:**
```json
{
  "email": "john.doe@example.com",
  "password": "secure_password123"
}
```

**Sample cURL:**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "john.doe@example.com",
    "password": "secure_password123"
  }'
```

#### Update Profile
**PUT** `/api/auth/profile`

**Request Payload:**
```json
{
  "first_name": "John Updated",
  "last_name": "Doe Updated"
}
```

**Sample cURL:**
```bash
curl -X PUT http://localhost:5000/api/auth/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "first_name": "John Updated",
    "last_name": "Doe Updated"
  }'
```

#### Change Password
**PUT** `/api/auth/change-password`

**Request Payload:**
```json
{
  "current_password": "secure_password123",
  "new_password": "new_secure_password456"
}
```

### 2. Pool Monitor Device Endpoints

#### Send Device Data (ESP32)
**POST** `/pool/data`

**Request Payload:**
```json
{
  "device_id": "ESP32_POOL_001",
  "sensors": {
    "ph": 7.2,
    "turbidity": 3.5,
    "temperature": 26.8
  },
  "status": {
    "water_quality": "optimal",
    "wifi_rssi": -65,
    "uptime": 3600
  }
}
```

**Sample cURL:**
```bash
curl -X POST http://localhost:5000/pool/data \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "ESP32_POOL_001",
    "sensors": {
      "ph": 7.2,
      "turbidity": 3.5,
      "temperature": 26.8
    },
    "status": {
      "water_quality": "optimal",
      "wifi_rssi": -65,
      "uptime": 3600
    }
  }'
```

#### Update Device Information
**PUT** `/api/devices/<device_id>`

**Request Payload:**
```json
{
  "name": "Backyard Pool Monitor",
  "location": "Main Pool Area - Southeast Corner"
}
```

**Sample cURL:**
```bash
curl -X PUT http://localhost:5000/api/devices/ESP32_POOL_001 \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Backyard Pool Monitor",
    "location": "Main Pool Area - Southeast Corner"
  }'
```

### 3. Device Configuration Endpoints

#### Create Device Configuration
**POST** `/api/devices/<device_id>/config`

**Request Payload:**
```json
{
  "calibration": {
    "ph_offset": 0.1,
    "ph_slope": 0.98,
    "turbidity_offset": -0.5,
    "turbidity_slope": 1.02,
    "temp_offset": 0.2
  },
  "thresholds": {
    "ph": {
      "optimal": 7.2,
      "acceptable": 7.8,
      "critical": 8.5
    },
    "turbidity": {
      "optimal": 5.0,
      "acceptable": 20.0,
      "critical": 50.0
    },
    "temperature": {
      "optimal": 26.0,
      "acceptable": 30.0,
      "critical": 33.0
    }
  },
  "intervals": {
    "post_interval": 2000,
    "config_interval": 60000
  }
}
```

**Sample cURL:**
```bash
curl -X POST http://localhost:5000/api/devices/ESP32_POOL_001/config \
  -H "Content-Type: application/json" \
  -d '{
    "thresholds": {
      "ph": {"optimal": 7.2, "acceptable": 7.8, "critical": 8.5},
      "turbidity": {"optimal": 5.0, "acceptable": 20.0, "critical": 50.0},
      "temperature": {"optimal": 26.0, "acceptable": 30.0, "critical": 33.0}
    },
    "intervals": {"post_interval": 2000, "config_interval": 60000}
  }'
```

#### Update Device Configuration
**PUT** `/api/devices/<device_id>/config`

**Request Payload:**
```json
{
  "thresholds": {
    "ph": {
      "optimal": 7.4,
      "critical": 8.2
    }
  },
  "intervals": {
    "post_interval": 1500
  }
}
```

### 4. Chemical Dispensing Jobs Endpoints

#### Create Chemical Dispensing Job
**POST** `/api/dispensing-jobs`

**Request Payload:**
```json
{
  "device_id": "ESP32_CHEM_001",
  "hcl": 10.5,
  "soda": 12.3,
  "cl": 2.1,
  "al": 0.8,
  "flag": "PENDING",
  "timestamp": "2023-12-16 14:30:00"
}
```

**Sample cURL:**
```bash
curl -X POST http://localhost:5000/api/dispensing-jobs \
  -H "Content-Type: application/json" \
  -d '{
    "device_id": "ESP32_CHEM_001",
    "hcl": 10.5,
    "soda": 12.3,
    "cl": 2.1,
    "al": 0.8,
    "flag": "PENDING",
    "timestamp": "2023-12-16 14:30:00"
  }'
```

**Response:**
```json
{
  "id": 1,
  "device_id": "ESP32_CHEM_001",
  "hcl": 10.5,
  "soda": 12.3,
  "cl": 2.1,
  "al": 0.8,
  "flag": "PENDING",
  "timestamp": "2023-12-16T14:30:00"
}
```

#### Update Chemical Dispensing Job
**PUT** `/api/dispensing-jobs/<record_id>`

**Request Payload:**
```json
{
  "flag": "IN_PROGRESS",
  "hcl": 11.2,
  "soda": 13.1
}
```

**Sample cURL:**
```bash
curl -X PUT http://localhost:5000/api/dispensing-jobs/1 \
  -H "Content-Type: application/json" \
  -d '{
    "flag": "IN_PROGRESS",
    "hcl": 11.2,
    "soda": 13.1
  }'
```

### 5. Sample GET Responses

#### Get All Devices
**GET** `/api/devices`

**Response:**
```json
[
  {
    "id": 1,
    "device_id": "ESP32_POOL_001",
    "name": "Backyard Pool Monitor",
    "location": "Main Pool Area - Southeast Corner",
    "registered_at": "2023-12-16T10:00:00.000000",
    "last_seen": "2023-12-16T14:30:00.000000"
  }
]
```

#### Get Device Readings
**GET** `/api/devices/ESP32_POOL_001/readings?limit=5`

**Response:**
```json
[
  {
    "id": 150,
    "device_id": "ESP32_POOL_001",
    "timestamp": "2023-12-16T14:30:00.000000",
    "ph": 7.2,
    "turbidity": 3.5,
    "temperature": 26.8,
    "water_quality": "optimal",
    "wifi_rssi": -65,
    "uptime": 3600
  },
  {
    "id": 149,
    "device_id": "ESP32_POOL_001",
    "timestamp": "2023-12-16T14:29:00.000000",
    "ph": 7.1,
    "turbidity": 3.8,
    "temperature": 26.9,
    "water_quality": "optimal",
    "wifi_rssi": -67,
    "uptime": 3540
  }
]
```

#### Get Chemical Dispensing Jobs (PENDING Jobs Only)
**GET** `/api/dispensing-jobs?limit=3`

**Response:**
```json
[
  {
    "id": 5,
    "device_id": "ESP32_CHEM_001",
    "hcl": 11.2,
    "soda": 13.1,
    "cl": 2.1,
    "al": 0.8,
    "flag": "PENDING",
    "timestamp": "2023-12-16T14:35:00"
  },
  {
    "id": 4,
    "device_id": "ESP32_CHEM_002",
    "hcl": 10.8,
    "soda": 12.5,
    "cl": 1.9,
    "al": 0.7,
    "flag": "PENDING",
    "timestamp": "2023-12-16T14:20:00"
  },
  {
    "id": 3,
    "device_id": "ESP32_CHEM_001",
    "hcl": 10.5,
    "soda": 12.3,
    "cl": 2.1,
    "al": 0.8,
    "flag": "PENDING",
    "timestamp": "2023-12-16T14:10:00"
  }
]
```

#### Get Device Statistics
**GET** `/api/stats/ESP32_POOL_001?hours=24`

**Response:**
```json
{
  "period_hours": 24,
  "total_readings": 1440,
  "ph": {
    "avg": 7.25,
    "min": 6.9,
    "max": 7.6
  },
  "turbidity": {
    "avg": 4.2,
    "min": 2.1,
    "max": 8.9
  },
  "temperature": {
    "avg": 26.8,
    "min": 24.2,
    "max": 29.1
  }
}
```

### 6. Query Parameters Examples

```bash
# Get device readings with custom limit and time filter
curl "http://localhost:5000/api/devices/ESP32_POOL_001/readings?limit=50&hours=12"

# Get dispensing jobs data with limit
curl "http://localhost:5000/api/dispensing-jobs?limit=25"

# Get PENDING jobs for specific device
curl "http://localhost:5000/api/dispensing-jobs?device_id=ESP32_CHEM_001"

# Get jobs by device ID (dedicated endpoint)
curl "http://localhost:5000/api/dispensing-jobs/ESP32_CHEM_001"

# Get jobs by device ID with custom status
curl "http://localhost:5000/api/dispensing-jobs/ESP32_CHEM_001?status=COMPLETED&limit=10"

# Get ALL jobs for tracking (including completed ones)
curl "http://localhost:5000/api/dispensing-jobs/all"

# Get all jobs for specific device (all statuses)
curl "http://localhost:5000/api/dispensing-jobs/all?device_id=ESP32_CHEM_001"

# Get all completed jobs for tracking
curl "http://localhost:5000/api/dispensing-jobs/all?status=COMPLETED&limit=200"

# Get device statistics for last week
curl "http://localhost:5000/api/stats/ESP32_POOL_001?hours=168"

# Get device configuration from ESP32
curl "http://localhost:5000/pool/config?device_id=ESP32_POOL_001"
```

### 7. Error Response Examples

**400 Bad Request:**
```json
{
  "error": "Missing required field: device_id"
}
```

**401 Unauthorized:**
```json
{
  "error": "Token is missing"
}
```

**404 Not Found:**
```json
{
  "error": "Device not found"
}
```

**409 Conflict:**
```json
{
  "error": "Email already exists"
}
```

## Environment Variables

Create a `.env` file in the server directory:

```
DEBUG=True
PORT=5001
DATABASE_URL=sqlite:///pool_monitor.db
JWT_SECRET_KEY=your-super-secret-jwt-key-change-in-production
```

## Database Models

The API uses SQLAlchemy with the following models:
- `Device` (pool_devices) - Pool monitoring devices
- `SensorReading` (pool_sensor_readings) - Sensor data from devices
- `DeviceConfig` (pool_device_configs) - Device configuration and calibration
- `Alert` (pool_alerts) - Critical condition alerts
- `ChemicalDispenser` (chemical_dispenser_jobs) - Chemical dispenser job data
- `User` (user_accounts) - User authentication data

## Project Structure

```
pool-monitor-and-dispenser/
├── README.md
├── firmware/
│   └── firmware.ino
└── server/
    ├── main.py
    ├── dependencies.txt
    └── instance/
```