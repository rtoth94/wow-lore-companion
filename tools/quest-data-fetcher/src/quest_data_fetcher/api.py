#!/usr/bin/env python3
"""Fetch one Retail quest for inspection; no third-party packages required."""

import base64
import getpass
import json
import os
from pathlib import Path
import sys
from urllib.error import HTTPError, URLError
from urllib.parse import urlencode
from urllib.request import HTTPRedirectHandler, Request, build_opener


class ResourceNotFound(RuntimeError):
    """The API returned HTTP 404 for a resource."""


class NoRedirects(HTTPRedirectHandler):
    # Never forward credentials to a redirected destination.
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def request_json(request, stage):
    try:
        with build_opener(NoRedirects()).open(request, timeout=30) as response:
            data = json.load(response)
    except HTTPError as error:
        hints = {
            401: "Check your client credentials or token.",
            403: "Access was denied; check your API client access.",
            404: "This resource was not found; quest coverage is not guaranteed.",
            429: "Rate limited; wait before trying again.",
        }
        # Do not print response bodies or request headers: they may contain secrets.
        error_type = ResourceNotFound if error.code == 404 else RuntimeError
        raise error_type(
            f"{stage}: HTTP {error.code}. "
            + hints.get(error.code, "Request failed; try again later.")
        ) from None
    except (URLError, TimeoutError):
        raise RuntimeError(f"{stage}: connection failed; check network and TLS setup.") from None
    except (ValueError, UnicodeError):
        raise RuntimeError(f"{stage}: response was not valid JSON.") from None
    if not isinstance(data, dict):
        raise RuntimeError(f"{stage}: expected a JSON object.")
    return data


def load_env(path):
    if not path.exists():
        return
    for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        key, separator, value = line.partition("=")
        key, value = key.strip(), value.strip()
        if not separator or key not in ("BLIZZARD_CLIENT_ID", "BLIZZARD_CLIENT_SECRET"):
            raise RuntimeError(f"Invalid .env setting on line {number}.")
        if value.startswith(("'", '"')):
            if len(value) < 2 or value[-1] != value[0]:
                raise RuntimeError(f"Unmatched quote in .env on line {number}.")
            value = value[1:-1]
        os.environ.setdefault(key, value)


def authenticate(env_file):
    load_env(env_file)
    client_id = os.environ.get("BLIZZARD_CLIENT_ID")
    client_secret = os.environ.get("BLIZZARD_CLIENT_SECRET")
    if not client_id or not client_secret:
        if not sys.stdin.isatty():
            raise RuntimeError("Run in a terminal to enter credentials, or set BLIZZARD_CLIENT_ID and BLIZZARD_CLIENT_SECRET.")
        client_id = client_id or input("Blizzard client ID: ").strip()
        client_secret = client_secret or getpass.getpass("Blizzard client secret (hidden): ")
    if not client_id or not client_secret:
        raise RuntimeError("Both client ID and client secret are required.")

    # Client credentials flow: exchange app credentials for a temporary token.
    basic = base64.b64encode(f"{client_id}:{client_secret}".encode()).decode("ascii")
    token_data = request_json(Request(
        "https://oauth.battle.net/token",
        data=urlencode({"grant_type": "client_credentials"}).encode("ascii"),
        headers={"Authorization": f"Basic {basic}",
                 "Content-Type": "application/x-www-form-urlencoded"},
    ), "Authentication")
    token = token_data.get("access_token")
    if not isinstance(token, str) or not token:
        raise RuntimeError("Authentication: no access token returned.")
    return token


def fetch_quest(quest_id, region, token):
    locale = "en_GB" if region == "eu" else "en_US"
    query = urlencode({"namespace": f"static-{region}", "locale": locale})
    url = f"https://{region}.api.blizzard.com/data/wow/quest/{quest_id}?{query}"
    quest = request_json(Request(url, headers={
        "Authorization": f"Bearer {token}", "Accept": "application/json",
    }), "Quest retrieval")
    if quest.get("id") != quest_id:
        raise RuntimeError("Quest retrieval: response ID did not match the requested quest.")
    return quest
