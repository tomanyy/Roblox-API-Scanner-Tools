import requests

def get_user_id(username):
    url = "https://users.roblox.com/v1/usernames/users"
    payload = {"usernames": [username], "excludeBannedUsers": True}
    headers = {"Content-Type": "application/json"}
    
    response = requests.post(url, json=payload, headers=headers)
    
    if response.status_code == 200:
        data = response.json()
        if data["data"]:
            return data["data"][0]["id"]
        else:
            print("User not found.")
            return None
    else:
        print(f"Failed to fetch user ID. Status Code: {response.status_code}, Response: {response.text}")
        return None

def get_user_games(user_id):
    url = f"https://games.roblox.com/v2/users/{user_id}/games?accessFilter=Public&limit=50"
    response = requests.get(url)
    
    if response.status_code == 200:
        data = response.json()
        games = data.get("data", [])
        
        if not games:
            print("No games found for this user.")
            return
        
        print(f"Games created by user {user_id}:")
        for game in games:
            print(f"- {game['name']} (ID: {game['id']})")
    else:
        print(f"Failed to fetch games. Status Code: {response.status_code}, Response: {response.text}")
        
if __name__ == "__main__":
    username = input("Enter the Roblox username: ")
    user_id = get_user_id(username)
    
    if user_id:
        get_user_games(user_id)
