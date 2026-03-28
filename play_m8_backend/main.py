import os
import time
import urllib.parse
import requests
import re
from typing import Dict, Any, List, Optional, Tuple

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from dotenv import load_dotenv
from pydantic import BaseModel

from play_m8DB import supabase  # kept (even if not used yet)
from account import Account

# Friend-added: user model (safe import so app doesn't crash if file missing)
try:
    from user import User  # noqa: F401
except Exception:
    User = None

load_dotenv()

# -----------------------------
# Models
# -----------------------------
class pyAccount(BaseModel):
    email: str
    password: str
    username: str


ac = Account()

# -----------------------------
# Env
# -----------------------------
TWITCH_CLIENT_ID = os.getenv("TWITCH_CLIENT_ID", "")
TWITCH_CLIENT_SECRET = os.getenv("TWITCH_CLIENT_SECRET", "")

STEAM_WEB_API_KEY = os.getenv("STEAM_WEB_API_KEY", "")

# Steam OpenID
PUBLIC_BASE_URL = os.getenv("PUBLIC_BASE_URL", "http://10.0.2.2:8000")
STEAM_OPENID_ENDPOINT = "https://steamcommunity.com/openid/login"

# -----------------------------
# App
# -----------------------------
app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ==========================================================
# Auth (Signup + Login)
# ==========================================================
@app.post("/signup")
def signup(newAC: pyAccount):
    ac.createAccount(newAC.username, newAC.email, newAC.password)
    return {"Confirmation": "Look for a confirmation email in your account"}


# ✅ Friend-added endpoint (kept)
@app.post("/login")
def login(account: pyAccount):
    """
    Expects Account.signIn(email, password) to return a User-like object
    with getUsername(). This matches your teammate's code.
    """
    email = account.email
    password = account.password

    user = ac.signIn(email, password)

    # Defensive: if user is dict-like or doesn't have getUsername
    username = None
    if hasattr(user, "getUsername"):
        username = user.getUsername()
    elif isinstance(user, dict):
        username = user.get("username")

    if not username:
        # You can change this behavior if you want
        return {"username": ""}

    return {"username": username}


# ==========================================================
# Steam OpenID Login
# ==========================================================
def build_steam_login_url() -> str:
    return_to = f"{PUBLIC_BASE_URL}/steam/callback"
    params = {
        "openid.ns": "http://specs.openid.net/auth/2.0",
        "openid.mode": "checkid_setup",
        "openid.return_to": return_to,
        "openid.realm": PUBLIC_BASE_URL,
        "openid.identity": "http://specs.openid.net/auth/2.0/identifier_select",
        "openid.claimed_id": "http://specs.openid.net/auth/2.0/identifier_select",
    }
    return f"{STEAM_OPENID_ENDPOINT}?{urllib.parse.urlencode(params)}"


def extract_steamid(claimed_id: str) -> str:
    if "/openid/id/" not in claimed_id:
        raise ValueError("Invalid claimed_id")
    return claimed_id.rstrip("/").split("/")[-1]


@app.get("/steam/login_url")
def steam_login_url():
    return {"url": build_steam_login_url()}


