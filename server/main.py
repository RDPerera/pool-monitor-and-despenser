from flask import Flask, request, jsonify
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from datetime import datetime, timedelta
import os
from dotenv import load_dotenv
from werkzeug.security import generate_password_hash, check_password_hash
import jwt
from functools import wraps

# Load environment variables
load_dotenv()


app = Flask(__name__)
# Allow all origins explicitly
CORS(app, resources={r"/*": {"origins": "*"}})

# Database configuration
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URL', 'sqlite:///pool_monitor.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'your-secret-key-change-in-production')
db = SQLAlchemy(app)

# ==================== DATABASE MODELS ====================

class User(db.Model):
    """Store user information for authentication"""
    __tablename__ = 'user_accounts'
    
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False)
    first_name = db.Column(db.String(50))
    last_name = db.Column(db.String(50))
    role = db.Column(db.String(20), default='user')  # user, admin
    is_active = db.Column(db.Boolean, default=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_login = db.Column(db.DateTime)
    
    def set_password(self, password):
        """Hash and set password"""
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        """Check if provided password matches hash"""
        return check_password_hash(self.password_hash, password)
    
    def generate_token(self):
        """Generate JWT token for user"""
        payload = {
            'user_id': self.id,
            'role': self.role,
            'exp': datetime.utcnow() + timedelta(hours=24)
        }
        return jwt.encode(payload, app.config['JWT_SECRET_KEY'], algorithm='HS256')
    
    def to_dict(self):
        return {
            'id': self.id,
            'email': self.email,
            'first_name': self.first_name,
            'last_name': self.last_name,
            'role': self.role,
            'is_active': self.is_active,
            'created_at': self.created_at.isoformat(),
            'last_login': self.last_login.isoformat() if self.last_login else None
        }


class Device(db.Model):
    """Store pool monitoring device information"""
    __tablename__ = 'pool_devices'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(50), unique=True, nullable=False)
    name = db.Column(db.String(100), default='Pool Monitor')
    location = db.Column(db.String(200))
    registered_at = db.Column(db.DateTime, default=datetime.utcnow)
    last_seen = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    readings = db.relationship('SensorReading', backref='device', lazy='dynamic', cascade='all, delete-orphan')
    config = db.relationship('DeviceConfig', backref='device', uselist=False, cascade='all, delete-orphan')
    
    def to_dict(self):
        return {
            'id': self.id,
            'device_id': self.device_id,
            'name': self.name,
            'location': self.location,
            'registered_at': self.registered_at.isoformat(),
            'last_seen': self.last_seen.isoformat()
        }


class SensorReading(db.Model):
    """Store pool sensor reading data"""
    __tablename__ = 'pool_sensor_readings'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(50), db.ForeignKey('pool_devices.device_id'), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    
    # Sensor values
    ph = db.Column(db.Float)
    turbidity = db.Column(db.Float)
    temperature = db.Column(db.Float)
    
    # Status
    water_quality = db.Column(db.String(20))  # optimal, acceptable, critical
    wifi_rssi = db.Column(db.Integer)
    uptime = db.Column(db.Integer)
    
    def to_dict(self):
        return {
            'id': self.id,
            'device_id': self.device_id,
            'timestamp': self.timestamp.isoformat(),
            'sensors': {
                'ph': self.ph,
                'turbidity': self.turbidity,
                'temperature': self.temperature
            },
            'status': {
                'water_quality': self.water_quality,
                'wifi_rssi': self.wifi_rssi,
                'uptime': self.uptime
            }
        }


