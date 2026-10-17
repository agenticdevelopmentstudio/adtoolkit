"""The live-site probe: the website serving the feed must be up before anything is published."""
from __future__ import annotations

import urllib.parse

from .state import Release


def http_status(r: Release, url: str) -> str:
    """The final HTTP status `url` answers with (redirects followed), or ''
    when nothing answered."""
    probe = r.run(["curl", "--silent", "--location", "--max-time", "30",
                   "--output", "/dev/null", "--write-out", "%{http_code}", url])
    status = (probe.stdout or "").strip()
    return "" if probe.returncode != 0 or status == "000" else status


def site_failures(r: Release) -> list[str]:
    """The site serving SUFeedURL must be live before anything is published,
    or installed apps poll a 404 and the release reaches no one.

    Once an appcast.xml is published, the feed itself must answer 200. Before
    the first release there is no appcast.xml for the site to proxy, so the
    feed cannot answer 200 yet; the same deploy's downloads page stands in.

    `r.site` swaps the origin for another deploy of the same website (staging),
    keeping the routes, so a release can be checked before production is live.
    """
    routes = r.cfg.site_routes
    feed = urllib.parse.urljoin(r.origin, routes["appcast"])
    first_release = not (r.releases_repo / "appcast.xml").exists()
    target = urllib.parse.urljoin(r.origin, routes["downloads"]) if first_release else feed
    status = http_status(r, target)
    where = r.site or "production"
    if status == "200":
        return []
    why = (f" (the first release: no appcast.xml is published yet, so {feed} cannot answer "
           f"200 until this release pushes one; the same site deploy's {routes['downloads']} "
           "stands in)" if first_release else "")
    return [f"{target} answered HTTP {status or 'nothing'}, not 200{why} — the website "
            f"version carrying {routes['appcast']} and {routes['downloads']} must be live on "
            f"{where} before a release. Deploying it is the owner's step; the release "
            "pipeline never deploys the site"]
