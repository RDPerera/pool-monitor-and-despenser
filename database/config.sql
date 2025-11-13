-- =====================================================
-- Pool Water Quality Monitor Database Schema
-- =====================================================
-- Compatible with PostgreSQL, MySQL, and SQLite
-- For production, use PostgreSQL for better performance
-- =====================================================

-- Drop existing tables (if recreating)
DROP TABLE IF EXISTS alerts;
DROP TABLE IF EXISTS sensor_readings;
DROP TABLE IF EXISTS device_configs;
DROP TABLE IF EXISTS devices;

-- =====================================================
-- DEVICES TABLE
-- =====================================================
CREATE TABLE devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,  -- Use AUTO_INCREMENT for MySQL
    device_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) DEFAULT 'Pool Monitor',
    location VARCHAR(200),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Indexes for performance
    CONSTRAINT unique_device_id UNIQUE (device_id)
);

CREATE INDEX idx_devices_device_id ON devices(device_id);
CREATE INDEX idx_devices_last_seen ON devices(last_seen);

-- =====================================================
-- DEVICE CONFIGURATIONS TABLE
-- =====================================================
CREATE TABLE device_configs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id VARCHAR(50) UNIQUE NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Calibration values
    ph_offset REAL DEFAULT 0.0,
    ph_slope REAL DEFAULT 1.0,
    turbidity_offset REAL DEFAULT 0.0,
    turbidity_slope REAL DEFAULT 1.0,
    temp_offset REAL DEFAULT 0.0,
    
    -- pH Thresholds
    ph_optimal REAL DEFAULT 7.4,
    ph_acceptable REAL DEFAULT 7.8,
    ph_critical REAL DEFAULT 8.5,
    
    -- Turbidity Thresholds (NTU)
    turbidity_optimal REAL DEFAULT 5.0,
    turbidity_acceptable REAL DEFAULT 20.0,
    turbidity_critical REAL DEFAULT 50.0,
    
    -- Temperature Thresholds (°C)
    temp_optimal REAL DEFAULT 26.0,
    temp_acceptable REAL DEFAULT 30.0,
    temp_critical REAL DEFAULT 33.0,
    
    -- Intervals (milliseconds)
    post_interval INTEGER DEFAULT 1000,
    config_interval INTEGER DEFAULT 60000,
    
    -- Foreign key constraint
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE,
    CONSTRAINT unique_config_device UNIQUE (device_id)
);

CREATE INDEX idx_device_configs_device_id ON device_configs(device_id);

-- =====================================================
-- SENSOR READINGS TABLE
-- =====================================================
CREATE TABLE sensor_readings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Sensor values
    ph REAL,
    turbidity REAL,
    temperature REAL,
    
    -- Status information
    water_quality VARCHAR(20),  -- 'optimal', 'acceptable', 'critical'
    wifi_rssi INTEGER,
    uptime INTEGER,
    
    -- Foreign key constraint
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

CREATE INDEX idx_readings_device_id ON sensor_readings(device_id);
CREATE INDEX idx_readings_timestamp ON sensor_readings(timestamp);
CREATE INDEX idx_readings_device_timestamp ON sensor_readings(device_id, timestamp);
CREATE INDEX idx_readings_water_quality ON sensor_readings(water_quality);

-- =====================================================
-- ALERTS TABLE
-- =====================================================
CREATE TABLE alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alert_type VARCHAR(50),  -- 'ph_critical', 'turbidity_critical', 'temp_critical'
    severity VARCHAR(20),    -- 'warning', 'critical'
    message VARCHAR(500),
    value REAL,
    acknowledged BOOLEAN DEFAULT 0,  -- Use FALSE for PostgreSQL
    
    -- Foreign key constraint
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

CREATE INDEX idx_alerts_device_id ON alerts(device_id);
CREATE INDEX idx_alerts_timestamp ON alerts(timestamp);
CREATE INDEX idx_alerts_acknowledged ON alerts(acknowledged);
CREATE INDEX idx_alerts_device_acknowledged ON alerts(device_id, acknowledged);

-- =====================================================
-- SAMPLE DATA (Optional - for testing)
-- =====================================================

-- Insert a test device
INSERT INTO devices (device_id, name, location) 
VALUES ('AABBCCDDEEFF', 'Main Pool Monitor', 'Backyard Pool');

-- Insert default configuration for test device
INSERT INTO device_configs (device_id) 
VALUES ('AABBCCDDEEFF');

-- Insert sample readings
INSERT INTO sensor_readings (device_id, ph, turbidity, temperature, water_quality, wifi_rssi, uptime)
VALUES 
    ('AABBCCDDEEFF', 7.2, 3.5, 25.8, 'optimal', -65, 3600),
    ('AABBCCDDEEFF', 7.3, 4.2, 26.1, 'optimal', -67, 3700),
    ('AABBCCDDEEFF', 7.5, 5.8, 26.5, 'acceptable', -65, 3800);

