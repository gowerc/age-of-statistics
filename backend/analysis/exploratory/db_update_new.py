import datetime
import time
import os
import re
from requests.exceptions import ConnectionError
from requests.exceptions import HTTPError
from urllib3.exceptions import MaxRetryError
from urllib3.exceptions import NewConnectionError
import requests
import pyarrow as pa
import pyarrow.parquet as pq
import pandas as pd


schema_players = {
    "match_id": pa.string(),
    "profile_id": pa.int32(),
    "steam_id": pa.string(),
    "name": pa.string(),
    "clan": pa.bool_(),
    "country": pa.string(),
    "slot": pa.int32(),
    "slot_type": pa.int32(),
    "rating": pa.int32(),
    "rating_change": pa.int32(),
    "games": pa.bool_(),
    "wins": pa.bool_(),
    "streak": pa.bool_(),
    "drops": pa.bool_(),
    "color": pa.int32(),
    "team": pa.int32(),
    "civ": pa.int32(),
    "won": pa.bool_()
}


schema_matches = {
    "match_id": pa.string(),
    "lobby_id": pa.string(),
    "match_uuid": pa.string(),
    "version": pa.string(),
    "name": pa.string(),
    "num_players": pa.int32(),
    "num_slots": pa.int32(),
    "average_rating": pa.int32(),
    "cheats": pa.bool_(),
    "full_tech_tree": pa.bool_(),
    "ending_age": pa.int32(),
    "expansion": pa.bool_(),
    "game_type": pa.int32(),
    "has_custom_content": pa.bool_(),
    "has_password": pa.bool_(),
    "lock_speed": pa.bool_(),
    "lock_teams": pa.bool_(),
    "map_size": pa.int32(),
    "map_type": pa.int32(),
    "pop": pa.int32(),
    "ranked": pa.bool_(),
    "leaderboard_id": pa.int32(),
    "rating_type": pa.int32(),
    "resources": pa.int32(),
    "rms": pa.string(),
    "scenario": pa.string(),
    "server": pa.string(),
    "shared_exploration": pa.bool_(),
    "speed": pa.int32(),
    "starting_age": pa.int32(),
    "team_together": pa.bool_(),
    "team_positions": pa.bool_(),
    "treaty_length": pa.int32(),
    "turbo": pa.bool_(),
    "victory": pa.int32(),
    "victory_time": pa.int32(),
    "visibility": pa.int32(),
    "opened": pa.int32(),
    "started": pa.int32(),
    "finished": pa.int32()
}


def get_matches(
        since,
        count=1000,
        game="aoe2de",
        language="en"):
    assert isinstance(since, int)
    params = {
        "since": since,
        "count": count,
        "game": game,
        "language": language
    }
    resp = requests.get("https://aoe2.net/api/matches", params)
    resp.raise_for_status()
    return resp.json()


def as_seconds(dt):
    return int(
        round(
            (dt - datetime.datetime(1970, 1, 1)).total_seconds(),
            0
        )
    )


def parse_api_players(apidata):
    players_data = []
    for match in apidata:
        match_id = match["match_id"]
        for player in match["players"]:
            player["match_id"] = match_id
            players_data.append(player)
    players_df = pd.DataFrame(players_data)
    players_pa = [
        pa.array(players_df[col], type=schema_players[col])
        for col in schema_players.keys()
    ]
    players_table = pa.table(players_pa, names=list(schema_players.keys()))
    return players_table


def parse_api_matches(apidata):
    matches_data = []
    for match in apidata:
        del match['players']
        matches_data.append(match)
    matches_df = pd.DataFrame(matches_data)
    matches_pa = [
        pa.array(matches_df[col], type=schema_matches[col])
        for col in schema_matches.keys()
    ]
    matches_table = pa.table(matches_pa, names=list(schema_matches.keys()))
    return matches_table


def get_latest_players_id():
    files = [i for i in os.listdir("./data/source/players") if i.endswith(".parquet")]
    if not files:
        return '0'
    files.sort(reverse=True)
    return re.match("players_(\d+).parquet", files[0])[1]


def get_latest_matches_id():
    files = [i for i in os.listdir("./data/source/matches") if i.endswith(".parquet")]
    if not files:
        return '0'
    files.sort(reverse=True)
    return re.match("matches_(\d+).parquet", files[0])[1]


def get_latest_id():
    assert get_latest_players_id() == get_latest_matches_id(), "Matches/Players ID dont match"
    return get_latest_players_id()


def read_latest_players():
    fid = get_latest_players_id()
    return pq.read_table(f"./data/source/players/players_{fid}.parquet")


def read_latest_matches():
    fid = get_latest_matches_id()
    return pq.read_table(f"./data/source/matches/matches_{fid}.parquet")


def save_data(tab, file_type):
    current_id = int(get_latest_id())
    next_id = current_id + 200000
    match_id_int = tab["match_id"].to_numpy().astype(int) 
    gte_current = match_id_int >= current_id
    gte_next = match_id_int >= next_id
    lt_next = match_id_int < next_id
    pa.write_parquet(
        tab.filter(gte_current * lt_next),
        f"./data/source/{file_type}/{file_type}_{current_id}.parquet"
    )
    if any(gte_next):
        pa.write_parquet(
            tab.filter(gte_next),
            f"./data/source/{file_type}/{file_type}_{next_id}.parquet"
        )


# Manage how we handle API failures
FAILURE_LIMIT = 3
FAILURE_CURRENT = 0

# Manage how many API pulls we do before saving the data
SAVE_LIMIT = 6
SAVE_CURRENT = 0


# Release date for lords of the west
# First metadata set is based on this release
DEFAULT_TIME = as_seconds(datetime.datetime(
    year=2021,
    month=9,
    day=8,
    hour=1,
    minute=00,
    second=00
))


if __name__ == "__main__":

    dt_limit = as_seconds(
        datetime.datetime.now() - datetime.timedelta(hours=32)
    )

    players = read_latest_players()
    matches = read_latest_matches()
    latest = int(matches["started"].to_numpy().max())

    while latest <= dt_limit:
        old_latest = latest
        
        try:
            print("Getting", datetime.datetime.fromtimestamp(latest))
            apidata = get_matches(latest)
        except (TimeoutError, ConnectionError, MaxRetryError, NewConnectionError, HTTPError):
            print("\nTimeoutError !!\n")
            FAILURE_CURRENT += 1
            if FAILURE_CURRENT > FAILURE_LIMIT:
                raise RuntimeError("Failure limit reached")
            time.sleep(90)
            continue
        else:
            FAILURE_CURRENT = 0
        
        players = pa.concat_tables([players, parse_api_players(apidata)])
        matches = pa.concat_tables([matches, parse_api_matches(apidata)])
        latest = int(matches["started"].to_numpy().max())
        
        SAVE_CURRENT += 1
        if SAVE_CURRENT == SAVE_LIMIT:
            print("---Saving to disk---")
            save_data(players, "players")
            save_data(matches, "matches")
            players = read_latest_players()
            matches = read_latest_matches()
            SAVE_CURRENT = 0
        
        if old_latest == latest:
            raise RuntimeError("Latest did not advance after data update")