@app.get("/steam/callback")
async def steam_callback(request: Request):
    """
    Steam redirects here after login.
    We verify the OpenID response, then return an HTML "bridge page"
    that opens the app via deep link (more reliable than 307 redirect).
    """
    qp = dict(request.query_params)

    mode = qp.get("openid.mode")
    claimed_id = qp.get("openid.claimed_id")

    if mode != "id_res" or not claimed_id:
        raise HTTPException(status_code=400, detail="Invalid OpenID response.")

    validate_params = dict(qp)
    validate_params["openid.mode"] = "check_authentication"

    r = requests.post(STEAM_OPENID_ENDPOINT, data=validate_params, timeout=20)
    if r.status_code != 200 or "is_valid:true" not in r.text:
        raise HTTPException(status_code=401, detail="Steam OpenID verification failed")

    steamid = extract_steamid(claimed_id)
    deep_link = f"playm8://auth/steam?steamid={steamid}"

    html = f"""
    <!doctype html>
    <html>
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width,initial-scale=1" />
        <title>Opening PlayM8…</title>
        <style>
          body {{
            font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Arial, sans-serif;
            padding: 24px; text-align: center;
          }}
          a.button {{
            display: inline-block; padding: 14px 18px; border-radius: 10px;
            background: #1f6feb; color: white; text-decoration: none; font-weight: 700;
          }}
          .muted {{ color: #666; margin-top: 14px; }}
        </style>
      </head>
      <body>
        <h2>Opening PlayM8…</h2>
        <p>If nothing happens, tap the button below:</p>
        <p><a class="button" href="{deep_link}">Continue to PlayM8</a></p>
        <p class="muted">SteamID: {steamid}</p>

        <script>
          window.location.href = "{deep_link}";
          setTimeout(function() {{
            window.location.href = "{deep_link}";
          }}, 600);
        </script>
      </body>
    </html>
    """
    return HTMLResponse(content=html, status_code=200)


# ==========================================================
# Steam Owned Games (History + playtime)
# ==========================================================
def _steam_owned_games_raw(steamid: str) -> List[Dict[str, Any]]:
    if not STEAM_WEB_API_KEY:
        raise HTTPException(status_code=500, detail="Missing STEAM_WEB_API_KEY in .env")

    url = "https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/"
    params = {
        "key": STEAM_WEB_API_KEY,
        "steamid": steamid,
        "include_appinfo": True,
        "include_played_free_games": True,
        "format": "json",
    }

    r = requests.get(url, params=params, timeout=25)
    if r.status_code != 200:
        raise HTTPException(status_code=502, detail=f"Steam API error: {r.text}")

    data = r.json()
    resp = data.get("response", {}) or {}
    return (resp.get("games", []) or [])


@app.get("/steam/owned_games")
def steam_owned_games(steamid: str):
    games = _steam_owned_games_raw(steamid)

    cleaned = []
    for g in games:
        appid = g.get("appid")
        cleaned.append(
            {
                "appid": appid,
                "name": g.get("name"),
                "playtime_forever": g.get("playtime_forever", 0),
                "header_image": f"https://cdn.cloudflare.steamstatic.com/steam/apps/{appid}/header.jpg",
            }
        )

    return {"steamid": steamid, "game_count": len(cleaned), "games": cleaned}


# ==========================================================
# IGDB + Twitch token
# ==========================================================
_token_cache = {"access_token": None, "expires_at": 0}
_games_cache: Dict[str, Dict[str, Any]] = {}
_platforms_cache = {"data": None, "expires_at": 0}

# cache for Steam->IGDB category profile
_profile_cache: Dict[str, Dict[str, Any]] = {}


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


# ==========================================================
# Steam -> IGDB category profile (genres + themes)
# ==========================================================
def _clean_title_for_igdb(name: str) -> str:
    s = (name or "").strip()
    s = re.sub(r"\s+", " ", s)
    s = re.sub(
        r"\b(goty|game of the year|ultimate|definitive|complete|deluxe|edition)\b",
        "",
        s,
        flags=re.I,
    )
    s = re.sub(r"\s+", " ", s).strip()
    return s


def _igdb_best_match_categories(game_name: str) -> Tuple[List[str], List[str]]:
    q = _clean_title_for_igdb(game_name)
    if not q:
        return ([], [])

    token = get_twitch_token()
    headers = {"Client-ID": TWITCH_CLIENT_ID, "Authorization": f"Bearer {token}"}

    query = f'''
      search "{q.replace('"', '\\"')}";
      fields id, name, genres.name, themes.name, rating_count;
      where name != null;
      limit 5;
    '''

    r = requests.post(
        "https://api.igdb.com/v4/games", headers=headers, data=query, timeout=20
    )
    r.raise_for_status()
    results = r.json() or []
    if not results:
        return ([], [])

    best = max(results, key=lambda g: int(g.get("rating_count") or 0))

    genres_out: List[str] = []
    gl = best.get("genres") or []
    if isinstance(gl, list):
        for gg in gl:
            if isinstance(gg, dict) and gg.get("name"):
                genres_out.append(str(gg["name"]))

    themes_out: List[str] = []
    tl = best.get("themes") or []
    if isinstance(tl, list):
        for tt in tl:
            if isinstance(tt, dict) and tt.get("name"):
                themes_out.append(str(tt["name"]))

    def uniq(xs: List[str]) -> List[str]:
        seen = set()
        out = []
        for x in xs:
            if x not in seen:
                seen.add(x)
                out.append(x)
        return out

    return (uniq(genres_out), uniq(themes_out))


