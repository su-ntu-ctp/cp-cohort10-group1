#!/bin/bash

# Autoscaling Test Script for ShopBot ECS Service
# Tests load generation and monitors container scaling

set -e

# Configuration
SERVICE_NAME="shopbot-service-dev"
CLUSTER_NAME="shopbot-ecs"
TARGET_URL="https://dev-shopbot.sctp-sandbox.com"
REGION="ap-southeast-1"
TEST_DURATION=120  # 5 minutes
LOAD_CONNECTIONS=50

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    if ! command -v aws &> /dev/null; then
        error "AWS CLI not found. Please install AWS CLI."
        exit 1
    fi
    
    if ! command -v curl &> /dev/null; then
        error "curl not found. Please install curl."
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        error "AWS credentials not configured. Run 'aws configure'."
        exit 1
    fi
    
    success "Prerequisites check passed"
}

# Get current container count
get_container_count() {
    aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION" \
        --query 'services[0].runningCount' \
        --output text 2>/dev/null || echo "0"
}

# Get desired container count
get_desired_count() {
    aws ecs describe-services \
        --cluster "$CLUSTER_NAME" \
        --services "$SERVICE_NAME" \
        --region "$REGION" \
        --query 'services[0].desiredCount' \
        --output text 2>/dev/null || echo "0"
}

# Get CPU utilization
get_cpu_utilization() {
    aws cloudwatch get-metric-statistics \
        --namespace AWS/ECS \
        --metric-name CPUUtilization \
        --dimensions Name=ServiceName,Value="$SERVICE_NAME" Name=ClusterName,Value="$CLUSTER_NAME" \
        --start-time "$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S)" \
        --end-time "$(date -u +%Y-%m-%dT%H:%M:%S)" \
        --period 60 \
        --statistics Average \
        --region "$REGION" \
        --query 'Datapoints[-1].Average' \
        --output text 2>/dev/null || echo "0"
}

# Monitor containers in background
monitor_containers() {
    local log_file="$1"
    local start_time=$(date +%s)
    
    while true; do
        local current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
        local running_count=$(get_container_count)
        local desired_count=$(get_desired_count)
        local cpu_util=$(get_cpu_utilization)
        
        echo "$(date '+%Y-%m-%d %H:%M:%S'),$elapsed,$running_count,$desired_count,$cpu_util" >> "$log_file"
        sleep 10
    done
}

# Generate load using multiple methods
generate_load() {
    log "Starting load generation..."
    
    # Method 1: Stress endpoint (CPU intensive)
    for i in {1..10}; do
        curl -s "$TARGET_URL/stress?duration=20000" > /dev/null &
    done
    
    # Method 2: Regular endpoints with high concurrency
    for i in {1..20}; do
        (
            while true; do
                curl -s "$TARGET_URL/" > /dev/null
                curl -s "$TARGET_URL/products" > /dev/null
                curl -s "$TARGET_URL/products/1" > /dev/null
                curl -s "$TARGET_URL/cart" > /dev/null
                sleep 0.1
            done
        ) &
    done
    
    # Method 3: Autocannon load test (if available)
    if command -v npx &> /dev/null; then
        npx autocannon \
            --connections $LOAD_CONNECTIONS \
            --duration $TEST_DURATION \
            "$TARGET_URL" > /dev/null 2>&1 &
    fi
    
    success "Load generation started"
}

# Stop all background processes
cleanup() {
    log "Cleaning up background processes..."
    jobs -p | xargs -r kill 2>/dev/null || true
    success "Cleanup completed"
}

# Main autoscaling test
run_autoscaling_test() {
    local test_name="autoscaling-test-$(date +%Y%m%d-%H%M%S)"
    local log_file="${test_name}.csv"
    
    log "Starting autoscaling test: $test_name"
    log "Target URL: $TARGET_URL"
    log "Test duration: ${TEST_DURATION}s"
    log "Load connections: $LOAD_CONNECTIONS"
    
    # Create CSV header
    echo "timestamp,elapsed_seconds,running_count,desired_count,cpu_utilization" > "$log_file"
    
    # Get initial state
    local initial_count=$(get_container_count)
    log "Initial container count: $initial_count"
    
    # Start monitoring in background
    monitor_containers "$log_file" &
    local monitor_pid=$!
    
    # Generate load
    generate_load
    
    # Wait and monitor
    local start_time=$(date +%s)
    local scale_up_detected=false
    local scale_down_detected=false
    local max_containers=$initial_count
    
    while [ $(($(date +%s) - start_time)) -lt $TEST_DURATION ]; do
        local current_count=$(get_container_count)
        local desired_count=$(get_desired_count)
        local cpu_util=$(get_cpu_utilization)
        
        # Track maximum containers
        if [ "$current_count" -gt "$max_containers" ]; then
            max_containers=$current_count
        fi
        
        # Detect scale up
        if [ "$current_count" -gt "$initial_count" ] && [ "$scale_up_detected" = false ]; then
            success "Scale UP detected! Containers: $initial_count → $current_count"
            scale_up_detected=true
        fi
        
        # Display current status
        printf "\r${BLUE}Running: %d | Desired: %d | CPU: %.1f%% | Elapsed: %ds${NC}" \
            "$current_count" "$desired_count" "$cpu_util" $(($(date +%s) - start_time))
        
        sleep 5
    done
    echo
    
    # Stop load generation
    cleanup
    
    # Wait for scale down (additional 10 minutes)
    log "Waiting for scale down (10 minutes)..."
    local scale_down_start=$(date +%s)
    
    while [ $(($(date +%s) - scale_down_start)) -lt 600 ]; do
        local current_count=$(get_container_count)
        local desired_count=$(get_desired_count)
        
        # Detect scale down
        if [ "$current_count" -lt "$max_containers" ] && [ "$scale_down_detected" = false ]; then
            success "Scale DOWN detected! Containers: $max_containers → $current_count"
            scale_down_detected=true
        fi
        
        printf "\r${YELLOW}Cooldown: Running: %d | Desired: %d | Elapsed: %ds${NC}" \
            "$current_count" "$desired_count" $(($(date +%s) - scale_down_start))
        
        sleep 10
    done
    echo
    
    # Stop monitoring
    kill $monitor_pid 2>/dev/null || true
    
    # Final results
    local final_count=$(get_container_count)
    
    echo
    log "=== AUTOSCALING TEST RESULTS ==="
    echo "Test Duration: ${TEST_DURATION}s + 600s cooldown"
    echo "Initial Containers: $initial_count"
    echo "Maximum Containers: $max_containers"
    echo "Final Containers: $final_count"
    echo "Scale Up Detected: $scale_up_detected"
    echo "Scale Down Detected: $scale_down_detected"
    echo "Log File: $log_file"
    
    # Generate summary report
    generate_report "$log_file" "$test_name"
}