-- =====================================================
-- POSTGRESQL SPECIFIC MODIFICATIONS
-- =====================================================
-- If using PostgreSQL, replace the above with:
/*

-- Use SERIAL instead of AUTOINCREMENT
CREATE TABLE devices (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) DEFAULT 'Pool Monitor',
    location VARCHAR(200),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE device_configs (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) UNIQUE NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Calibration values
    ph_offset REAL DEFAULT 0.0,
    ph_slope REAL DEFAULT 1.0,
    turbidity_offset REAL DEFAULT 0.0,
    turbidity_slope REAL DEFAULT 1.0,
    temp_offset REAL DEFAULT 0.0,
    
    -- pH Thresholds
    ph_optimal REAL DEFAULT 7.4,
    ph_acceptable REAL DEFAULT 7.8,
    ph_critical REAL DEFAULT 8.5,
    
    -- Turbidity Thresholds
    turbidity_optimal REAL DEFAULT 5.0,
    turbidity_acceptable REAL DEFAULT 20.0,
    turbidity_critical REAL DEFAULT 50.0,
    
    -- Temperature Thresholds
    temp_optimal REAL DEFAULT 26.0,
    temp_acceptable REAL DEFAULT 30.0,
    temp_critical REAL DEFAULT 33.0,
    
    -- Intervals
    post_interval INTEGER DEFAULT 1000,
    config_interval INTEGER DEFAULT 60000,
    
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

CREATE TABLE sensor_readings (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    ph REAL,
    turbidity REAL,
    temperature REAL,
    
    water_quality VARCHAR(20),
    wifi_rssi INTEGER,
    uptime INTEGER,
    
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

CREATE TABLE alerts (
    id SERIAL PRIMARY KEY,
    device_id VARCHAR(50) NOT NULL,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    alert_type VARCHAR(50),
    severity VARCHAR(20),
    message VARCHAR(500),
    value REAL,
    acknowledged BOOLEAN DEFAULT FALSE,
    
    FOREIGN KEY (device_id) REFERENCES devices(device_id) ON DELETE CASCADE
);

-- Same indexes as above...

*/

-- =====================================================
-- MYSQL SPECIFIC MODIFICATIONS
-- =====================================================
-- If using MySQL, replace AUTOINCREMENT with AUTO_INCREMENT
-- and use ENGINE=InnoDB for foreign key support
/*

CREATE TABLE devices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    device_id VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(100) DEFAULT 'Pool Monitor',
    location VARCHAR(200),
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_device_id (device_id),
    INDEX idx_last_seen (last_seen)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Similar modifications for other tables...

*/

-- =====================================================
-- USEFUL QUERIES
-- =====================================================

-- Get latest reading for each device
-- SELECT d.device_id, d.name, sr.* 
-- FROM devices d
-- LEFT JOIN sensor_readings sr ON d.device_id = sr.device_id
-- WHERE sr.id = (
--     SELECT id FROM sensor_readings 
--     WHERE device_id = d.device_id 
--     ORDER BY timestamp DESC LIMIT 1
-- );

-- Get unacknowledged critical alerts
-- SELECT a.*, d.name 
-- FROM alerts a
-- JOIN devices d ON a.device_id = d.device_id
-- WHERE a.acknowledged = 0 AND a.severity = 'critical'
-- ORDER BY a.timestamp DESC;

-- Get average readings for last 24 hours
-- SELECT 
--     device_id,
--     AVG(ph) as avg_ph,
--     AVG(turbidity) as avg_turbidity,
--     AVG(temperature) as avg_temperature,
--     COUNT(*) as reading_count
-- FROM sensor_readings
-- WHERE timestamp >= datetime('now', '-24 hours')
-- GROUP BY device_id;

-- Clean up old readings (keep last 30 days)
-- DELETE FROM sensor_readings 
-- WHERE timestamp < datetime('now', '-30 days');

-- =====================================================
-- VIEWS (Optional - for easier querying)
-- =====================================================

CREATE VIEW latest_readings AS
SELECT 
    d.device_id,
    d.name,
    d.location,
    sr.timestamp,
    sr.ph,
    sr.turbidity,
    sr.temperature,
    sr.water_quality,
    sr.wifi_rssi
FROM devices d
LEFT JOIN sensor_readings sr ON d.device_id = sr.device_id
WHERE sr.id = (
    SELECT id FROM sensor_readings 
    WHERE device_id = d.device_id 
    ORDER BY timestamp DESC LIMIT 1
);

CREATE VIEW active_alerts AS
SELECT 
    a.*,
    d.name as device_name,
    d.location as device_location
FROM alerts a
JOIN devices d ON a.device_id = d.device_id
WHERE a.acknowledged = 0
ORDER BY a.timestamp DESC;

-- =====================================================
-- TRIGGERS (Optional - for auto-updating timestamps)
-- =====================================================

-- SQLite trigger to update device last_seen
CREATE TRIGGER update_device_last_seen
AFTER INSERT ON sensor_readings
BEGIN
    UPDATE devices 
    SET last_seen = CURRENT_TIMESTAMP 
    WHERE device_id = NEW.device_id;
END;

-- SQLite trigger to update config updated_at
CREATE TRIGGER update_config_timestamp
AFTER UPDATE ON device_configs
BEGIN
    UPDATE device_configs 
    SET updated_at = CURRENT_TIMESTAMP 
    WHERE id = NEW.id;
END;

-- =====================================================
-- MAINTENANCE PROCEDURES
-- =====================================================

-- Create a cleanup procedure (for PostgreSQL)
/*
CREATE OR REPLACE FUNCTION cleanup_old_data(days_to_keep INTEGER)
RETURNS void AS $$
BEGIN
    DELETE FROM sensor_readings 
    WHERE timestamp < NOW() - INTERVAL '1 day' * days_to_keep;
    
    DELETE FROM alerts 
    WHERE acknowledged = TRUE 
    AND timestamp < NOW() - INTERVAL '1 day' * days_to_keep;
END;
$$ LANGUAGE plpgsql;

-- Run cleanup: SELECT cleanup_old_data(30);
*/

-- =====================================================
-- END OF SCHEMA
-- =====================================================