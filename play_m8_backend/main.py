import os
import time
import requests
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv

load_dotenv()

TWITCH_CLIENT_ID = os.getenv("TWITCH_CLIENT_ID", "")
TWITCH_CLIENT_SECRET = os.getenv("TWITCH_CLIENT_SECRET", "")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_token_cache = {"access_token": None, "expires_at": 0}
_games_cache = {"data": None, "expires_at": 0}


def get_twitch_token() -> str:
    now = int(time.time())
    if _token_cache["access_token"] and now < _token_cache["expires_at"] - 30:
        return _token_cache["access_token"]

    if not TWITCH_CLIENT_ID or not TWITCH_CLIENT_SECRET:
        raise RuntimeError("Missing TWITCH_CLIENT_ID or TWITCH_CLIENT_SECRET in .env")

    url = "https://id.twitch.tv/oauth2/token"
    params = {
        "client_id": TWITCH_CLIENT_ID,
        "client_secret": TWITCH_CLIENT_SECRET,
        "grant_type": "client_credentials",
    }

    r = requests.post(url, params=params, timeout=20)
    r.raise_for_status()
    data = r.json()

    _token_cache["access_token"] = data["access_token"]
    _token_cache["expires_at"] = now + int(data.get("expires_in", 3600))
    return _token_cache["access_token"]


@app.get("/igdb/games")
def igdb_games(limit: int = 30):
    now = int(time.time())

    # Cache for 60 seconds so Flutter doesn't wait on IGDB repeatedly
    if _games_cache["data"] and now < _games_cache["expires_at"]:
        return _games_cache["data"][: min(limit, len(_games_cache["data"]))]

    token = get_twitch_token()

    headers = {
        "Client-ID": TWITCH_CLIENT_ID,
        "Authorization": f"Bearer {token}",
    }

    query = f"""
      fields name, cover.image_id, genres.name;
      where cover != null;
      sort rating_count desc;
      limit {min(limit, 50)};
    """

    # Logging (visible in terminal)
    print(f"[IGDB] Fetching games limit={limit}")

    r = requests.post(
        "https://api.igdb.com/v4/games",
        headers=headers,
        data=query,
        timeout=20,
    )
    r.raise_for_status()

    games = r.json()
    results = []

    for g in games:
        gid = g.get("id")
        title = g.get("name") or "Unknown"

        genre = "Unknown"
        genres = g.get("genres") or []
        if genres and isinstance(genres, list):
            gn = genres[0].get("name")
            if gn:
                genre = gn

        cover = g.get("cover")
        image_id = cover.get("image_id") if isinstance(cover, dict) else None

        image_url = ""
        if image_id:
            image_url = f"https://images.igdb.com/igdb/image/upload/t_cover_big_2x/{image_id}.jpg"

        results.append({
            "id": gid,
            "title": title,
            "genre": genre,
            "imageUrl": image_url,
        })

    _games_cache["data"] = results
    _games_cache["expires_at"] = now + 60

    return results
