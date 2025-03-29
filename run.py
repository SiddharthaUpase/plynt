import requests
import json
import time
import subprocess
import sys

# API configuration
API_KEY = "m0-Q7FEFPUZAQ5xxXAjBy139zDyQzMNz4cRVMWvUnF9"
BASE_URL = "https://api.mem0.ai/v1/memories/"

user_id = "s1dupase34@gmail.com"

# Fetch all memories from the API
def get_all_memories():
    headers = {
        "Authorization": f"Token {API_KEY}",
        "Content-Type": "application/json"
    }
    
    # Include user_id directly in the URL as suggested
    url = f"{BASE_URL}?version=v2&page=1&page_size=50&user_id={user_id}"
    
    print(f"Attempting to fetch memories from: {url}")
    response = requests.get(url, headers=headers)
    
    if response.status_code != 200:
        print(f"Failed to fetch memories: {response.status_code}")
        print(f"Response: {response.text}")
        
        # Try alternative URL format
        alt_url = f"{BASE_URL}?user_id={user_id}&version=v2&page=1&page_size=50"
        print(f"Trying alternative URL: {alt_url}")
        response = requests.get(alt_url, headers=headers)
        
        if response.status_code != 200:
            print(f"Alternative URL also failed: {response.status_code}")
            print(f"Response: {response.text}")
            return []
    
    data = response.json()
    print(f"Successfully fetched {len(data.get('results', []))} memories")
    return [memory["id"] for memory in data.get("results", [])]

# Get memory IDs to delete
memory_ids = get_all_memories()

# Counters for tracking progress
total_memories = len(memory_ids)
deleted = 0
failed = 0
failed_ids = []

print(f"Found {total_memories} memories to delete")

# Delete each memory
for i, memory_id in enumerate(memory_ids):
    print(f"Deleting memory {i+1}/{total_memories}: {memory_id}")
    
    headers = {
        "Authorization": f"Token {API_KEY}",
        "Content-Type": "application/json"
    }
    
    response = requests.delete(f"{BASE_URL}{memory_id}/", headers=headers)
    
    if response.status_code in [200, 204]:
        print(f"✓ Successfully deleted memory: {memory_id}")
        deleted += 1
    else:
        print(f"✗ Failed to delete memory: {memory_id} (Status: {response.status_code})")
        print(f"  Response: {response.text}")
        failed += 1
        failed_ids.append(memory_id)
    
    # Small delay to avoid rate limiting
    time.sleep(0.5)

# Summary
print("\nDeletion complete!")
print(f"Successfully deleted: {deleted}/{total_memories}")
print(f"Failed: {failed}/{total_memories}")

if failed > 0:
    print("\nFailed memory IDs:")
    for failed_id in failed_ids:
        print(f"- {failed_id}")
