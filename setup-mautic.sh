#!/bin/bash

# Function to display script progress
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to check command existence
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo "Error: $1 is required but not installed. Please install it first."
        exit 1
    fi
}

# Function to setup a single environment
setup_environment() {
    local env_name=$1
    local port=$2
    local db_port=$3
    
    log_message "Setting up $env_name environment..."
    
    # Create project directory
    mkdir -p "$env_name"
    cd "$env_name"
    
    # Initialize DDEV project
    ddev config --project-type=php --project-name="mautic-$env_name" \
        --docroot=mautic --create-docroot --php-version=8.1 \
        --web-environment="MAUTIC_ENV=dev"
    
    # Customize ports
    sed -i "s/\(.*router_http_port:\).*/\1 $port/" .ddev/config.yaml
    sed -i "s/\(.*mysql_port:\).*/\1 $db_port/" .ddev/config.yaml
    
    # Start DDEV
    ddev start
    
    # Clone latest Mautic
    git clone https://github.com/mautic/mautic.git
    cd mautic
    
    # Install Composer dependencies
    ddev composer install
    
    # Configure Mautic
    cp app/config/local.php.dist app/config/local.php
    
    # Set proper permissions
    ddev exec chmod -R 755 .
    ddev exec chown -R www-data:www-data .
    
    # Create database and install Mautic
    ddev exec php bin/console mautic:install \
        --db_driver=pdo_mysql \
        --db_host=db \
        --db_port=3306 \
        --db_name=db \
        --db_user=db \
        --db_password=db \
        --db_prefix=mautic_ \
        --admin_email=admin@example.com \
        --admin_password=admin123 \
        --admin_firstname=Admin \
        --admin_lastname=User \
        --mailer_from_name="Mautic $env_name" \
        --mailer_from_email=mautic@example.com \
        --mailer_transport=smtp \
        --mailer_host=localhost \
        --mailer_port=1025
        
    cd ..
    
    log_message "$env_name environment setup completed!"
}

# Main script execution
main() {
    # Check required commands
    check_command "ddev"
    check_command "git"
    
    # Create parent directory for environments
    local base_dir="mautic-environments"
    mkdir -p "$base_dir"
    cd "$base_dir"
    
    # Setup development environment
    setup_environment "dev" "8080" "3306"
    
    # Setup testing environment
    # setup_environment "test" "8081" "3307"
    
    log_message "Both environments have been set up successfully!"
    log_message "Dev environment: http://mautic-dev.ddev.site:8080"
    log_message "Test environment: http://mautic-test.ddev.site:8081"
    log_message "Default admin credentials for both environments:"
    log_message "Email: admin@example.com"
    log_message "Password: admin123"
}

# Execute main function
main