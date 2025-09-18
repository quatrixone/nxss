#!/bin/bash

# NXSS Server Docker Build Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available. Please install Docker Compose first."
        exit 1
    fi
}

# Create necessary directories
create_directories() {
    log_info "Creating necessary directories..."
    mkdir -p storage_data config tmp_uploads ssl
    chmod 755 storage_data config tmp_uploads ssl
    log_success "Directories created successfully"
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    docker build -t nxss-server:latest .
    log_success "Docker image built successfully"
}

# Start services
start_services() {
    log_info "Starting services..."
    docker compose up -d
    log_success "Services started successfully"
}

# Stop services
stop_services() {
    log_info "Stopping services..."
    docker compose down
    log_success "Services stopped successfully"
}

# Restart services
restart_services() {
    log_info "Restarting services..."
    docker compose restart
    log_success "Services restarted successfully"
}

# Show logs
show_logs() {
    log_info "Showing logs..."
    docker compose logs -f
}

# Check health
check_health() {
    log_info "Checking server health..."
    sleep 5
    if curl -s http://localhost:8080/health > /dev/null; then
        log_success "Server is healthy and running"
    else
        log_error "Server is not responding"
        exit 1
    fi
}

# Clean up
cleanup() {
    log_info "Cleaning up Docker resources..."
    docker compose down
    docker system prune -f
    log_success "Cleanup completed"
}

# Show help
show_help() {
    echo "NXSS Server Docker Management Script"
    echo ""
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build     Build Docker image"
    echo "  start     Start services"
    echo "  stop      Stop services"
    echo "  restart   Restart services"
    echo "  logs      Show logs"
    echo "  health    Check server health"
    echo "  cleanup   Clean up Docker resources"
    echo "  full      Full setup (build + start + health check)"
    echo "  help      Show this help message"
    echo ""
}

# Main script
main() {
    case "${1:-help}" in
        "build")
            check_docker
            create_directories
            build_image
            ;;
        "start")
            check_docker
            create_directories
            start_services
            check_health
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            check_health
            ;;
        "logs")
            show_logs
            ;;
        "health")
            check_health
            ;;
        "cleanup")
            cleanup
            ;;
        "full")
            check_docker
            create_directories
            build_image
            start_services
            check_health
            log_success "Full setup completed! Server is running at http://localhost:8080"
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
