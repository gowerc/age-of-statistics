import datetime



def as_seconds(dt):
    return int(
        round(
            (dt - datetime.datetime(1970, 1, 1)).total_seconds(),
            0
        )
    )




