#!/bin/bash
# scripts/simulate-traffic.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
TRAFFIC_TYPE="benign"
DURATION=300  # 5 minutes default
INTENSITY="normal"
USERS_FILE="/tmp/simulation_users.json"
LOG_FILE="/tmp/traffic_simulation.log"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_section() {
    echo -e "${BLUE}--------------------------------${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}--------------------------------${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -t, --type TYPE        Traffic type: benign, malicious, mixed (default: benign)"
    echo "  -d, --duration SECONDS Duration in seconds (default: 300)"
    echo "  -i, --intensity LEVEL  Intensity: low, normal, high (default: normal)"
    echo "  -u, --users FILE       Users file path (default: /tmp/simulation_users.json)"
    echo "  -l, --log FILE         Log file path (default: /tmp/traffic_simulation.log)"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --type benign --duration 600 --intensity normal"
    echo "  $0 --type malicious --duration 120 --intensity high"
    echo "  $0 --type mixed --duration 900 --intensity low"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            TRAFFIC_TYPE="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -i|--intensity)
            INTENSITY="$2"
            shift 2
            ;;
        -u|--users)
            USERS_FILE="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
            shift 2
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate inputs
if [[ ! "$TRAFFIC_TYPE" =~ ^(benign|malicious|mixed)$ ]]; then
    print_error "Invalid traffic type: $TRAFFIC_TYPE. Must be benign, malicious, or mixed"
    exit 1
fi

if [[ ! "$INTENSITY" =~ ^(low|normal|high)$ ]]; then
    print_error "Invalid intensity: $INTENSITY. Must be low, normal, or high"
    exit 1
fi

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    print_error "Duration must be a positive integer"
    exit 1
fi

