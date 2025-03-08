import requests
import json
import time
from tabulate import tabulate

def get_friends(user_id):
    url = f"https://friends.roblox.com/v1/users/{user_id}/friends"
    response = requests.get(url)
    
    if response.status_code == 429:
        print("Rate limited! Waiting before retrying...")
        time.sleep(5)  # Wait 5 seconds before retrying
        return get_friends(user_id)

    if response.status_code == 200:
        return response.json().get("data", [])
    
    print(f"Error fetching friends: {response.status_code}")
    return []

def get_currently_wearing(friend_id):
    url = f"https://avatar.roblox.com/v1/users/{friend_id}/currently-wearing"
    response = requests.get(url)

    if response.status_code == 429:
        print(f"Rate limited on {friend_id}, waiting before retrying...")
        time.sleep(5)
        return get_currently_wearing(friend_id)

    if response.status_code == 200:
        return response.json().get("assetIds", [])
    
    print(f"Error fetching avatar for {friend_id}: {response.status_code}")
    return []

def main():
    user_id = input("Enter the Roblox user ID to scan: ")
    flagged_items = {123456, 7890000}  # Replace with actual flagged item IDs
    
    friends = get_friends(user_id)
    detected_friends = []
    
    for friend in friends:
        friend_id = friend["id"]
        friend_name = friend["name"]

        time.sleep(4)  # Prevent hitting rate limits

        worn_items = get_currently_wearing(friend_id)
        
        detected_items = [item for item in worn_items if item in flagged_items]
        
        if detected_items:
            print(f"{friend_name} ({friend_id}) has items {detected_items} equipped")
            detected_friends.append([friend_name, friend_id, ", ".join(map(str, detected_items))])
        else:
            print(f"{friend_name} ({friend_id}) hasn't got any of the certain items equipped")
    
    print(f"\nDetected friends: {len(detected_friends)}")
    
    if detected_friends:
        print("\nDetected Friends Table:")
        print(tabulate(detected_friends, headers=["Friend Name", "Friend ID", "Detected Items"], tablefmt="grid"))

if __name__ == "__main__":
    main()
