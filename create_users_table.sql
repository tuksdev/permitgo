-- Create users table for permitgo database
USE permitgo;

CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert a test user (password: test123)
INSERT INTO users (user_id, email, first_name, last_name, password_hash) 
VALUES (
    '1',
    'test@example.com',
    'Test',
    'User',
    'scrypt:32768:8:1$EKZJwCHXyPhWRSJe$d8c6c6f4c3e8c8b3c5a0d0f0c0e5d9b0a5c0f5e0a5c0f5e0a5c0f5e0a5c0f5e0a5c0f5e0a5c0f5e0a5c0f5e0a5c0f5e0'
)
ON DUPLICATE KEY UPDATE email=email;
