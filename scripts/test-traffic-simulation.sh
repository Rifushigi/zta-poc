#!/bin/bash
# scripts/test-traffic-simulation.sh

set -e

echo "Testing Traffic Simulation Script"
echo "=================================="

# Test 1: Benign traffic for 30 seconds
echo ""
echo "Test 1: Benign traffic (30 seconds, low intensity)"
./scripts/simulate-traffic.sh --type benign --duration 30 --intensity low

# Test 2: Malicious traffic for 30 seconds
echo ""
echo "Test 2: Malicious traffic (30 seconds, low intensity)"
./scripts/simulate-traffic.sh --type malicious --duration 30 --intensity low

# Test 3: Mixed traffic for 30 seconds
echo ""
echo "Test 3: Mixed traffic (30 seconds, low intensity)"
./scripts/simulate-traffic.sh --type mixed --duration 30 --intensity low

echo ""
echo "All tests completed!"
echo ""
echo "Log files created:"
echo "  - /tmp/traffic_simulation.log (latest run)"
echo ""
echo "Users file:"
echo "  - /tmp/simulation_users.json"
echo ""
echo "To view the latest log:"
echo "  tail -f /tmp/traffic_simulation.log"
echo ""
echo "To run longer simulations:"
echo "  ./scripts/simulate-traffic.sh --type benign --duration 300 --intensity normal"
echo "  ./scripts/simulate-traffic.sh --type malicious --duration 120 --intensity high"
echo "  ./scripts/simulate-traffic.sh --type mixed --duration 600 --intensity normal" 