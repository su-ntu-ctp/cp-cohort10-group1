#!/bin/bash

# Enhanced Autoscaling Test Script with Sustained Load
set -e

# Configuration
SERVICE_NAME="shopbot-app-staging"  # Updated for staging
CLUSTER_NAME="shopbot-ecs-staging"
TARGET_URL="https://staging-shopbot.sctp-sandbox.com"
REGION="ap-southeast-1"
TEST_DURATION=600  # 10 minutes for sustained load
LOAD_CONNECTIONS=30

# Generate sustained consistent load
generate_sustained_load() {
    log "Starting sustained load generation..."
    
    # Method 1: Continuous stress endpoint calls
    for i in {1..15}; do
        (
            while true; do
                curl -s "$TARGET_URL/stress?duration=30000" > /dev/null 2>&1
                sleep 2  # Brief pause between stress calls
            done
        ) &
    done
    
    # Method 2: Continuous regular endpoint bombardment
    for i in {1..25}; do
        (
            while true; do
                curl -s "$TARGET_URL/" > /dev/null 2>&1
                curl -s "$TARGET_URL/products" > /dev/null 2>&1
                curl -s "$TARGET_URL/products/1" > /dev/null 2>&1
                curl -s "$TARGET_URL/cart" > /dev/null 2>&1
                curl -s "$TARGET_URL/health" > /dev/null 2>&1
                sleep 0.05  # Very short pause for sustained load
            done
        ) &
    done
    
    # Method 3: Artillery-style load (if available)
    if command -v npx &> /dev/null; then
        npx autocannon \
            --connections $LOAD_CONNECTIONS \
            --duration $TEST_DURATION \
            --rate 100 \
            "$TARGET_URL" > /dev/null 2>&1 &
    fi
    
    success "Sustained load generation started - will maintain for ${TEST_DURATION}s"
}

# Enhanced monitoring
