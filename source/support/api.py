import requests


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


def get_meta(game="aoe2de", language="en"):
    params = {
        "game": game,
        "language": language
    }
    resp = requests.get("https://aoe2.net/api/strings", params)
    resp.raise_for_status()
    return resp.json()




