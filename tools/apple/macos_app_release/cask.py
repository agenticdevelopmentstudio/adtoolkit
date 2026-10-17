"""The Homebrew cask: the app's own template, rendered for one release."""
from __future__ import annotations

import re
import string

import macos_release as mr

from .config import ReleaseConfig

# LSMinimumSystemVersion's major -> the symbol a cask's `depends_on macos:` takes.
HOMEBREW_MACOS = {"14": ":sonoma", "15": ":sequoia", "26": ":tahoe"}


def homebrew_macos(minimum_system_version: str) -> str:
    major = minimum_system_version.split(".")[0]
    if major not in HOMEBREW_MACOS:
        raise RuntimeError(f"no Homebrew macOS symbol for LSMinimumSystemVersion "
                           f"{minimum_system_version!r} — add its major to HOMEBREW_MACOS")
    return HOMEBREW_MACOS[major]


def cask_ruby(entry: mr.ReleaseEntry, cfg: ReleaseConfig) -> str:
    """The Homebrew cask for `entry`, rendered from `cfg.cask_template`
    (a `string.Template`; variables `$version $sha256 $url $pkg $name $homepage
    $feed $macos $bundle_id $token`). Its url is written with brew's
    `#{version}` interpolation, the form `brew bump-cask-pr` and livecheck
    expect; it must still name exactly the pkg releases.json lists.

    A template naming any other variable raises KeyError (`substitute`, never
    `safe_substitute`), so a bad template stops the release before it is public.
    """
    pkg = f"{cfg.app_name}-#{{version}}.pkg"
    url = f"{cfg.download_prefix}/v#{{version}}/{pkg}"
    if url.replace("#{version}", entry.version) != entry.pkg.url:
        raise ValueError(f"the cask's url {url} would not resolve to the published pkg "
                         f"{entry.pkg.url}")
    rendered = string.Template(cfg.cask_template.read_text()).substitute(
        version=entry.version, sha256=entry.pkg.sha256, url=url, pkg=pkg, name=cfg.title,
        homepage=f"{cfg.site_origin}/", feed=cfg.feed_url,
        macos=homebrew_macos(entry.minimum_system_version),
        bundle_id=cfg.bundle_id, token=cfg.cask_token)
    # A template may hard-code its url stanza instead of using $url: hold the
    # rendered cask itself to the same rule.
    stanza = re.search(r'^  url "([^"]+)"', rendered, re.MULTILINE)
    if stanza is None:
        raise ValueError(f"{cfg.cask_template} renders no top-level `url \"...\"` stanza")
    if stanza.group(1).replace("#{version}", entry.version) != entry.pkg.url:
        raise ValueError(f"the rendered cask's url {stanza.group(1)} would not resolve to the "
                         f"published pkg {entry.pkg.url}")
    return rendered