# Function to get random user credentials
get_random_user() {
    if [ -f "$USERS_FILE" ]; then
        local users_count=$(jq '.users | length' "$USERS_FILE" 2>/dev/null)
        if [ "$users_count" -gt 0 ] 2>/dev/null; then
            local random_index=$((RANDOM % users_count))
            local user=$(jq -r ".users[$random_index]" "$USERS_FILE" 2>/dev/null)
            echo "$user"
        else
            # Fallback if users file is empty or malformed
            local users=("admin:adminpass" "user:userpass")
            local random_index=$((RANDOM % ${#users[@]}))
            echo "${users[$random_index]}"
        fi
    else
        # Fallback to default users
        local users=("admin:adminpass" "user:userpass")
        local random_index=$((RANDOM % ${#users[@]}))
        echo "${users[$random_index]}"
    fi
}

# Function to get access token
get_access_token() {
    local username="$1"
    local password="$2"
    
    local token=$(curl -s -X POST \
        --max-time 10 \
        --connect-timeout 5 \
        "http://localhost:8080/realms/zero-trust/protocol/openid-connect/token" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "username=$username" \
        -d "password=$password" \
        -d "grant_type=password" \
        -d "client_id=myapp" \
        -d "client_secret=EJO8EHORKiNmG6dQx3SFFoL7GwZChSOa" 2>/dev/null | jq -r '.access_token // empty' 2>/dev/null)
    
    echo "$token"
}

# Function to make API request
make_api_request() {
    local method="$1"
    local endpoint="$2"
    local token="$3"
    local data="$4"
    local malicious="$5"
    
    local headers=(
        "-H" "Authorization: Bearer $token"
        "-H" "Content-Type: application/json"
        "-H" "X-Request-ID: $(uuidgen 2>/dev/null || echo "req-$RANDOM")"
    )
    
    local curl_opts=(
        "-s"
        "-w" "%{http_code}"
        "--max-time" "10"
        "--connect-timeout" "5"
    )
    
    local response=""
    if [ "$method" = "GET" ]; then
        response=$(curl "${curl_opts[@]}" "${headers[@]}" "http://localhost:4000$endpoint" 2>/dev/null || echo "000:")
    elif [ "$method" = "POST" ]; then
        response=$(curl "${curl_opts[@]}" "${headers[@]}" -X POST -d "$data" "http://localhost:4000$endpoint" 2>/dev/null || echo "000:")
    elif [ "$method" = "PUT" ]; then
        response=$(curl "${curl_opts[@]}" "${headers[@]}" -X PUT -d "$data" "http://localhost:4000$endpoint" 2>/dev/null || echo "000:")
    elif [ "$method" = "DELETE" ]; then
        response=$(curl "${curl_opts[@]}" "${headers[@]}" -X DELETE "http://localhost:4000$endpoint" 2>/dev/null || echo "000:")
    fi
    
    # Extract status code more safely
    local status_code="000"
    if [ ${#response} -ge 3 ]; then
        status_code="${response: -3}"
        local response_body="${response%???}"
    else
        local response_body=""
    fi
    
    echo "$status_code:$response_body"
}

# Function to generate benign traffic
generate_benign_traffic() {
    local user_creds="$1"
    local username=$(echo "$user_creds" | cut -d: -f1)
    local password=$(echo "$user_creds" | cut -d: -f2)
    
    local token=$(get_access_token "$username" "$password")
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        print_warning "Failed to get token for user $username"
        return 1
    fi
    
    # Random benign actions
    local actions=(
        "GET:/api/data"
        "GET:/api/data?page=1&limit=5"
        "GET:/api/data?page=2&limit=10"
        "GET:/health"
        "GET:/metrics"
    )
    
    # Add admin-specific actions if user is admin
    if [ "$username" = "admin" ]; then
        actions+=(
            "GET:/api/admin"
            "GET:/api/admin?page=1&limit=5"
        )
    fi
    
    # Random POST requests for data creation
    if [ $((RANDOM % 10)) -lt 3 ]; then
        local item_names=("Meeting Notes" "Project Update" "Task List" "Report" "Document")
        local item_descriptions=("Important meeting notes from today" "Latest project status update" "Updated task list" "Monthly report" "Important document")
        
        local random_name="${item_names[$((RANDOM % ${#item_names[@]}))]}"
        local random_desc="${item_descriptions[$((RANDOM % ${#item_descriptions[@]}))]}"
        
        local post_data="{\"name\":\"$random_name\",\"description\":\"$random_desc\"}"
        local response=$(make_api_request "POST" "/api/data" "$token" "$post_data" "false")
        
        local status_code=$(echo "$response" | cut -d: -f1)
        if [ "$status_code" = "201" ]; then
            print_status "Created item: $random_name"
        fi
    fi
    
    # Random action
    local random_action="${actions[$((RANDOM % ${#actions[@]}))]}"
    local method=$(echo "$random_action" | cut -d: -f1)
    local endpoint=$(echo "$random_action" | cut -d: -f2)
    
    local response=$(make_api_request "$method" "$endpoint" "$token" "" "false")
    local status_code=$(echo "$response" | cut -d: -f1)
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - BENIGN - $username - $method $endpoint - $status_code" >> "$LOG_FILE"
}

# Function to generate malicious traffic
generate_malicious_traffic() {
    local user_creds="$1"
    local username=$(echo "$user_creds" | cut -d: -f1)
    local password=$(echo "$user_creds" | cut -d: -f2)
    
    local token=$(get_access_token "$username" "$password")
    if [ -z "$token" ] || [ "$token" = "null" ]; then
        print_warning "Failed to get token for user $username"
        return 1
    fi
    
    # Malicious actions
    local malicious_actions=(
        # SQL Injection attempts
        "GET:/api/data?page=1' OR '1'='1"
        "GET:/api/data?page=1; DROP TABLE items;"
        "GET:/api/data?page=1 UNION SELECT * FROM users"
        
        # XSS attempts
        "POST:/api/data:{\"name\":\"<script>alert('xss')</script>\",\"description\":\"XSS test\"}"
        "POST:/api/data:{\"name\":\"javascript:alert('xss')\",\"description\":\"XSS test\"}"
        
        # Path traversal
        "GET:/api/data/../../../etc/passwd"
        "GET:/api/data/..\\..\\..\\windows\\system32\\config\\sam"
        
        # Unauthorized access attempts
        "GET:/api/admin"
        "GET:/api/admin?page=1&limit=100"
        
        # Invalid data
        "POST:/api/data:{\"name\":\"\",\"description\":\"\"}"
        "POST:/api/data:{\"name\":null,\"description\":null}"
        "POST:/api/data:{\"invalid_field\":\"test\"}"
        
        # Rate limiting bypass attempts
        "GET:/api/data"
        "GET:/api/data"
        "GET:/api/data"
        "GET:/api/data"
        "GET:/api/data"
        
        # Invalid endpoints
        "GET:/api/invalid"
        "GET:/admin"
        "GET:/config"
        "GET:/debug"
    )
    
    # Exclude large payload attack as it can cause issues
    # "POST:/api/data:{\"name\":\"$(printf 'A%.0s' {1..10000})\",\"description\":\"Large payload\"}"
    
    local random_action="${malicious_actions[$((RANDOM % ${#malicious_actions[@]}))]}"
    local method=$(echo "$random_action" | cut -d: -f1)
    local endpoint=$(echo "$random_action" | cut -d: -f2)
    local data=""
    
    # Check if there's data part (for POST requests)
    if [[ "$random_action" == *":"* ]] && [[ "$random_action" != *"GET:"* ]]; then
        data=$(echo "$random_action" | cut -d: -f3-)
    fi
    
    local response
    if [ -z "$data" ]; then
        response=$(make_api_request "$method" "$endpoint" "$token" "" "true")
    else
        response=$(make_api_request "$method" "$endpoint" "$token" "$data" "true")
    fi
    
    local status_code=$(echo "$response" | cut -d: -f1)
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - MALICIOUS - $username - $method $endpoint - $status_code" >> "$LOG_FILE"
}

# Function to determine request interval based on intensity
get_request_interval() {
    case "$INTENSITY" in
        "low")
            echo $((5 + RANDOM % 10))  # 5-15 seconds
            ;;
        "normal")
            echo $((2 + RANDOM % 5))   # 2-7 seconds
            ;;
        "high")
            echo $((1 + RANDOM % 3))   # 1-4 seconds
            ;;
    esac
}

# Function to generate mixed traffic
generate_mixed_traffic() {
    local user_creds="$1"
    
    # 70% benign, 30% malicious
    if [ $((RANDOM % 10)) -lt 7 ]; then
        generate_benign_traffic "$user_creds"
    else
        generate_malicious_traffic "$user_creds"
    fi
}

# Main simulation function
run_simulation() {
    print_header "Starting Traffic Simulation"
    print_section "Configuration"
    print_status "Type: $TRAFFIC_TYPE"
    print_status "Duration: $DURATION seconds"
    print_status "Intensity: $INTENSITY"
    print_status "Log file: $LOG_FILE"
    echo ""
    
    # Clear log file
    > "$LOG_FILE"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + DURATION))
    local request_count=0
    
    print_status "Starting simulation at $(date)"
    print_status "Will run until $(date -d @$end_time 2>/dev/null || date -r $end_time 2>/dev/null || echo "end time")"
    echo ""
    
    while [ $(date +%s) -lt $end_time ]; do
        local user_creds=$(get_random_user)
        local username=$(echo "$user_creds" | cut -d: -f1)
        
        case "$TRAFFIC_TYPE" in
            "benign")
                generate_benign_traffic "$user_creds"
                ;;
            "malicious")
                generate_malicious_traffic "$user_creds"
                ;;
            "mixed")
                generate_mixed_traffic "$user_creds"
                ;;
        esac
        
        request_count=$((request_count + 1))
        
        # Progress indicator
        if [ $((request_count % 10)) -eq 0 ]; then
            local elapsed=$(( $(date +%s) - start_time ))
            local remaining=$((end_time - $(date +%s)))
            print_status "Requests: $request_count, Elapsed: ${elapsed}s, Remaining: ${remaining}s"
        fi
        
        # Sleep based on intensity
        local interval=$(get_request_interval)
        sleep "$interval"
    done
    
    print_header "Simulation Complete"
    print_section "Results"
    print_status "Total requests: $request_count"
    print_status "Duration: $DURATION seconds"
    
    # Calculate average RPS with better error handling
    if command -v bc &> /dev/null && [ "$DURATION" -gt 0 ]; then
        local avg_rps=$(echo "scale=2; $request_count / $DURATION" | bc -l 2>/dev/null)
        print_status "Average RPS: $avg_rps"
    else
        local avg_rps=$((request_count / DURATION))
        print_status "Average RPS: $avg_rps (approximate)"
    fi
    
    print_status "Log file: $LOG_FILE"
    
    # Show log summary
    echo ""
    print_section "Log Summary"
    if [ -f "$LOG_FILE" ]; then
        echo "Benign requests: $(grep -c "BENIGN" "$LOG_FILE" 2>/dev/null || echo "0")"
        echo "Malicious requests: $(grep -c "MALICIOUS" "$LOG_FILE" 2>/dev/null || echo "0")"
        echo "Total requests: $(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")"
    else
        echo "Log file not found"
    fi
}