@app.get("/steam/profile_categories")
def steam_profile_categories(steamid: str, top_n: int = 25, top_k: int = 6):
    now = int(time.time())
    cache_key = f"{steamid}|top_n={top_n}|top_k={top_k}"
    cached = _profile_cache.get(cache_key)
    if cached and now < cached.get("expires_at", 0):
        return cached["data"]

    games = _steam_owned_games_raw(steamid)
    games_sorted = sorted(
        games, key=lambda g: int(g.get("playtime_forever") or 0), reverse=True
    )
    top_games = games_sorted[: max(5, min(top_n, 80))]

    genre_w: Dict[str, float] = {}
    theme_w: Dict[str, float] = {}

    debug_used = []
    matched_count = 0

    for g in top_games:
        name = g.get("name") or ""
        minutes = int(g.get("playtime_forever") or 0)
        if not name or minutes <= 0:
            continue

        hours = minutes / 60.0
        genres, themes = _igdb_best_match_categories(name)
        if not genres and not themes:
            continue

        matched_count += 1

        for gn in genres:
            genre_w[gn] = genre_w.get(gn, 0.0) + hours
        for tn in themes:
            theme_w[tn] = theme_w.get(tn, 0.0) + hours

        debug_used.append(
            {
                "name": name,
                "hours": round(hours, 1),
                "genres": genres[:4],
                "themes": themes[:4],
            }
        )

    top_genres = [
        k
        for (k, _) in sorted(genre_w.items(), key=lambda kv: kv[1], reverse=True)[
            : max(1, min(top_k, 12))
        ]
    ]
    top_themes = [
        k
        for (k, _) in sorted(theme_w.items(), key=lambda kv: kv[1], reverse=True)[
            : max(1, min(top_k, 12))
        ]
    ]

    combined: Dict[str, float] = {}
    for k, v in genre_w.items():
        combined[k] = combined.get(k, 0.0) + v
    for k, v in theme_w.items():
        combined[k] = combined.get(k, 0.0) + v

    all_ranked = [k for (k, _) in sorted(combined.items(), key=lambda kv: kv[1], reverse=True)]

    out = {
        "steamid": steamid,
        "top_genres": top_genres,
        "top_themes": top_themes,
        "all_categories_ranked": all_ranked[:50],
        "computed_from_games": matched_count,
        "debug_sample": debug_used[:10],
    }

    _profile_cache[cache_key] = {"data": out, "expires_at": now + (10 * 60)}
    return out


