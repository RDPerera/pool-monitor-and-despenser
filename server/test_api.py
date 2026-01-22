#!/usr/bin/env python3
"""
Test script for Pool Dispenser API
"""

import requests
import json
import time
from datetime import datetime

# Configuration
BASE_URL = "http://localhost:5000"  # Change this to your server URL
API_GET = f"{BASE_URL}/api/dispenser/get"
API_SET = f"{BASE_URL}/api/dispenser/set"
API_RESET = f"{BASE_URL}/api/dispenser/reset"

def print_header(text):
    print("\n" + "="*50)
    print(f" {text}")
    print("="*50)

def print_response(response):
    print(f"Status Code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

def test_get_values():
    """Test getting current dispenser values"""
    print_header("TEST: Get Dispenser Values")
    try:
        response = requests.get(API_GET, timeout=5)
        print_response(response)
        return response.json()
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
        return None

def test_set_values(values):
    """Test setting dispenser values"""
    print_header("TEST: Set Dispenser Values")
    print(f"Setting values: {json.dumps(values, indent=2)}")
    try:
        response = requests.post(API_SET, json=values, timeout=5)
        print_response(response)
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
        return False

def test_reset_values():
    """Test resetting dispenser values"""
    print_header("TEST: Reset Dispenser Values")
    try:
        response = requests.post(API_RESET, timeout=5)
        print_response(response)
        return response.status_code == 200
    except requests.exceptions.RequestException as e:
        print(f"❌ Error: {e}")
        return False

def simulate_esp32_polling():
    """Simulate ESP32 polling behavior"""
    print_header("SIMULATION: ESP32 Polling")
    print("Simulating ESP32 polling every 5 seconds...")
    print("Press Ctrl+C to stop\n")
    
    try:
        poll_count = 0
        while True:
            poll_count += 1
            timestamp = datetime.now().strftime("%H:%M:%S")
            
            print(f"[{timestamp}] Poll #{poll_count}", end=" → ")
            
            try:
                response = requests.get(API_GET, timeout=2)
                if response.status_code == 200:
                    data = response.json()
                    
                    # Check if any dispenser has non-zero value
                    has_job = any(int(data.get(f"dispenser{i}", 0)) > 0 for i in range(1, 5))
                    
                    if has_job:
                        print(f"🔴 DISPENSING: {data}")
                    else:
                        print(f"🟢 Idle: {data}")
                else:
                    print(f"❌ Error {response.status_code}")
            except requests.exceptions.RequestException as e:
                print(f"❌ Connection error: {e}")
            
            time.sleep(5)
            
    except KeyboardInterrupt:
        print("\n\n✓ Simulation stopped")

def run_all_tests():
    """Run all API tests"""
    print("\n" + "="*50)
    print(" Pool Dispenser API Test Suite")
    print("="*50)
    print(f" Server: {BASE_URL}")
    print(f" Time: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*50)
    
    # Test 1: Get initial values
    initial_values = test_get_values()
    time.sleep(1)
    
    # Test 2: Set some test values
    test_values = {
        "dispenser1": "5",
        "dispenser2": "3",
        "dispenser3": "7",
        "dispenser4": "2"
    }
    test_set_values(test_values)
    time.sleep(1)
    
    # Test 3: Verify values were set
    test_get_values()
    time.sleep(1)
    
    # Test 4: Reset values
    test_reset_values()
    time.sleep(1)
    
    # Test 5: Verify reset
    test_get_values()
    
    print_header("All Tests Complete!")
    print("\nWhat would you like to do next?")
    print("1. Run tests again")
    print("2. Simulate ESP32 polling")
    print("3. Set custom values")
    print("4. Exit")
    
    choice = input("\nEnter choice (1-4): ").strip()
    
    if choice == "1":
        run_all_tests()
    elif choice == "2":
        simulate_esp32_polling()
    elif choice == "3":
        set_custom_values()
    else:
        print("\nGoodbye! 👋")

def set_custom_values():
    """Interactive value setting"""
    print_header("Set Custom Dispenser Values")
    print("Enter dispenser times in seconds (0 to skip):\n")
    
    values = {}
    for i in range(1, 5):
        while True:
            try:
                value = input(f"Dispenser {i} (seconds): ").strip()
                if value == "":
                    value = "0"
                int(value)  # Validate it's a number
                values[f"dispenser{i}"] = value
                break
            except ValueError:
                print("❌ Please enter a valid number")
    
    print(f"\nSetting: {json.dumps(values, indent=2)}")
    confirm = input("\nConfirm? (y/n): ").strip().lower()
    
    if confirm == 'y':
        if test_set_values(values):
            print("\n✓ Values set successfully!")
            test_get_values()
    else:
        print("❌ Cancelled")

def main():
    """Main entry point"""
    import sys
    
    if len(sys.argv) > 1:
        command = sys.argv[1].lower()
        
        if command == "get":
            test_get_values()
        elif command == "reset":
            test_reset_values()
        elif command == "poll":
            simulate_esp32_polling()
        elif command == "set":
            if len(sys.argv) == 6:
                values = {
                    "dispenser1": sys.argv[2],
                    "dispenser2": sys.argv[3],
                    "dispenser3": sys.argv[4],
                    "dispenser4": sys.argv[5]
                }
                test_set_values(values)
            else:
                set_custom_values()
        else:
            print("Usage:")
            print("  python test_api.py          - Run all tests")
            print("  python test_api.py get      - Get current values")
            print("  python test_api.py reset    - Reset to zero")
            print("  python test_api.py set      - Set custom values interactively")
            print("  python test_api.py set 5 3 2 4 - Set values directly")
            print("  python test_api.py poll     - Simulate ESP32 polling")
    else:
        run_all_tests()

if __name__ == "__main__":
    main()