# Check dependencies
check_dependencies() {
    print_section "Checking Dependencies"
    local missing_deps=()
    
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Optional dependencies
    if ! command -v uuidgen &> /dev/null; then
        print_warning "uuidgen not found, will use fallback for request IDs"
    fi
    
    if ! command -v bc &> /dev/null; then
        print_warning "bc not found, will use basic arithmetic for RPS calculation"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_error "Missing required dependencies: ${missing_deps[*]}"
        print_status "Please install the missing dependencies and try again"
        exit 1
    fi
}

# Check if services are running
check_services() {
    print_section "Checking Services"
    print_status "Checking service availability..."
    
    # Check Keycloak
    if ! curl -s --max-time 5 --connect-timeout 3 http://localhost:8080/health > /dev/null 2>&1; then
        print_error "Keycloak is not running on localhost:8080"
        exit 1
    fi
    
    # Check Backend service
    if ! curl -s --max-time 5 --connect-timeout 3 http://localhost:4000/health > /dev/null 2>&1; then
        print_error "Backend service is not running on localhost:4000"
        exit 1
    fi
    
    print_status "All services are running"
}

# Signal handler for cleanup
cleanup() {
    print_warning "Received interrupt signal, cleaning up..."
    exit 0
}

# Set up signal handlers
trap cleanup INT TERM

# Main execution
main() {
    check_dependencies
    check_services
    run_simulation
}

# Run main function
main "$@"