class DeviceConfig(db.Model):
    """Store pool device configuration"""
    __tablename__ = 'pool_device_configs'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(50), db.ForeignKey('pool_devices.device_id'), unique=True, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Calibration values
    ph_offset = db.Column(db.Float, default=0.0)
    ph_slope = db.Column(db.Float, default=1.0)
    turbidity_offset = db.Column(db.Float, default=0.0)
    turbidity_slope = db.Column(db.Float, default=1.0)
    temp_offset = db.Column(db.Float, default=0.0)
    
    # pH Thresholds
    ph_optimal = db.Column(db.Float, default=7.4)
    ph_acceptable = db.Column(db.Float, default=7.8)
    ph_critical = db.Column(db.Float, default=8.5)
    
    # Turbidity Thresholds (NTU)
    turbidity_optimal = db.Column(db.Float, default=5.0)
    turbidity_acceptable = db.Column(db.Float, default=20.0)
    turbidity_critical = db.Column(db.Float, default=50.0)
    
    # Temperature Thresholds (C)
    temp_optimal = db.Column(db.Float, default=26.0)
    temp_acceptable = db.Column(db.Float, default=30.0)
    temp_critical = db.Column(db.Float, default=33.0)
    
    # Intervals (milliseconds)
    post_interval = db.Column(db.Integer, default=1000)
    config_interval = db.Column(db.Integer, default=60000)
    
    def to_dict(self):
        return {
            'calibration': {
                'ph_offset': self.ph_offset,
                'ph_slope': self.ph_slope,
                'turbidity_offset': self.turbidity_offset,
                'turbidity_slope': self.turbidity_slope,
                'temp_offset': self.temp_offset
            },
            'thresholds': {
                'ph': {
                    'optimal': self.ph_optimal,
                    'acceptable': self.ph_acceptable,
                    'critical': self.ph_critical
                },
                'turbidity': {
                    'optimal': self.turbidity_optimal,
                    'acceptable': self.turbidity_acceptable,
                    'critical': self.turbidity_critical
                },
                'temperature': {
                    'optimal': self.temp_optimal,
                    'acceptable': self.temp_acceptable,
                    'critical': self.temp_critical
                }
            },
            'intervals': {
                'post_interval': self.post_interval,
                'config_interval': self.config_interval
            }
        }


class Alert(db.Model):
    """Store pool monitoring alert information"""
    __tablename__ = 'pool_alerts'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(50), db.ForeignKey('pool_devices.device_id'), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    alert_type = db.Column(db.String(50))  # ph_critical, turbidity_critical, temp_critical
    severity = db.Column(db.String(20))  # warning, critical
    message = db.Column(db.String(500))
    value = db.Column(db.Float)
    acknowledged = db.Column(db.Boolean, default=False)
    
    def to_dict(self):
        return {
            'id': self.id,
            'device_id': self.device_id,
            'timestamp': self.timestamp.isoformat(),
            'alert_type': self.alert_type,
            'severity': self.severity,
            'message': self.message,
            'value': self.value,
            'acknowledged': self.acknowledged
        }


class ChemicalDispenser(db.Model):
    """Store chemical dispenser job data"""
    __tablename__ = 'chemical_dispenser_jobs'
    
    id = db.Column(db.Integer, primary_key=True)
    device_id = db.Column(db.String(50), nullable=False)
    hcl = db.Column(db.Float, nullable=False)
    soda = db.Column(db.Float, nullable=False)
    cl = db.Column(db.Float, nullable=False)
    al = db.Column(db.Float, nullable=False)
    flag = db.Column(db.String(50), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow, index=True)
    
    def to_dict(self):
        return {
            'id': self.id,
            'device_id': self.device_id,
            'hcl': self.hcl,
            'soda': self.soda,
            'cl': self.cl,
            'al': self.al,
            'flag': self.flag,
            'timestamp': self.timestamp.isoformat()
        }


# ==================== AUTHENTICATION DECORATOR ====================

