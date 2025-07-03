#!/bin/bash
# Database initialization script for dgamelaunch SQLite database

set -e

DB_PATH="/opt/dgl/chroot/dgldir/dgl-login.db"
DB_USER="nethack"
DB_GROUP="games"

echo "Initializing dgamelaunch SQLite database..."

# Remove any existing empty database file
if [ -f "$DB_PATH" ] && [ ! -s "$DB_PATH" ]; then
    echo "Removing empty database file..."
    rm "$DB_PATH"
fi

# Create database with proper schema if it doesn't exist
if [ ! -f "$DB_PATH" ]; then
    echo "Creating new database with schema..."
    
    # Create the database with the schema dgamelaunch expects
    sqlite3 "$DB_PATH" <<EOF
CREATE TABLE dglusers (
    id INTEGER PRIMARY KEY,
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(254),
    env VARCHAR(1024),
    password VARCHAR(60),
    flags INTEGER
);
EOF
    
    echo "Database schema created successfully."
else
    echo "Database already exists, checking schema..."
    
    # Check if the required table exists
    TABLES=$(sqlite3 "$DB_PATH" ".tables")
    if [[ ! "$TABLES" =~ "dglusers" ]]; then
        echo "Warning: dglusers table not found, recreating database..."
        rm "$DB_PATH"
        sqlite3 "$DB_PATH" <<EOF
CREATE TABLE dglusers (
    id INTEGER PRIMARY KEY,
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(254),
    env VARCHAR(1024),
    password VARCHAR(60),
    flags INTEGER
);
EOF
        echo "Database schema recreated."
    else
        echo "Database schema is valid."
    fi
fi

# Set correct ownership and permissions
echo "Setting database permissions..."
chown "$DB_USER:$DB_GROUP" "$DB_PATH"
chmod 664 "$DB_PATH"

# Verify the setup
echo "Verifying database setup..."
ls -la "$DB_PATH"
sqlite3 "$DB_PATH" ".schema"

echo "Database initialization complete!"