# ==========================================================
# IGDB games (filters: category matches genres OR themes; platforms optional)
# ==========================================================
@app.get("/igdb/games")
def igdb_games(
    limit: int = 40, genre: Optional[str] = None, platforms: Optional[str] = None
):
    now = int(time.time())
    cache_key = f"limit={limit}|genre={genre or ''}|platforms={platforms or ''}"
    cached = _games_cache.get(cache_key)
    if cached and now < cached.get("expires_at", 0):
        data = cached["data"]
        return data[: min(limit, len(data))]

    token = get_twitch_token()
    headers = {"Client-ID": TWITCH_CLIENT_ID, "Authorization": f"Bearer {token}"}

    requested: Optional[str] = None
    if genre and genre.strip() and genre.strip().lower() != "all":
        requested = genre.strip()

    wanted_platforms: List[str] = []
    if platforms and platforms.strip():
        wanted_platforms = [p.strip() for p in platforms.split(",") if p.strip()]

    def run_query(require_cover: bool) -> List[Dict[str, Any]]:
        where_clauses: List[str] = []
        if require_cover:
            where_clauses.append("cover != null")

        if requested:
            v = requested.replace('"', '\\"')
            where_clauses.append(f'(genres.name = ("{v}") | themes.name = ("{v}"))')

        if wanted_platforms:
            escaped = [p.replace('"', '\\"') for p in wanted_platforms]
            quoted = ",".join([f'"{p}"' for p in escaped])
            where_clauses.append(f"platforms.name = ({quoted})")

        where_sql = " & ".join(where_clauses) if where_clauses else "name != null"

        filtered = bool(requested or wanted_platforms)
        igdb_limit = min(max(limit, 160 if filtered else limit), 200)
        sort_line = "" if filtered else "sort rating_count desc;"

        query = f"""
          fields name, cover.image_id, genres.name, themes.name, platforms.name;
          where {where_sql};
          {sort_line}
          limit {igdb_limit};
        """

        r = requests.post(
            "https://api.igdb.com/v4/games", headers=headers, data=query, timeout=20
        )
        r.raise_for_status()

        games = r.json() or []
        results: List[Dict[str, Any]] = []

        for g in games:
            gid = g.get("id")
            title = g.get("name") or "Unknown"

            genre_names: List[str] = []
            genres_list = g.get("genres") or []
            if isinstance(genres_list, list):
                for gg in genres_list:
                    if isinstance(gg, dict) and gg.get("name"):
                        genre_names.append(str(gg["name"]))

            theme_names: List[str] = []
            themes_list = g.get("themes") or []
            if isinstance(themes_list, list):
                for tt in themes_list:
                    if isinstance(tt, dict) and tt.get("name"):
                        theme_names.append(str(tt["name"]))

            out_label = "Unknown"
            if requested and (requested in genre_names or requested in theme_names):
                out_label = requested
            elif genre_names:
                out_label = genre_names[0]
            elif theme_names:
                out_label = theme_names[0]

            cover = g.get("cover")
            image_id = cover.get("image_id") if isinstance(cover, dict) else None
            image_url = ""
            if image_id:
                image_url = f"https://images.igdb.com/igdb/image/upload/t_cover_big_2x/{image_id}.jpg"

            plats_out: List[str] = []
            pls = g.get("platforms") or []
            if isinstance(pls, list):
                for p in pls:
                    if isinstance(p, dict) and p.get("name"):
                        plats_out.append(str(p["name"]))

            results.append(
                {
                    "id": gid,
                    "title": title,
                    "genre": out_label,
                    "imageUrl": image_url,
                    "platforms": plats_out,
                }
            )

        return results

    results = run_query(require_cover=True)
    if not results and (requested or wanted_platforms):
        results = run_query(require_cover=False)

    _games_cache[cache_key] = {"data": results, "expires_at": now + 60}
    return results[: min(limit, len(results))]


@app.get("/igdb/platforms")
def igdb_platforms(limit: int = 250):
    now = int(time.time())
    if _platforms_cache["data"] and now < _platforms_cache["expires_at"]:
        data = _platforms_cache["data"]
        return data[: min(limit, len(data))]

    token = get_twitch_token()
    headers = {"Client-ID": TWITCH_CLIENT_ID, "Authorization": f"Bearer {token}"}

    q = f"""
      fields name;
      where name != null;
      sort name asc;
      limit {min(limit, 500)};
    """

    r = requests.post("https://api.igdb.com/v4/platforms", headers=headers, data=q, timeout=20)
    r.raise_for_status()

    raw = r.json() or []
    names = []
    for p in raw:
        if isinstance(p, dict) and p.get("name"):
            names.append(p["name"])

    names = sorted(list(set(names)))
    _platforms_cache["data"] = names
    _platforms_cache["expires_at"] = now + (24 * 60 * 60)
    return names