def token_required(f):
    """Decorator to require JWT token for protected routes"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = request.headers.get('Authorization')
        
        if not token:
            return jsonify({'error': 'Token is missing'}), 401
        
        try:
            if token.startswith('Bearer '):
                token = token[7:]
            
            data = jwt.decode(token, app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
            current_user = User.query.get(data['user_id'])
            
            if not current_user or not current_user.is_active:
                return jsonify({'error': 'Token is invalid'}), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'Token has expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': 'Token is invalid'}), 401
        
        return f(current_user, *args, **kwargs)
    return decorated


# ==================== USER AUTHENTICATION ENDPOINTS ====================

@app.route('/api/auth/register', methods=['POST'])
def register():
    """Register a new user"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate required fields
        required_fields = ['email', 'password']
        for field in required_fields:
            if not data.get(field):
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        # Check if email already exists
        existing_user = User.query.filter_by(email=data['email']).first()
        if existing_user:
            return jsonify({'error': 'Email already exists'}), 409
        
        # Create new user
        user = User(
            email=data['email'],
            first_name=data.get('first_name'),
            last_name=data.get('last_name'),
            role=data.get('role', 'user')
        )
        user.set_password(data['password'])
        
        db.session.add(user)
        db.session.commit()
        
        # Generate token
        token = user.generate_token()
        
        return jsonify({
            'message': 'User registered successfully',
            'user': user.to_dict(),
            'token': token
        }), 201
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/login', methods=['POST'])
def login():
    """Login user and return JWT token"""
    try:
        data = request.get_json()
        
        if not data or not data.get('email') or not data.get('password'):
            return jsonify({'error': 'Email and password required'}), 400
        
        # Find user by email
        user = User.query.filter_by(email=data['email']).first()
        
        if not user or not user.check_password(data['password']):
            return jsonify({'error': 'Invalid credentials'}), 401
        
        if not user.is_active:
            return jsonify({'error': 'Account is deactivated'}), 401
        
        # Update last login
        user.last_login = datetime.utcnow()
        db.session.commit()
        
        # Generate token
        token = user.generate_token()
        
        return jsonify({
            'message': 'Login successful',
            'user': user.to_dict(),
            'token': token
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/profile', methods=['GET'])
@token_required
def get_profile(current_user):
    """Get current user profile"""
    return jsonify(current_user.to_dict()), 200


@app.route('/api/auth/profile', methods=['PUT'])
@token_required
def update_profile(current_user):
    """Update current user profile"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Update allowed fields
        if 'first_name' in data:
            current_user.first_name = data['first_name']
        if 'last_name' in data:
            current_user.last_name = data['last_name']
        
        db.session.commit()
        
        return jsonify({
            'message': 'Profile updated successfully',
            'user': current_user.to_dict()
        }), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/auth/change-password', methods=['PUT'])
@token_required
def change_password(current_user):
    """Change user password"""
    try:
        data = request.get_json()
        
        if not data or not data.get('current_password') or not data.get('new_password'):
            return jsonify({'error': 'Current password and new password required'}), 400
        
        # Verify current password
        if not current_user.check_password(data['current_password']):
            return jsonify({'error': 'Current password is incorrect'}), 401
        
        # Set new password
        current_user.set_password(data['new_password'])
        db.session.commit()
        
        return jsonify({'message': 'Password changed successfully'}), 200
        
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/users', methods=['GET'])
@token_required
def get_users(current_user):
    """Get all users (admin only)"""
    if current_user.role != 'admin':
        return jsonify({'error': 'Admin access required'}), 403
    
    try:
        users = User.query.all()
        return jsonify([user.to_dict() for user in users]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==================== API ENDPOINTS ====================

@app.route('/pool/data', methods=['POST'])
def receive_data():
    """Receive sensor data from ESP32 devices"""
    try:
        data = request.get_json()
        
        if not data or 'device_id' not in data:
            return jsonify({'error': 'Invalid data format'}), 400
        
        device_id = data['device_id']
        
        # Get or create device
        device = Device.query.filter_by(device_id=device_id).first()
        if not device:
            device = Device(device_id=device_id)
            db.session.add(device)
            
            # Create default config for new device
            config = DeviceConfig(device_id=device_id)
            db.session.add(config)
        
        # Update last seen
        device.last_seen = datetime.utcnow()
        
        # Extract sensor data
        sensors = data.get('sensors', {})
        status = data.get('status', {})
        
        # Create sensor reading
        reading = SensorReading(
            device_id=device_id,
            ph=sensors.get('ph'),
            turbidity=sensors.get('turbidity'),
            temperature=sensors.get('temperature'),
            water_quality=status.get('water_quality'),
            wifi_rssi=status.get('wifi_rssi'),
            uptime=status.get('uptime')
        )
        db.session.add(reading)
        
        # Check for critical conditions and create alerts
        config = device.config
        if config:
            alerts_to_create = []
            
            # Check pH
            ph = sensors.get('ph')
            if ph and (ph < config.ph_optimal - 1.0 or ph > config.ph_critical):
                alerts_to_create.append({
                    'type': 'ph_critical',
                    'severity': 'critical',
                    'message': f'pH level is critical: {ph:.2f}',
                    'value': ph
                })
            
            # Check turbidity
            turbidity = sensors.get('turbidity')
            if turbidity and turbidity > config.turbidity_critical:
                alerts_to_create.append({
                    'type': 'turbidity_critical',
                    'severity': 'critical',
                    'message': f'Turbidity level is critical: {turbidity:.2f} NTU',
                    'value': turbidity
                })
            
            # Check temperature
            temperature = sensors.get('temperature')
            if temperature and (temperature < config.temp_optimal - 4.0 or temperature > config.temp_critical):
                alerts_to_create.append({
                    'type': 'temperature_critical',
                    'severity': 'critical',
                    'message': f'Temperature is critical: {temperature:.2f}°C',
                    'value': temperature
                })
            
            # Create alerts (avoid duplicates within 5 minutes)
            for alert_data in alerts_to_create:
                recent_alert = Alert.query.filter_by(
                    device_id=device_id,
                    alert_type=alert_data['type'],
                    acknowledged=False
                ).filter(
                    Alert.timestamp > datetime.utcnow() - timedelta(minutes=5)
                ).first()
                
                if not recent_alert:
                    alert = Alert(
                        device_id=device_id,
                        alert_type=alert_data['type'],
                        severity=alert_data['severity'],
                        message=alert_data['message'],
                        value=alert_data['value']
                    )
                    db.session.add(alert)
        
        db.session.commit()
        
        return jsonify({
            'status': 'success',
            'message': 'Data received successfully',
            'reading_id': reading.id
        }), 200
        
    except Exception as e:
        db.session.rollback()
        print(f"Error receiving data: {e}")
        return jsonify({'error': str(e)}), 500


@app.route('/pool/config', methods=['GET'])
def get_config():
    """Send configuration to ESP32 device"""
    try:
        device_id = request.args.get('device_id')
        
        if not device_id:
            return jsonify({'error': 'device_id parameter required'}), 400
        
        # Get or create device config
        config = DeviceConfig.query.filter_by(device_id=device_id).first()
        
        if not config:
            # Create default config
            device = Device.query.filter_by(device_id=device_id).first()
            if not device:
                device = Device(device_id=device_id)
                db.session.add(device)
            
            config = DeviceConfig(device_id=device_id)
            db.session.add(config)
            db.session.commit()
        
        return jsonify(config.to_dict()), 200
        
    except Exception as e:
        print(f"Error getting config: {e}")
        return jsonify({'error': str(e)}), 500


# ==================== WEB API ENDPOINTS (for dashboard/admin) ====================

@app.route('/api/devices', methods=['GET'])
def get_devices():
    """Get all registered devices"""
    try:
        devices = Device.query.all()
        return jsonify([device.to_dict() for device in devices]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>', methods=['GET'])
def get_device(device_id):
    """Get specific device information"""
    try:
        device = Device.query.filter_by(device_id=device_id).first()
        if not device:
            return jsonify({'error': 'Device not found'}), 404
        
        return jsonify(device.to_dict()), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>', methods=['PUT'])
def update_device(device_id):
    """Update device information"""
    try:
        device = Device.query.filter_by(device_id=device_id).first()
        if not device:
            return jsonify({'error': 'Device not found'}), 404
        
        data = request.get_json()
        if 'name' in data:
            device.name = data['name']
        if 'location' in data:
            device.location = data['location']
        
        db.session.commit()
        return jsonify(device.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>/readings', methods=['GET'])
def get_readings(device_id):
    """Get sensor readings for a device"""
    try:
        # Get query parameters - limit to maximum 100 records
        limit = min(request.args.get('limit', 100, type=int), 100)
        hours = request.args.get('hours', type=int)
        
        query = SensorReading.query.filter_by(device_id=device_id)
        
        if hours:
            start_time = datetime.utcnow() - timedelta(hours=hours)
            query = query.filter(SensorReading.timestamp >= start_time)
        
        readings = query.order_by(SensorReading.timestamp.desc()).limit(limit).all()
        
        return jsonify([reading.to_dict() for reading in readings]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>/latest', methods=['GET'])
def get_latest_reading(device_id):
    """Get latest sensor reading for a device"""
    try:
        reading = SensorReading.query.filter_by(device_id=device_id)\
            .order_by(SensorReading.timestamp.desc()).first()
        
        if not reading:
            return jsonify({'error': 'No readings found'}), 404
        
        return jsonify(reading.to_dict()), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>/config', methods=['GET'])
def get_device_config(device_id):
    """Get device configuration"""
    try:
        config = DeviceConfig.query.filter_by(device_id=device_id).first()
        if not config:
            return jsonify({'error': 'Configuration not found'}), 404
        
        return jsonify(config.to_dict()), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>/config', methods=['POST'])
def create_device_config(device_id):
    """Create device configuration"""
    try:
        # Check if device exists
        device = Device.query.filter_by(device_id=device_id).first()
        if not device:
            return jsonify({'error': 'Device not found'}), 404
        
        # Check if config already exists
        existing_config = DeviceConfig.query.filter_by(device_id=device_id).first()
        if existing_config:
            return jsonify({'error': 'Configuration already exists. Use PUT to update.'}), 409
        
        data = request.get_json()
        config = DeviceConfig(device_id=device_id)
        
        # Set configuration values from request data
        if 'calibration' in data:
            cal = data['calibration']
            config.ph_offset = cal.get('ph_offset', 0.0)
            config.ph_slope = cal.get('ph_slope', 1.0)
            config.turbidity_offset = cal.get('turbidity_offset', 0.0)
            config.turbidity_slope = cal.get('turbidity_slope', 1.0)
            config.temp_offset = cal.get('temp_offset', 0.0)
        
        if 'thresholds' in data:
            thresh = data['thresholds']
            if 'ph' in thresh:
                config.ph_optimal = thresh['ph'].get('optimal', 7.4)
                config.ph_acceptable = thresh['ph'].get('acceptable', 7.8)
                config.ph_critical = thresh['ph'].get('critical', 8.5)
            if 'turbidity' in thresh:
                config.turbidity_optimal = thresh['turbidity'].get('optimal', 5.0)
                config.turbidity_acceptable = thresh['turbidity'].get('acceptable', 20.0)
                config.turbidity_critical = thresh['turbidity'].get('critical', 50.0)
            if 'temperature' in thresh:
                config.temp_optimal = thresh['temperature'].get('optimal', 26.0)
                config.temp_acceptable = thresh['temperature'].get('acceptable', 30.0)
                config.temp_critical = thresh['temperature'].get('critical', 33.0)
        
        if 'intervals' in data:
            intervals = data['intervals']
            config.post_interval = intervals.get('post_interval', 1000)
            config.config_interval = intervals.get('config_interval', 60000)
        
        db.session.add(config)
        db.session.commit()
        
        return jsonify(config.to_dict()), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>/config', methods=['PUT'])
def update_device_config(device_id):
    """Update device configuration"""
    try:
        config = DeviceConfig.query.filter_by(device_id=device_id).first()
        if not config:
            # Create config if doesn't exist
            device = Device.query.filter_by(device_id=device_id).first()
            if not device:
                return jsonify({'error': 'Device not found'}), 404
            config = DeviceConfig(device_id=device_id)
            db.session.add(config)
        
        data = request.get_json()
        
        # Update calibration
        if 'calibration' in data:
            cal = data['calibration']
            if 'ph_offset' in cal:
                config.ph_offset = cal['ph_offset']
            if 'ph_slope' in cal:
                config.ph_slope = cal['ph_slope']
            if 'turbidity_offset' in cal:
                config.turbidity_offset = cal['turbidity_offset']
            if 'turbidity_slope' in cal:
                config.turbidity_slope = cal['turbidity_slope']
            if 'temp_offset' in cal:
                config.temp_offset = cal['temp_offset']
        
        # Update thresholds
        if 'thresholds' in data:
            thresh = data['thresholds']
            if 'ph' in thresh:
                if 'optimal' in thresh['ph']:
                    config.ph_optimal = thresh['ph']['optimal']
                if 'acceptable' in thresh['ph']:
                    config.ph_acceptable = thresh['ph']['acceptable']
                if 'critical' in thresh['ph']:
                    config.ph_critical = thresh['ph']['critical']
            
            if 'turbidity' in thresh:
                if 'optimal' in thresh['turbidity']:
                    config.turbidity_optimal = thresh['turbidity']['optimal']
                if 'acceptable' in thresh['turbidity']:
                    config.turbidity_acceptable = thresh['turbidity']['acceptable']
                if 'critical' in thresh['turbidity']:
                    config.turbidity_critical = thresh['turbidity']['critical']
            
            if 'temperature' in thresh:
                if 'optimal' in thresh['temperature']:
                    config.temp_optimal = thresh['temperature']['optimal']
                if 'acceptable' in thresh['temperature']:
                    config.temp_acceptable = thresh['temperature']['acceptable']
                if 'critical' in thresh['temperature']:
                    config.temp_critical = thresh['temperature']['critical']
        
        # Update intervals
        if 'intervals' in data:
            intervals = data['intervals']
            if 'post_interval' in intervals:
                config.post_interval = intervals['post_interval']
            if 'config_interval' in intervals:
                config.config_interval = intervals['config_interval']
        
        config.updated_at = datetime.utcnow()
        db.session.commit()
        
        return jsonify(config.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/devices/<device_id>/alerts', methods=['GET'])
def get_alerts(device_id):
    """Get alerts for a device"""
    try:
        # Get query parameters
        limit = request.args.get('limit', 50, type=int)
        acknowledged = request.args.get('acknowledged', type=str)
        
        query = Alert.query.filter_by(device_id=device_id)
        
        if acknowledged is not None:
            ack_bool = acknowledged.lower() == 'true'
            query = query.filter_by(acknowledged=ack_bool)
        
        alerts = query.order_by(Alert.timestamp.desc()).limit(limit).all()
        
        return jsonify([alert.to_dict() for alert in alerts]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/alerts/<int:alert_id>/acknowledge', methods=['POST'])
def acknowledge_alert(alert_id):
    """Acknowledge an alert"""
    try:
        alert = Alert.query.get(alert_id)
        if not alert:
            return jsonify({'error': 'Alert not found'}), 404
        
        alert.acknowledged = True
        db.session.commit()
        
        return jsonify(alert.to_dict()), 200
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/stats/<device_id>', methods=['GET'])
def get_statistics(device_id):
    """Get statistics for a device"""
    try:
        hours = request.args.get('hours', 24, type=int)
        start_time = datetime.utcnow() - timedelta(hours=hours)
        
        readings = SensorReading.query.filter_by(device_id=device_id)\
            .filter(SensorReading.timestamp >= start_time).all()
        
        if not readings:
            return jsonify({'error': 'No data available'}), 404
        
        # Calculate statistics
        ph_values = [r.ph for r in readings if r.ph is not None]
        turbidity_values = [r.turbidity for r in readings if r.turbidity is not None]
        temp_values = [r.temperature for r in readings if r.temperature is not None]
        
        stats = {
            'period_hours': hours,
            'total_readings': len(readings),
            'ph': {
                'avg': sum(ph_values) / len(ph_values) if ph_values else None,
                'min': min(ph_values) if ph_values else None,
                'max': max(ph_values) if ph_values else None
            },
            'turbidity': {
                'avg': sum(turbidity_values) / len(turbidity_values) if turbidity_values else None,
                'min': min(turbidity_values) if turbidity_values else None,
                'max': max(turbidity_values) if turbidity_values else None
            },
            'temperature': {
                'avg': sum(temp_values) / len(temp_values) if temp_values else None,
                'min': min(temp_values) if temp_values else None,
                'max': max(temp_values) if temp_values else None
            }
        }
        
        return jsonify(stats), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


# ==================== CHEMICAL DISPENSER ENDPOINTS ====================

@app.route('/api/dispensing-jobs', methods=['POST'])
def create_chemical_data():
    """Create new chemical dispensing job"""
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Validate required fields
        required_fields = ['device_id', 'hcl', 'soda', 'cl', 'al', 'flag']
        for field in required_fields:
            if field not in data:
                return jsonify({'error': f'Missing required field: {field}'}), 400
        
        chemical_data = ChemicalDispenser(
            device_id=data['device_id'],
            hcl=float(data['hcl']),
            soda=float(data['soda']),
            cl=float(data['cl']),
            al=float(data['al']),
            flag=data['flag'],
            timestamp=datetime.strptime(data['timestamp'], '%Y-%m-%d %H:%M:%S') if 'timestamp' in data else datetime.utcnow()
        )
        
        db.session.add(chemical_data)
        db.session.commit()
        
        return jsonify(chemical_data.to_dict()), 201
    except ValueError as e:
        return jsonify({'error': f'Invalid data format: {str(e)}'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/dispensing-jobs', methods=['GET'])
def get_chemical_data():
    """Get PENDING chemical dispensing jobs"""
    try:
        limit = min(request.args.get('limit', 100, type=int), 100)
        device_id = request.args.get('device_id')
        
        # Base query for PENDING jobs only
        query = ChemicalDispenser.query.filter_by(flag='PENDING')
        
        # Filter by device_id if provided
        if device_id:
            query = query.filter_by(device_id=device_id)
        
        chemical_data = query.order_by(ChemicalDispenser.timestamp.desc()).limit(limit).all()
        
        return jsonify([data.to_dict() for data in chemical_data]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/dispensing-jobs/<int:record_id>', methods=['PUT'])
def update_chemical_data(record_id):
    """Update chemical dispensing job data"""
    try:
        chemical_data = ChemicalDispenser.query.get(record_id)
        if not chemical_data:
            return jsonify({'error': 'Record not found'}), 404
        
        data = request.get_json()
        if not data:
            return jsonify({'error': 'No data provided'}), 400
        
        # Update fields if provided
        if 'device_id' in data:
            chemical_data.device_id = data['device_id']
        if 'hcl' in data:
            chemical_data.hcl = float(data['hcl'])
        if 'soda' in data:
            chemical_data.soda = float(data['soda'])
        if 'cl' in data:
            chemical_data.cl = float(data['cl'])
        if 'al' in data:
            chemical_data.al = float(data['al'])
        if 'flag' in data:
            chemical_data.flag = data['flag']
        if 'timestamp' in data:
            chemical_data.timestamp = datetime.strptime(data['timestamp'], '%Y-%m-%d %H:%M:%S')
        
        db.session.commit()
        
        return jsonify(chemical_data.to_dict()), 200
    except ValueError as e:
        return jsonify({'error': f'Invalid data format: {str(e)}'}), 400
    except Exception as e:
        db.session.rollback()
        return jsonify({'error': str(e)}), 500


@app.route('/api/dispensing-jobs/<device_id>', methods=['GET'])
def get_chemical_data_by_device(device_id):
    """Get chemical dispensing jobs for a specific device"""
    try:
        limit = min(request.args.get('limit', 100, type=int), 100)
        status_filter = request.args.get('status', 'PENDING')  # Default to PENDING, but allow override
        
        # Query for jobs by device_id and status
        query = ChemicalDispenser.query.filter_by(device_id=device_id, flag=status_filter)
        chemical_data = query.order_by(ChemicalDispenser.timestamp.desc()).limit(limit).all()
        
        return jsonify([data.to_dict() for data in chemical_data]), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/dispensing-jobs/all', methods=['GET'])
def get_all_chemical_jobs():
    """Get all chemical dispensing jobs for tracking (including completed ones)"""
    try:
        limit = min(request.args.get('limit', 100, type=int), 500)  # Allow higher limit for tracking
        device_id = request.args.get('device_id')
        status_filter = request.args.get('status')  # Optional status filter
        
        # Base query for all jobs
        query = ChemicalDispenser.query
        
        # Filter by device_id if provided
        if device_id:
            query = query.filter_by(device_id=device_id)
            
        # Filter by status if provided
        if status_filter:
            query = query.filter_by(flag=status_filter)
        
        chemical_data = query.order_by(ChemicalDispenser.timestamp.desc()).limit(limit).all()
        
        return jsonify({
            'total_jobs': len(chemical_data),
            'jobs': [data.to_dict() for data in chemical_data]
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/', methods=['GET'])
def index():
    """API root endpoint"""
    return jsonify({
        'name': 'Pool Water Quality Monitor & Chemical Dispenser API',
        'version': '1.0.0',
        'endpoints': {
            # Authentication
            'register': '/api/auth/register (POST)',
            'login': '/api/auth/login (POST)',
            'profile': '/api/auth/profile (GET/PUT)',
            'change_password': '/api/auth/change-password (PUT)',
            'users': '/api/users (GET - Admin only)',
            # Device endpoints
            'device_data': '/pool/data (POST)',
            'device_config': '/pool/config (GET)',
            'devices': '/api/devices (GET)',
            'device_readings': '/api/devices/<device_id>/readings (GET)',
            'create_config': '/api/devices/<device_id>/config (POST)',
            # Chemical dispensing jobs
            'dispensing_jobs_create': '/api/dispensing-jobs (POST)',
            'dispensing_jobs_pending': '/api/dispensing-jobs (GET) - supports ?device_id=<id>',
            'dispensing_jobs_by_device': '/api/dispensing-jobs/<device_id> (GET) - device specific',
            'dispensing_jobs_all_tracking': '/api/dispensing-jobs/all (GET)',
            'dispensing_jobs_update': '/api/dispensing-jobs/<id> (PUT)'
        }
    }), 200


# ==================== DATABASE INITIALIZATION ====================

@app.before_request
def create_tables():
    """Create database tables before first request"""
    db.create_all()


if __name__ == '__main__':
    with app.app_context():
        db.create_all()
        print("Database tables created successfully!")
    
    # Run the app
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('DEBUG', 'False').lower() == 'true'
    
    print(f"\n=== Pool Monitor API Server ===")
    print(f"Running on port {port}")
    print(f"Debug mode: {debug}\n")
    
    app.run(host='0.0.0.0', port=port, debug=debug)