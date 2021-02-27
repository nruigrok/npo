import requests

OP1 = "urn:vme:default:series:2102001130264509431"
API = "https://zoeken-api.beeldengeluid.nl/gp/api/v1"


def api_call(request):
    url = f"{API}{request}"
    r = requests.get(url)
    r.raise_for_status()
    data = r.json()["payload"]
    return data


def get_members(model, id, offset=0, limit=10):
    data = api_call(f"/model/{model}/{id}/members?offset={offset}&limit={limit}")
    # what are the members called?
    keys = set(x.replace("Pagination", "") for x in data.keys()) - {"id", "type"}
    if len(keys) != 1:
        raise Exception(f"Cannot find members name from {data.keys}: {keys}")
    key = list(keys)[0]
    return data[key], data[f"{key}Pagination"]


def get_all_members(model, id, offset=0, limit=10):
    while True:
        members, pagination = get_members(model, id, offset, limit)
        yield from members
        offset += limit
        if offset >= pagination['total']:
            break


def get_metadata(model, id):
    data = api_call(f"/model/{model}/{id}/metadata")
    metadata = {x["name"]: x.get("value") for x in data["metadata"]}
    if len(data["metadata"]) != len(metadata):
        raise Exception("Something went wrong, keys not unique?")
    return metadata
