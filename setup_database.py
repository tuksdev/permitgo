import pymysql
from werkzeug.security import generate_password_hash

# Connect to database
conn = pymysql.connect(
    host='localhost',
    user='root',
    password='1234',
    database='permitgo'
)

cursor = conn.cursor()

# Create users table
create_table_query = """
CREATE TABLE IF NOT EXISTS users (
    user_id VARCHAR(50) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    mobile_number VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
)
"""

cursor.execute(create_table_query)
print("✅ Users table created successfully!")

# Create a test user
test_password = generate_password_hash('test123')
insert_user_query = """
INSERT INTO users (user_id, email, first_name, last_name, password_hash, mobile_number)
VALUES (%s, %s, %s, %s, %s, %s)
ON DUPLICATE KEY UPDATE email=email
"""

cursor.execute(insert_user_query, ('1', 'test@example.com', 'Test', 'User', test_password, '09123456789'))
conn.commit()
print("✅ Test user created successfully!")
print("   Email: test@example.com")
print("   Password: test123")

cursor.close()
conn.close()

print("\n✅ Database setup complete! You can now sign in with the test account.")
