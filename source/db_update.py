import psycopg2
import json
import datetime
import support
import support.api


# Release date for lords of the west
# First metadata set is based on this release
DEFAULT_TIME = support.as_seconds(datetime.datetime(
    year=2021,
    month=10,
    day=1,
    hour=1,
    minute=00,
    second=00
))


def db_insert_into(data, db_name):
    db_vars = dbmeta[db_name]["variables"].keys()
    db_keys = dbmeta[db_name]["keys"]
    
    insert_query_template = """\
    INSERT INTO {TABLE} ({VARIABLES})
    VALUES ({VALUES})
    ON CONFLICT ({KEYS}) DO NOTHING;
    """
    
    insert_query = insert_query_template.format(
        TABLE=db_name,
        VARIABLES=", ".join(db_vars),
        VALUES=", ".join(["%s" for i in db_vars]),
        KEYS=", ".join(db_keys)
    )
    
    for row in data:
        record_to_insert = [row[var] for var in db_vars]
        cur.execute(insert_query, record_to_insert)


def extract_data(dat):
    PLAYERS = []
    MATCHES = []
    for row in dat:
        players = row["players"]
        match_id = row["match_id"]
        row["players"] = {}
        for player in players:
            player["match_id"] = match_id
            if not player["profile_id"]:
                player["profile_id"] = -999
            PLAYERS.append(player)
        MATCHES.append(row)
    return {"matches": MATCHES, "players": PLAYERS}


def db_create_table_if_not(db_name):
    
    create_table_query_template = """
    CREATE TABLE IF NOT EXISTS public.{TABLE} (
        {VARIABLES},
        PRIMARY KEY ({KEYS})
        {CONSTRAINTS}
    );
    """
    
    constraint_template = """
    ,CONSTRAINT {CONSTRAINT_NAME} {CONSTRAINT}
    """
    
    keys = dbmeta[db_name]["keys"]
    variables = dbmeta[db_name]["variables"]
    constraints_raw = dbmeta[db_name].get("constraints")
    
    if constraints_raw is not None:
        constraints = [
            constraint_template.format(
                CONSTRAINT_NAME=i,
                CONSTRAINT=constraints_raw[i]
            )
            for i in constraints_raw.keys()
        ]
    else:
        constraints = [""]
    
    create_table_query = create_table_query_template.format(
        TABLE=db_name,
        VARIABLES=", ".join(
            ["{var} {type}".format(var=var, type=type) for var, type in variables.items()]
        ),
        KEYS=", ".join(keys),
        CONSTRAINTS=" ".join(constraints)
    )
    
    cur.execute(create_table_query)


def get_connection():
    with open("./bin/config.json") as fi:
        env = json.load(fi)
    conn = psycopg2.connect(
        host=env["APP_HOST"],
        database=env["APP_DB"],
        user=env["APP_USER"],
        password=env["APP_PASSWORD"]
    )
    return conn


def db_get_latest():
    query = "SELECT count(started) as count from public.match_meta;"
    cur.execute(query)
    ret = cur.fetchall()
    count = ret[0][0]
    if count == 0:
        return DEFAULT_TIME
    query = "SELECT max(started) from public.match_meta;"
    cur.execute(query)
    ret = cur.fetchall()
    return ret[0][0]


def add_to_db(dt):
    print(
        "Getting:",
        datetime.datetime.fromtimestamp(dt)
    )
    
    ret = support.api.get_matches(dt)
    data = extract_data(ret)
    
    db_insert_into(
        data=data["matches"],
        db_name="match_meta"
    )
    
    db_insert_into(
        data=data["players"],
        db_name="match_players"
    )
    
    conn.commit()


if __name__ == "__main__":
    
    with open("./data-raw/db_schema.json", "r") as fi:
        dbmeta = json.load(fi)
    
    dt_limit = support.as_seconds(
        datetime.datetime.now() - datetime.timedelta(hours=32)
    )
    
    conn = get_connection()
    cur = conn.cursor()

    for db in dbmeta:
        db_create_table_if_not(db)
    
    conn.commit()
    
    latest = db_get_latest()
    
    while latest <= dt_limit:
        old_latest = latest
        add_to_db(latest)
        latest = db_get_latest()
        if old_latest == latest:
            raise RuntimeError("Latest did not advance after data update")
    
    cur.close()
    conn.close()