# Generate detailed report
generate_report() {
    local log_file="$1"
    local test_name="$2"
    local report_file="${test_name}-report.txt"
    
    log "Generating detailed report..."
    
    {
        echo "ShopBot Autoscaling Test Report"
        echo "==============================="
        echo "Test: $test_name"
        echo "Date: $(date)"
        echo "Target: $TARGET_URL"
        echo
        
        # Statistics from CSV
        if [ -f "$log_file" ]; then
            echo "Container Count Statistics:"
            echo "- Min: $(tail -n +2 "$log_file" | cut -d',' -f3 | sort -n | head -1)"
            echo "- Max: $(tail -n +2 "$log_file" | cut -d',' -f3 | sort -n | tail -1)"
            echo "- Avg: $(tail -n +2 "$log_file" | cut -d',' -f3 | awk '{sum+=$1} END {printf "%.1f", sum/NR}')"
            echo
            
            echo "CPU Utilization Statistics:"
            echo "- Min: $(tail -n +2 "$log_file" | cut -d',' -f5 | sort -n | head -1)%"
            echo "- Max: $(tail -n +2 "$log_file" | cut -d',' -f5 | sort -n | tail -1)%"
            echo "- Avg: $(tail -n +2 "$log_file" | cut -d',' -f5 | awk '{sum+=$1} END {printf "%.1f", sum/NR}')%"
            echo
            
            echo "Timeline (last 10 entries):"
            echo "Time,Elapsed,Running,Desired,CPU%"
            tail -10 "$log_file"
        fi
        
    } > "$report_file"
    
    success "Report saved to: $report_file"
}

# Quick status check
check_status() {
    log "Current ECS Service Status:"
    echo "Service: $SERVICE_NAME"
    echo "Cluster: $CLUSTER_NAME"
    echo "Running Containers: $(get_container_count)"
    echo "Desired Containers: $(get_desired_count)"
    echo "CPU Utilization: $(get_cpu_utilization)%"
}

# Show usage
usage() {
    echo "Usage: $0 [COMMAND]"
    echo
    echo "Commands:"
    echo "  test      Run full autoscaling test (default)"
    echo "  status    Show current service status"
    echo "  monitor   Monitor containers continuously"
    echo "  load      Generate load only"
    echo "  help      Show this help"
    echo
    echo "Environment Variables:"
    echo "  SERVICE_NAME      ECS service name (default: shopbot-service-dev)"
    echo "  CLUSTER_NAME      ECS cluster name (default: shopbot-ecs)"
    echo "  TARGET_URL        Application URL (default: https://dev-shopbot.sctp-sandbox.com)"
    echo "  TEST_DURATION     Test duration in seconds (default: 300)"
    echo "  LOAD_CONNECTIONS  Load test connections (default: 50)"
}

# Continuous monitoring
continuous_monitor() {
    log "Starting continuous monitoring (Ctrl+C to stop)..."
    echo "Time,Running,Desired,CPU%"
    
    while true; do
        local running=$(get_container_count)
        local desired=$(get_desired_count)
        local cpu=$(get_cpu_utilization)
        
        printf "%s,%d,%d,%.1f%%\n" "$(date '+%H:%M:%S')" "$running" "$desired" "$cpu"
        sleep 10
    done
}

# Main script
main() {
    trap cleanup EXIT
    
    case "${1:-test}" in
        "test")
            check_prerequisites
            run_autoscaling_test
            ;;
        "status")
            check_prerequisites
            check_status
            ;;
        "monitor")
            check_prerequisites
            continuous_monitor
            ;;
        "load")
            check_prerequisites
            generate_load
            log "Load generation started. Press Ctrl+C to stop."
            wait
            ;;
        "help"|"-h"|"--help")
            usage
            ;;
        *)
            error "Unknown command: $1"
            usage
            exit 1
            ;;
    esac
}

main "$@"
