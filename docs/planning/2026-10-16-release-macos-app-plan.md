# release-macos-app Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Turn Stenographer's release pipeline into one toolkit CLI driven by a per-app `release.json`, plus one shared `/release-macos-app` skill.

**Architecture:** A Python package `tools/apple/macos_app_release/` holds the pipeline, one module per concern, ported function by function from Stenographer's `scripts/release*.py`. Every Stenographer module constant becomes a field of a frozen `ReleaseConfig`, which is read from `release.json` and carried on the `Release` state object. `tools/apple/release_macos_app.py` is the single CLI. The skill lives in mydevsetup's shared payload and runs the CLI from the app's pinned toolkit submodule.

**Tech Stack:** Python 3.11+ stdlib, pytest, the existing `tools/apple/macos_release.py` (imported as `mr`).

**Spec:** `docs/specs/2026-10-16-release-macos-app-design.md` (read it before any task).

## Global Constraints

- **Toolkit worktree (every path below is relative to it unless stated otherwise):**
  `/Users/mfullerton/Development/projects/adkitchen/.claude/worktrees/release-macos-app/external/agenticdevelopertoolkit`
  on branch `adkitchen/release-macos-app`.
- **Stenographer sources, read-only, never modified:** `/Users/mfullerton/Development/projects/stenographer/`.
  - `scripts/release.py`, `release_verify.py`, `release_prepared.py`, `release_install.py`, `bundle_layout.py`, `app_processes.py`, `build_warnings.py`
  - the matching `tests/test_*.py`
- **Port, don't redesign.** Each ported function keeps Stenographer's logic, messages and docstrings. The only change is the generalization table below. A behaviour change needs a reason in the spec.
- **Generalization table** (Stenographer name → port):

  | Stenographer | port |
  |---|---|
  | `APP_NAME` | `r.cfg.app_name` |
  | `APP_BUNDLE_ID` | `r.cfg.bundle_id` |
  | `APP_IDENTITY` / `INSTALLER_IDENTITY` | `r.cfg.app_identity` / `r.cfg.installer_identity` |
  | `NOTARY_PROFILE` | `r.cfg.notary_profile` |
  | `SPARKLE_ACCOUNT` | `r.cfg.sparkle_account` |
  | `GITHUB_REPO` | `r.cfg.github_repo` |
  | `RELEASES_REPO` | `r.releases_repo` (defaults to `cfg.releases_checkout`) |
  | `DOWNLOAD_PREFIX` | `cfg.download_prefix` |
  | `DERIVED_DATA` | `r.derived_data` (defaults to `cfg.derived_data`) |
  | `PROJECT_YML` | `cfg.project_yml` |
  | `feed_url()` (read from the Info.plist) | `cfg.feed_url` |
  | `ROUTER_SWIFT` / `router_version_failures` | `versions.must_match_failures(cfg, version)` |
  | `WORKSPACE` | `cfg.resolve_*` |
  | `ENTITLEMENTS` / `HELPER_ENTITLEMENTS` | `cfg.entitlements` |
  | `DEVID_PROFILES` | `cfg.profiles` |
  | `WIDGET_PATH` checks | `cfg.nested_bundles` |
  | `bundle_layout.check` | `layout.problems(app, cfg)` |
  | `AgenticReleaseChannel` check | `cfg.expect_info` |
  | `INSTALLER_SCRIPTS_DIR` | `cfg.pkg_scripts` |
  | `LEGACY_MENUBAR_LABEL` in must-close | `cfg.pkg_must_close` |
  | `CASK_TEMPLATE` | `cfg.cask_template` (a file) |
  | `CASK_FILE` | `cfg.cask_file` |
  | `SOURCE_TAG_PREFIX` | `cfg.source_tag_prefix` |
  | `"main"` as the source branch | `cfg.source_branch` |
  | `"main"` on the releases repo | `cfg.releases_branch` |
  | `install.build_release` / `install_app` / `ensure_metal_toolchain` / `SKIP_PLUGIN_SELF_INSTALL` | `cfg.build_command` (run as the build hook) |
  | `STENOGRAPHER_*` env vars | none, except `RELEASE_RELEASES_CHECKOUT` (read in config) and each profile's `env` |
  | `REPO_DIR` defaults | explicit `repo`/`cfg` arguments, with no module globals |

- **Imports.** Package modules import siblings relatively (`from .config import ReleaseConfig`) and the primitives as `import macos_release as mr`. Tests live in `tools/apple/` and import `macos_app_release` and `macos_release` directly: pytest's default prepend mode puts `tools/apple` on `sys.path`, as it already does for `macos_release_test.py`.
- **Test file naming:** `tools/apple/macos_app_release_<area>_test.py`.
- **Test command:** `python3 -m pytest tools/apple -q`, run from the toolkit root.
- **Shared test fixtures:** in `tools/apple/macos_app_release_fixtures.py`. It is a plain module that tests import, not a conftest, so that no toolkit-wide conftest changes.
- **No test touches** a keychain, notarytool, GitHub, the network, `/Applications` or a real process. Every external command goes through an injected `Runner`, and every HTTP request through an injected `Fetch`.
- **Python only**, no shell scripts. Everything uses `from __future__ import annotations` and frozen dataclasses for config.
- **Subagents do NOT run git write commands.** The controller commits after each wave, staging only the files the wave touched.
- **Never run** `publish`, a GitHub release, a tag push or a site deploy against anything real.
- Commit trailer: `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Review Focus

1. **A `release.json` with a typo'd or missing key** must exit 2 and list *every* problem, not just the first, and must never fall back to a default silently. *Task 1: test that two problems are reported together.*
2. **A cask template that names an unknown `$variable`** must fail at render time, before anything is public. *Task 3: `cask_ruby` raises `KeyError`, caught as a build failure.*
3. **A `must_match` regex with zero or two groups**, or one that matches nothing in its file, is a config or preflight failure, never a silent pass. *Task 2.*
4. **`build.command` exits 0 but leaves no app at `RELEASE_APP_DEST`.** That is a clear failure naming the hook, not a later crash in the bundle checks. *Task 4.*
5. **A relative `releases.checkout`, or a `~` path**, resolves against the repo root or the home directory, never the cwd. *Task 1.*

## File Structure

```
tools/apple/macos_app_release/__init__.py          package marker, exports nothing
tools/apple/macos_app_release/config.py            Task 1
tools/apple/macos_app_release/shell.py             Task 1
tools/apple/macos_app_release/state.py             Task 2
tools/apple/macos_app_release/versions.py          Task 2
tools/apple/macos_app_release/profiles.py          Task 3
tools/apple/macos_app_release/sparkle.py           Task 3
tools/apple/macos_app_release/site.py              Task 3
tools/apple/macos_app_release/cask.py              Task 3
tools/apple/macos_app_release/layout.py            Task 3
tools/apple/macos_app_release/build_pipeline.py             Task 4
tools/apple/macos_app_release/publish.py           Task 5
tools/apple/macos_app_release/verify.py            Task 6
tools/apple/macos_app_release/processes.py         Task 7
tools/apple/macos_app_release/prepared.py          Task 7
tools/apple/macos_app_release/install.py           Task 7
tools/apple/macos_app_release/warnings.py          Task 8
tools/apple/release_macos_app.py                   Task 8 (CLI)
tools/apple/macos_app_release_fixtures.py          Task 1 (grown by later tasks)
tools/apple/macos_app_release_*_test.py            one per task
docs/release-macos-app.md                          Task 8 (release.json reference + adoption)
docs/examples/release-macos-app/release.json       Task 8
docs/examples/release-macos-app/cask.rb.template   Task 8
```

mydevsetup (Task 9), in `/Users/mfullerton/Development/mydevsetup/.claude/worktrees/release-skill`:

```
source/agents/skills/release-macos-app/SKILL.md
source/agents/skills/release-macos-app/hosts/claude.yaml
source/agents/skills/release-macos-app/hosts/claude.md
source/installer/manifest.json                 add "release-macos-app" to agents.skills
source/tests/test_release_macos_app_skill.py
```

Waves (tasks in one wave touch disjoint files and may run in parallel):

1. Task 1, then Task 2
2. Tasks 3 and 7
3. Tasks 4, 5 and 6
4. Tasks 8 and 9

---

### Task 1: Config and shell

**Files:**
- Create: `tools/apple/macos_app_release/__init__.py` (a docstring only)
- Create: `tools/apple/macos_app_release/config.py`
- Create: `tools/apple/macos_app_release/shell.py`
- Create: `tools/apple/macos_app_release_fixtures.py`
- Test: `tools/apple/macos_app_release_config_test.py`

**Interfaces — Produces:**

```python
# config.py
class ConfigError(Exception):
    problems: list[str]          # every problem found; str(e) joins them with newlines

@dataclass(frozen=True)
class MustMatch:  file: Path; pattern: str          # file absolute; pattern has exactly 1 group
@dataclass(frozen=True)
class Profile:    bundle: str; env: str; bundle_id: str; required: bool
@dataclass(frozen=True)
class BundleCheck: name: str; command: tuple[str, ...]

@dataclass(frozen=True)
class ReleaseConfig:
    repo: Path; main_checkout: Path
    app_name: str; bundle_id: str; title: str
    project_yml: Path; marketing_setting: str; build_setting: str
    must_match: tuple[MustMatch, ...]; nested_bundles: tuple[str, ...]
    regenerate: tuple[str, ...] | None
    build_command: tuple[str, ...]; derived_data: Path
    resolve_kind: str            # "workspace" | "project"
    resolve_path: Path; resolve_scheme: str
    expect_info: Mapping[str, str]
    layout_required: tuple[str, ...]; layout_forbidden: tuple[str, ...]; layout_required_globs: tuple[str, ...]
    checks: tuple[BundleCheck, ...]
    app_identity: str; installer_identity: str; notary_profile: str
    entitlements: Mapping[str, Path]          # bundle-rel -> absolute file
    profiles: tuple[Profile, ...]
    sparkle_account: str; feed_url: str; public_key_setting: str
    github_repo: str; releases_checkout: Path; releases_branch: str
    source_branch: str; source_tag_prefix: str
    site_routes: Mapping[str, str]            # keys: downloads, latest, appcast
    notes_dir: Path
    cask_token: str; cask_template: Path
    pkg_must_close: tuple[str, ...]           # bundle_id first, then extras, de-duplicated
    pkg_scripts: Path | None
    apps_dir: Path
    hook_tests: tuple[str, ...]; hook_warnings_build: tuple[str, ...]; hook_health: tuple[str, ...] | None
    warnings_allowlist: Path
    toolkit: Path
    # derived, as properties:
    site_origin: str        # scheme://netloc of feed_url
    download_prefix: str    # f"https://github.com/{github_repo}/releases/download"
    cask_file: str          # f"Casks/{cask_token}.rb"
    def notes_path(self, version: str) -> Path   # notes_dir / f"{version}.md"
    def source_tag(self, version: str) -> str    # source_tag_prefix + version

CONFIG_FILE = "release.json"
def load_config(repo: Path, *, main_checkout: Path | None = None,
                env: Mapping[str, str] | None = None, home: Path | None = None) -> ReleaseConfig
def parse_config(data: dict, *, repo: Path, main_checkout: Path,
                 env: Mapping[str, str], home: Path) -> ReleaseConfig

# shell.py
Runner = Callable[[list[str]], subprocess.CompletedProcess[str]]   # same shape as mr.Runner
def subprocess_runner(verbose: bool, *, cwd: Path | None = None) -> Runner
def check(proc, what: str) -> subprocess.CompletedProcess[str]      # port of release.py:299
def step(msg: str) -> None                                          # "==> msg"
def bullet(msg: str) -> None                                        # "  → msg"
def run_hook(argv: Sequence[str], *, cwd: Path, env: Mapping[str, str]) -> int   # streams output, returns the exit code
def capture_hook(argv: Sequence[str], *, cwd: Path, env: Mapping[str, str]) -> subprocess.CompletedProcess[str]
def main_checkout(repo: Path, run: Runner) -> Path   # parent of `git -C repo rev-parse --path-format=absolute --git-common-dir`
```

```python
# macos_app_release_fixtures.py — used by every later task's tests
class FakeRunner: ...            # copy of stenographer tests/test_release.py FakeRunner (responses + find)
def write_config(repo: Path, overrides: dict | None = None, *, flavor: str = "adkitchen") -> Path
    # writes release.json (deep-merged overrides) and every file it points at:
    # project.yml with MARKETING_VERSION/CURRENT_PROJECT_VERSION/<public_key_setting>,
    # entitlements files, cask template, warnings allowlist; returns repo/release.json
ADKITCHEN: dict      # the spec's minimal example (required keys only, plus app.title)
STENOGRAPHER: dict   # every optional key set: must_match, nested_bundles, 2 profiles,
                     # required_globs, expect_info, pkg.scripts, pkg.must_close extra, hooks.health
def config(tmp_path: Path, overrides=None, *, flavor="adkitchen") -> ReleaseConfig  # write + load
```

- [ ] **Step 1: Write the failing tests** in `macos_app_release_config_test.py`:

```python
from pathlib import Path
import json
import pytest
from macos_app_release import config as c
from macos_app_release_fixtures import config, write_config, ADKITCHEN, STENOGRAPHER

def test_minimal_config_resolves_every_default(tmp_path):
    cfg = config(tmp_path)
    repo = tmp_path / "repo"
    assert cfg.title == ADKITCHEN["app"]["title"]
    assert cfg.marketing_setting == "MARKETING_VERSION"
    assert cfg.build_setting == "CURRENT_PROJECT_VERSION"
    assert cfg.app_identity == "Developer ID Application"
    assert cfg.installer_identity == "Developer ID Installer"
    assert cfg.source_branch == "main" and cfg.source_tag_prefix == "release/"
    assert cfg.releases_branch == "main"
    assert cfg.releases_checkout == repo.parent / "adkitchen-releases"
    assert cfg.derived_data == tmp_path / "home/Library/Developer/Xcode/DerivedData/adkitchen-release"
    assert cfg.site_routes == {"downloads": "/downloads", "latest": "/downloads/latest",
                               "appcast": "/appcast.xml"}
    assert cfg.notes_path("1.2.0") == repo / "docs" / "release-notes" / "1.2.0.md"
    assert cfg.pkg_must_close == (cfg.bundle_id,)
    assert cfg.apps_dir == Path("/Applications")
    assert cfg.toolkit == repo / "external/agenticdevelopertoolkit"
    assert cfg.site_origin == "https://kitchen.agenticdevelopmentstudio.com"
    assert cfg.cask_file == "Casks/adkitchen.rb"
    assert cfg.source_tag("1.2.0") == "release/1.2.0"
    assert cfg.hook_health is None and cfg.regenerate is None

def test_stenographer_shape_loads(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    assert len(cfg.profiles) == 2 and cfg.profiles[0].required
    assert cfg.must_match[0].file.is_absolute()
    assert cfg.layout_required_globs == ("Contents/PlugIns/*.aiplugin",)
    assert cfg.expect_info == {"AgenticReleaseChannel": "release"}
    assert cfg.pkg_must_close[0] == cfg.bundle_id and len(cfg.pkg_must_close) == 2
    assert cfg.pkg_scripts is not None and cfg.hook_health is not None

def test_every_problem_is_reported_at_once(tmp_path):
    write_config(tmp_path / "repo", {"app": {"nmae": "x"}, "cask": {"token": None}})
    with pytest.raises(c.ConfigError) as e:
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})
    text = str(e.value)
    assert "app.nmae" in text and "unknown" in text
    assert "cask.token" in text
    assert len(e.value.problems) >= 2

@pytest.mark.parametrize("key", ["app.name", "app.bundle_id", "version.project_yml",
    "build.command", "build.resolve", "signing.notary_profile", "signing.entitlements",
    "sparkle.account", "sparkle.feed_url", "sparkle.public_key_setting",
    "releases.github_repo", "cask.token", "cask.template", "hooks.tests",
    "hooks.warnings_build", "warnings_allowlist"])
def test_required_key_missing_is_an_error(tmp_path, key):
    data = json.loads(write_config(tmp_path / "repo").read_text())
    section, _, leaf = key.partition(".")
    if leaf: del data[section][leaf]
    else: del data[section]
    with pytest.raises(c.ConfigError, match=key.replace(".", r"\.")):
        c.parse_config(data, repo=tmp_path / "repo", main_checkout=tmp_path / "repo",
                       env={}, home=tmp_path / "home")

def test_entitlements_must_name_the_app(tmp_path):
    write_config(tmp_path / "repo", {"signing": {"entitlements": {"Contents/MacOS/x": "a.entitlements"}}},
                 replace=("signing", "entitlements"))
    with pytest.raises(c.ConfigError, match=r'signing\.entitlements.*"\."'):
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})

@pytest.mark.parametrize("pattern", ["no groups", "(a)(b)", "([unclosed"])
def test_must_match_needs_exactly_one_group(tmp_path, pattern):
    write_config(tmp_path / "repo", {"version": {"must_match": [{"file": "x.swift", "pattern": pattern}]}})
    with pytest.raises(c.ConfigError, match="must_match"):
        c.load_config(tmp_path / "repo", home=tmp_path / "home", env={})

def test_paths_resolve_against_repo_home_or_absolute(tmp_path):
    cfg = config(tmp_path, {"releases": {"checkout": "~/rel"}, "build": {"derived_data": "/abs/dd"},
                            "notes_dir": "notes"})
    assert cfg.releases_checkout == tmp_path / "home/rel"
    assert cfg.derived_data == Path("/abs/dd")
    assert cfg.notes_dir == tmp_path / "repo/notes"

def test_env_overrides_the_releases_checkout(tmp_path):
    write_config(tmp_path / "repo")
    cfg = c.load_config(tmp_path / "repo", home=tmp_path / "home",
                        env={"RELEASE_RELEASES_CHECKOUT": str(tmp_path / "elsewhere")})
    assert cfg.releases_checkout == tmp_path / "elsewhere"

def test_releases_checkout_default_is_beside_the_main_checkout(tmp_path):
    write_config(tmp_path / "wt")
    cfg = c.load_config(tmp_path / "wt", main_checkout=tmp_path / "main", home=tmp_path / "home", env={})
    assert cfg.releases_checkout == tmp_path / "adkitchen-releases"

def test_missing_file_and_bad_json(tmp_path):
    (tmp_path / "repo").mkdir()
    with pytest.raises(c.ConfigError, match="release.json"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path)
    (tmp_path / "repo/release.json").write_text("{")
    with pytest.raises(c.ConfigError, match="JSON"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path)

def test_schema_must_be_1(tmp_path):
    write_config(tmp_path / "repo", {"schema": 2})
    with pytest.raises(c.ConfigError, match="schema"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")

def test_resolve_needs_exactly_one_of_workspace_or_project(tmp_path):
    write_config(tmp_path / "repo", {"build": {"resolve": {"scheme": "S"}}}, replace=("build", "resolve"))
    with pytest.raises(c.ConfigError, match="build.resolve"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")

def test_feed_url_must_be_https(tmp_path):
    write_config(tmp_path / "repo", {"sparkle": {"feed_url": "kitchen/appcast.xml"}})
    with pytest.raises(c.ConfigError, match="feed_url"):
        c.load_config(tmp_path / "repo", env={}, home=tmp_path / "home")
```

  `write_config(repo, overrides, *, flavor, replace=(section, key))`: `overrides` is deep-merged into the flavor's dict. `replace` names one nested key whose override value *replaces* the base value instead of merging into it. A `None` value in `overrides` deletes the key. Fix the first test's title assert to the exact `ADKITCHEN["app"]["title"]` value when writing the fixture.

  Fix the first test's title assert to the exact `ADKITCHEN["app"]["title"]` value. The fixture's default `home` is `tmp_path / "home"` and its repo is `tmp_path / "repo"`; `config()` loads with `env={}` and `main_checkout=repo`.

  Also add `macos_app_release_shell_test.py`:

```python
import subprocess, sys
from pathlib import Path
import pytest
from macos_app_release import shell

def test_check_raises_with_output():
    p = subprocess.CompletedProcess(["x"], 3, "out", "err")
    with pytest.raises(RuntimeError, match=r"thing failed \(exit 3\):\nerrout"):
        shell.check(p, "thing")

def test_capture_hook_passes_env_and_cwd(tmp_path):
    p = shell.capture_hook([sys.executable, "-c", "import os;print(os.getcwd());print(os.environ['X'])"],
                           cwd=tmp_path, env={"X": "1"})
    cwd, x = p.stdout.split()
    assert p.returncode == 0 and Path(cwd).resolve() == tmp_path.resolve() and x == "1"

def test_run_hook_returns_exit_code(tmp_path):
    assert shell.run_hook([sys.executable, "-c", "raise SystemExit(4)"], cwd=tmp_path, env={}) == 4

def test_main_checkout_is_parent_of_common_dir(tmp_path):
    def run(argv):
        assert argv[:3] == ["git", "-C", str(tmp_path / "wt")]
        return subprocess.CompletedProcess(argv, 0, str(tmp_path / "main/.git") + "\n", "")
    assert shell.main_checkout(tmp_path / "wt", run) == tmp_path / "main"
```

  `run_hook` and `capture_hook` merge `env` over `os.environ`. Tests pass `{}` and rely on PATH being inherited.

- [ ] **Step 2: Run the tests and confirm they fail.** Run `python3 -m pytest tools/apple/macos_app_release_config_test.py tools/apple/macos_app_release_shell_test.py -q`. Expected: ImportError.

- [ ] **Step 3: Implement `config.py`:**
  - Keep a schema table per section, mapping key → (required, kind), with kinds str / path / argv / list / map / bool.
  - Walk it, collecting every problem as a `"<dotted.key>: <what>"` string, and raise a single `ConfigError(problems)` at the end.
  - Report unknown keys as `"<dotted.key>: unknown key"`.
  - Path resolution: `~…` → `home / rest`; `/…` → absolute; anything else → `repo / value`.
  - `argv` values must be non-empty lists of strings.
  - Validate each `must_match` pattern with `re.compile(p).groups == 1`.
  - `build.resolve` must have exactly one of `workspace`/`project`, plus `scheme`.
  - `sparkle.feed_url` must parse with scheme `https` and a netloc.
  - `site.routes`, if given, must have exactly the keys `downloads`, `latest` and `appcast`.

  Implement `shell.py` exactly per the interfaces. `subprocess_runner` ports `release.py:269` and adds `cwd`.

- [ ] **Step 4: Run the tests and confirm they pass.** Same command. Expected: all pass.

---

### Task 2: Release state, provenance, versions

**Files:**
- Create: `tools/apple/macos_app_release/state.py`
- Create: `tools/apple/macos_app_release/versions.py`
- Test: `tools/apple/macos_app_release_state_test.py`
- Modify: `tools/apple/macos_app_release_fixtures.py` (add `release(tmp_path, runner, **kw) -> Release`)

**Interfaces:**
- Consumes: `ReleaseConfig`, `Runner`, and `check` from Task 1.
- Produces:

```python
# state.py
PROVENANCE = "provenance.json"
class AlreadyPublished(Exception): ...
@dataclass
class Release:   # port of release.py:310, plus cfg
    cfg: ReleaseConfig
    version: str; build_number: int; run: Runner
    verbose: bool = False; publish: bool = False
    branch: str | None = None        # None -> cfg.source_branch (resolve in __post_init__)
    site: str | None = None          # origin override; None -> cfg.site_origin
    artifacts_root: Path | None = None
    releases_repo: Path | None = None   # None -> cfg.releases_checkout
    derived_data: Path | None = None    # None -> cfg.derived_data
    env: dict[str, str] = field(default_factory=lambda: dict(os.environ))
    bin_path: Path | None = None; team: str | None = None
    profiles: dict[str, Path] = field(default_factory=dict)
    minimum_system_version: str = ""
    source_sha: str | None = None; publish_state: str | None = None
    # properties: repo (cfg.repo), out, app, zip_path, pkg_path, appcast_path, notes,
    # tag ("v"+version), source_tag, sparkle_bin, provenance_path, origin (site or cfg.site_origin)
SPARKLE_BIN_REL = Path("SourcePackages/artifacts/sparkle/Sparkle/bin")
def sha256_of(path: Path) -> str
def head_sha(r: Release) -> str | None
def tag_sha(r: Release) -> str | None
def source_tag_failures(r: Release) -> list[str]
def write_provenance(r: Release, *, notarized: bool) -> None
def artifact_failures(r: Release) -> list[str]
def git_count(r: Release, revs: str) -> int

# versions.py
def project_setting(name: str, text: str) -> str            # port release.py:223
def read_versions(cfg: ReleaseConfig) -> tuple[str, int]
def must_match_failures(cfg: ReleaseConfig, version: str) -> list[str]
def next_version(version: str, kind: str) -> str            # "patch" -> a.b.(c+1); "minor" -> a.(b+1).0
def bump(cfg: ReleaseConfig, kind: str, *, run: Runner) -> tuple[str, int]
    # rewrites project.yml settings (version, build+1) and each must_match group,
    # then runs cfg.regenerate (if set) via run from cfg.repo; returns (version, build)
```

- [ ] **Step 1: Write the failing tests.** Port `tests/test_release.py`'s tests for these functions:
  - `source_tag_failures`, `write_provenance`/`artifact_failures` (grep `provenance`, `artifact_failures`, `source_tag`);
  - `read_versions`;
  - `router_version_failures`, which becomes `must_match_failures` against the stenographer flavor's must_match file;
  - each `Release` property.

  Swap Stenographer's fake repo for the fixtures. Add these tests:

```python
from macos_app_release import versions as v

def test_next_version():
    assert v.next_version("1.0.154", "patch") == "1.0.155"
    assert v.next_version("1.0.154", "minor") == "1.1.0"
    assert v.next_version("2.9", "minor") == "2.10.0"   # a 2-part version gets a .0 patch

def test_bump_rewrites_yml_and_must_match_and_regenerates(tmp_path):
    from macos_app_release_fixtures import config, FakeRunner
    cfg = config(tmp_path, flavor="stenographer", overrides={"version": {"regenerate": ["xcodegen", "generate"]}})
    run = FakeRunner()
    assert v.bump(cfg, "minor", run=run) == ("1.1.0", 2)   # fixture starts at 1.0.154 / build 1
    assert v.read_versions(cfg) == ("1.1.0", 2)
    assert v.must_match_failures(cfg, "1.1.0") == []
    assert run.find("xcodegen", "generate")

def test_must_match_pattern_matching_nothing_fails(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    cfg.must_match[0].file.write_text("nothing here")
    assert v.must_match_failures(cfg, "1.0.154") and "matched nothing" in v.must_match_failures(cfg, "1.0.154")[0]

def test_bump_refuses_unknown_kind(tmp_path):
    with pytest.raises(ValueError):
        v.bump(config(tmp_path), "major", run=FakeRunner())
```

  The fixture project.yml must use Stenographer's quoting: `MARKETING_VERSION: "1.0.154"` and `CURRENT_PROJECT_VERSION: "1"`. `bump` rewrites the values in place and keeps the quoting.

- [ ] **Step 2: Run the tests and confirm they fail.** `python3 -m pytest tools/apple/macos_app_release_state_test.py -q`
- [ ] **Step 3: Implement.** Port `release.py:310-378` (`Release`), `:379-395`, and `:582-666`, using the generalization table.
- [ ] **Step 4: Run the tests and confirm they pass.** Then run `python3 -m pytest tools/apple -q` and confirm the existing tests still pass.

---

### Task 3: Profiles, Sparkle, site, cask, layout

**Files:**
- Create: `profiles.py`, `sparkle.py`, `site.py`, `cask.py`, `layout.py` under `tools/apple/macos_app_release/`
- Test: `tools/apple/macos_app_release_parts_test.py`

**Interfaces:**
- Consumes: `Release`, `ReleaseConfig`, `check`, `bullet`, `sha256_of`.
- Produces:

```python
# profiles.py — port release.py:235-267, 440-490, 855-888
EMBEDDED_PROFILE = Path("Contents/embedded.provisionprofile")
def identity_team(find_identity_stdout: str, prefix: str) -> str | None
def bundle_at(app: Path, rel: str) -> Path
def profile_fix(env: str, bundle_id: str) -> str
def profile_problems(r, profile: Path, bundle_id: str, team: str | None) -> list[str]
def profile_failures(r) -> list[str]
def step_provision(r) -> None
def check_developer_id_profile(r, rel: str = ".") -> None
def entitlements_map(app: Path, cfg) -> dict[Path, Path]

# sparkle.py — port release.py:241-257, 396-425, 918-968, 1034-1074
SPARKLE_NS = "http://www.andymatuschak.org/xml-namespaces/sparkle"
def sparkle_config_problems(info: dict) -> list[str]
def sparkle_public_key(cfg) -> str               # project_setting(cfg.public_key_setting, project.yml)
def generate_keys_command(r) -> str
def public_key_failure(r) -> str
def ensure_sparkle_tools(r) -> None              # xcodebuild -resolvePackageDependencies -<resolve_kind> <path> -scheme <scheme> -derivedDataPath <dd>
def enclosure_signature(appcast: Path, archive_name: str) -> str | None
def step_sparkle_verify(r) -> None
def generate_appcast(r) -> Path
def step_appcast(r) -> None
def bundle_info_problems(info: dict, cfg, *, version: str, build: int) -> list[str]
    # version/build match, every expect_info pair, SUFeedURL == cfg.feed_url,
    # LSMinimumSystemVersion present, plus sparkle_config_problems(info)

# site.py — port release.py:732-768
def http_status(r, url: str) -> str
def site_failures(r) -> list[str]                # probes r.origin + each cfg.site_routes path

# cask.py — port release.py:1087-1186
HOMEBREW_MACOS = {"14": ":sonoma", "15": ":sequoia", "26": ":tahoe"}
def homebrew_macos(minimum_system_version: str) -> str
def cask_ruby(entry: mr.ReleaseEntry, cfg) -> str
    # string.Template(cfg.cask_template.read_text()).substitute(version=, sha256=, url=, pkg=,
    #   name=cfg.title, homepage=cfg.site_origin, feed=cfg.feed_url, macos=, bundle_id=, token=)
    # url/pkg use brew's #{version}; keep Stenographer's self-check that the rendered url,
    # with #{version} expanded, equals entry.pkg.url, raising ValueError otherwise.
    # An unknown $name raises KeyError (substitute, not safe_substitute).

# layout.py — port bundle_layout.py
def problems(app: Path, cfg) -> list[str]   # required/forbidden paths + each required glob matches >= 1
```

- [ ] **Step 1: Write the failing tests.** Port every `test_release.py` test that covers these functions: grep `profile_`, `identity_team`, `sparkle_config`, `enclosure_signature`, `sparkle_verify`, `generate_appcast`, `step_appcast`, `http_status`, `site_failures`, `homebrew_macos`, `cask_ruby`, `entitlements_map`, `provision`. Also port all of `tests/test_bundle_layout.py`.
  - Stenographer's literal-cask assertions (daemon labels and so on) become assertions on a fixture template.
  - Add the `$version $sha256 $url $pkg $name $homepage $feed $macos $bundle_id $token` example template, written by `write_config`.
  - Add these tests:

```python
def test_cask_unknown_variable_fails(tmp_path):
    cfg = config(tmp_path)
    cfg.cask_template.write_text("cask \"$token\" do\n  version \"$nope\"\nend\n")
    with pytest.raises(KeyError):
        cask.cask_ruby(entry(cfg), cfg)

def test_cask_url_must_resolve_to_the_pkg(tmp_path):
    cfg = config(tmp_path)
    cfg.cask_template.write_text('cask "$token" do\n  url "https://example.com/x.pkg"\nend\n')
    # template that hardcodes a url not equal to entry.pkg.url
    with pytest.raises(ValueError, match="url"):
        cask.cask_ruby(entry(cfg), cfg)

def test_layout_glob_requires_a_match(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    app = tmp_path / "S.app"; (app / "Contents/PlugIns").mkdir(parents=True)
    for rel in cfg.layout_required: (app / rel).parent.mkdir(parents=True, exist_ok=True); (app / rel).touch()
    assert any("aiplugin" in p for p in layout.problems(app, cfg))

def test_bundle_info_problems_names_each(tmp_path):
    cfg = config(tmp_path, flavor="stenographer")
    info = {"CFBundleShortVersionString": "1.0.154", "CFBundleVersion": "1",
            "SUFeedURL": "https://wrong/appcast.xml", "SUPublicEDKey": "k",
            "LSMinimumSystemVersion": "15.0"}
    problems = sparkle.bundle_info_problems(info, cfg, version="1.0.154", build=1)
    assert any("SUFeedURL" in p for p in problems)
    assert any("AgenticReleaseChannel" in p for p in problems)
```

  `entry(cfg)` builds an `mr.ReleaseEntry`. Put it in the fixtures module.
- [ ] **Step 2: Run the tests and confirm they fail.** `python3 -m pytest tools/apple/macos_app_release_parts_test.py -q`
- [ ] **Step 3: Implement**, porting with the generalization table.
- [ ] **Step 4: Run the tests and confirm they pass.**

---

### Task 4: Build pipeline

**Files:**
- Create: `tools/apple/macos_app_release/build_pipeline.py`
- Test: `tools/apple/macos_app_release_build_test.py`

**Interfaces:**
- Consumes: everything from Tasks 1-3.
- Produces:

```python
BUILD_STEPS = ["preflight", "build", "check-bundle", "provision", "sign", "notarize-app",
               "update-zip", "appcast", "sparkle-verify", "pkg", "notarize-pkg"]
def step_preflight(r) -> None          # port release.py:491-581 (release + publish preflight; Task 5 imports publish_preflight)
def release_preflight(r, public_key: str, failures: list[str]) -> None
def publish_preflight(r, public_key: str, failures: list[str]) -> None
def releases_repo_failures(r) -> list[str]   # port :769, using cfg.releases_branch
def submodule_drift(r) -> list[str]          # port :812
def build_env(r) -> dict[str, str]           # r.env + RELEASE_APP_DEST/RELEASE_DERIVED_DATA/RELEASE_VERSION/RELEASE_BUILD
def step_build(r) -> None   # drift refusal, then rm -rf staging app, mkdir parent, run cfg.build_command via r.run
                            # with cwd=cfg.repo (wrap: ["/usr/bin/env", *[f"{k}={v}" for the RELEASE_* vars], *cmd]
                            # so the injected Runner sees one argv); fail if exit != 0 OR r.app missing
def step_check_bundle(r) -> None  # bundle_info_problems + layout.problems + each cfg.checks (env RELEASE_APP)
def step_sign(r) -> None; step_notarize_app; step_update_zip; step_pkg; step_notarize_pkg
def distribution_xml(r) -> str    # port :969, must_close=cfg.pkg_must_close
def release_entry(r, *, now=None) -> mr.ReleaseEntry   # port :1021
def build_steps() -> dict[str, Callable[[Release], None]]
def run_build(r) -> int           # runs BUILD_STEPS in order, prints step(), returns 0/1, prints failures (port main's loop)
```

  `step_build` runs the hook through `r.run` so tests can fake it. The `/usr/bin/env K=V … cmd` prefix carries the variables. The working directory is set by `run`, which `subprocess_runner(cwd=cfg.repo)` provides; the CLI builds it.

- [ ] **Step 1: Write the failing tests.** Port `test_release.py`'s tests for `step_preflight`, `release_preflight`, `releases_repo_failures`, `submodule_drift`, `step_build`/`step_assemble` (now `step_check_bundle`), `step_sign`, `step_notarize_*`, `step_update_zip`, `distribution_xml`, `step_pkg`, `release_entry` and the main loop. Run them against **both** fixture flavors where flavor matters (`@pytest.mark.parametrize("flavor", ["adkitchen", "stenographer"])`). Add:

```python
def test_build_hook_that_leaves_no_app_fails_naming_the_hook(tmp_path):
    r = release(tmp_path, FakeRunner())
    with pytest.raises(RuntimeError, match=r"build\.command.*RELEASE_APP_DEST"):
        build.step_build(r)

def test_build_hook_gets_release_env(tmp_path):
    seen = {}
    def run(argv):
        if argv[0] == "/usr/bin/env":
            seen.update(a.split("=", 1) for a in argv[1:] if "=" in a and a.startswith("RELEASE_"))
            Path(seen["RELEASE_APP_DEST"]).mkdir(parents=True)
        return subprocess.CompletedProcess(argv, 0, "", "")
    r = release(tmp_path, run)
    build.step_build(r)
    assert seen["RELEASE_APP_DEST"] == str(r.app) and seen["RELEASE_VERSION"] == r.version

def test_bundle_check_command_failure_stops(tmp_path):
    r = release(tmp_path, FakeRunner([(lambda a: a[-1] == "check-x", 1, "bad thing")]),
                overrides={"checks": [{"name": "x", "command": ["check-x"]}]})
    make_app(r)   # fixture: a layout-correct bundle with a matching Info.plist
    with pytest.raises(RuntimeError, match="bad thing"):
        build.step_check_bundle(r)
```

  Add `make_app(r)` to the fixtures. It writes a bundle at `r.app` that satisfies `layout.problems` and `bundle_info_problems`.
- [ ] **Step 2: Run the tests and confirm they fail.**
- [ ] **Step 3: Implement**, porting `release.py:491-1033` and `1223-1275`.
- [ ] **Step 4: Run the tests and confirm they pass.** `python3 -m pytest tools/apple -q`

---

### Task 5: Publish pipeline

**Files:**
- Create: `tools/apple/macos_app_release/publish.py`
- Test: `tools/apple/macos_app_release_publish_test.py`

**Interfaces:**
- Consumes: `build.step_preflight`, `sparkle.step_appcast`, `sparkle.step_sparkle_verify`, `cask.cask_ruby`, `state.*`, `build.release_entry`.
- Produces:

```python
PUBLISH_STEPS = ["preflight", "appcast", "sparkle-verify", "publish"]
def release_files(cfg) -> tuple[str, ...]   # ("releases.json", "notes/{version}.md", "appcast.xml", cfg.cask_file)
def load_releases_json(r) -> dict            # port :426
def github_release_assets(r) -> list[dict] | None   # :667
def asset_mismatches(r, assets) -> list[str]        # :680
def publish_state(r) -> str                          # :701 ; raises AlreadyPublished
def step_publish(r) -> None                          # :1187 ; pushes origin cfg.releases_branch
def run_publish(r) -> int     # AlreadyPublished -> print + 0; state "push" skips appcast + sparkle-verify
```

- [ ] **Step 1: Write the failing tests.** Port every `test_release.py` test covering `publish_state`, `asset_mismatches`, `github_release_assets`, `step_publish`, `--publish` main runs, and the skips when `push`. Add:

```python
def test_publish_writes_cask_at_configured_token(tmp_path): ...  # Casks/adkitchen.rb exists and git add names it
def test_publish_pushes_the_configured_branch(tmp_path): ...     # releases.branch "trunk" -> ["git", ..., "push", "origin", "trunk"]
```

  Write both with full bodies, modelled on the ported `step_publish` test.
- [ ] **Step 2: Run the tests and confirm they fail.** **Step 3: Implement.** **Step 4: Run the tests and confirm they pass.**

---

### Task 6: Verifier

**Files:**
- Create: `tools/apple/macos_app_release/verify.py`
- Test: `tools/apple/macos_app_release_verify_test.py`

**Interfaces:**
- Consumes: `ReleaseConfig`, `state.sha256_of`, `sparkle.SPARKLE_NS`, `versions.read_versions`.
- Produces: a port of all of `release_verify.py`.
  - `Fetched`, `Fetch`, `http_fetch`, `tool_runner`, `Expected`, `Check`, `local_digests`, `published_entry`
  - `check_github`, `check_feed`, `check_cask`, `check_downloads`, `check_latest`, `check_appcast`, `check_pkg`, `check_zip`
  - `check_once`, `poll_until_ready`, `DEFAULT_TIMEOUT = 900`, `DEFAULT_INTERVAL = 30`
  - plus:

```python
def raw_base(cfg) -> str      # f"https://raw.githubusercontent.com/{cfg.github_repo}/{cfg.releases_branch}/"
def expected_for(cfg, version: str | None, site: str, fetch: Fetch, *, artifacts_root: Path | None = None) -> Expected
def run_verify(cfg, *, version, site, timeout, interval, as_json, fetch=http_fetch, run=None, sleep=time.sleep, monotonic=time.monotonic) -> int
```

  `Expected` carries `cfg`, so `check_cask` uses `cfg.cask_file` and the downloads, latest and appcast checks use `cfg.site_routes`. `--site` replaces the origin and keeps the routes.

- [ ] **Step 1: Port all of `tests/test_release_verify.py`.** Add one test with `site_routes` overridden (for example `"/dl"`) asserting the fetched URL uses it.
- [ ] **Steps 2-4:** Confirm the tests fail, implement the port, then confirm they pass.

---

### Task 7: Processes, prepared, install, installed

**Files:**
- Create: `processes.py`, `prepared.py`, `install.py` under the package
- Test: `tools/apple/macos_app_release_install_test.py`

**Interfaces:**
- Consumes: `Release`, `state.*`, `layout.problems`, `versions.read_versions`.
- Produces:

```python
# processes.py — all of app_processes.py
def own_ps(fields: str) -> str; bundle_prefixes(app) ; parse_bundle_pids(output, app) ; bundle_pids(app)
def signal_pid(pid, sig, *, kill=None) ; quit_pids(find, *, term_wait, kill_wait, first=None, kill=None, sleep=time.sleep, monotonic=time.monotonic)

# prepared.py — release_prepared.py
def main_failures(r) -> list[str]; staged_failures(r) -> list[str]   # nested_bundles replace the widget
def prepared_failures(r) -> dict[str, list[str]]
def run_prepared(r, *, as_json: bool) -> int

# install.py — release_install.py + installed check
QUIT_TIMEOUT_S = 10.0; REAP_TIMEOUT_S = 5.0
def quit_app(app, *, pids, kill, sleep, monotonic) -> None
def install(zip_path: Path, cfg, *, apps_dir: Path | None = None, run=..., pids=..., kill=..., sleep=..., monotonic=...) -> None
    # app name f"{cfg.app_name}.app"; layout gate = layout.problems(extracted, cfg)
def installed_failures(cfg, *, apps_dir: Path | None = None, run, pids) -> list[str]
    # installed Info.plist version/build == read_versions(cfg); codesign -dv authority starts
    # "Developer ID Application"; layout.problems == []; at least one pid in bundle
```

- [ ] **Step 1: Port `tests/test_app_processes.py`, `tests/test_release_prepared.py` and `tests/test_release_install.py`.** Add `installed_failures` tests covering a version mismatch, a non-Developer-ID signature, and not running.
- [ ] **Steps 2-4:** Confirm the tests fail, implement the port, then confirm they pass.

---

### Task 8: Warnings gate, CLI, docs

**Files:**
- Create: `tools/apple/macos_app_release/warnings.py` (a port of `build_warnings.py`, with `load_allowlist(path)` required and no default)
- Create: `tools/apple/release_macos_app.py`
- Create: `docs/release-macos-app.md`, `docs/examples/release-macos-app/release.json`, `docs/examples/release-macos-app/cask.rb.template`
- Test: `tools/apple/macos_app_release_cli_test.py`

**Interfaces:**
- Consumes: everything.
- Produces: the CLI from the spec's table. `main(argv=None, *, run=None, fetch=None) -> int`.
  - **Exit codes:** 0 ok; 1 failure; 2 for `ConfigError` (print each problem) or argparse errors.
  - **`--repo`** defaults to `git rev-parse --show-toplevel` of the cwd.
  - **`main_checkout`** comes from `shell.main_checkout`.
  - **`status --json`** keys: `app`, `version`, `build`, `notes`, `notes_exists`, `source_tag`, `releases_checkout`, `latest_published` (`{"version", "publishedAt"}` or null, from the releases checkout's `releases.json`), `hooks` (`{"tests": bool, "warnings_build": bool, "health": bool}`), `artifacts_default`, `toolkit`.
  - **`warnings`:**
    1. Create `tempfile.mkdtemp(prefix="release-warnings-")`.
    2. Run `hook_warnings_build` with `RELEASE_WARNINGS_DERIVED_DATA` set to it, capturing output.
    3. Write the log to `--log-dir/warnings-build.log` (default: the temp dir's parent).
    4. Delete the DerivedData.
    5. Gate the log: a hook exit other than 0 prints the log tail and returns 1.
  - **`hook NAME`**: `run_hook(cfg.hook_<name>)`. A hook that isn't set exits 2 with `"<name> hook is not configured"`.

- [ ] **Step 1: Write the failing tests.** Port `tests/test_build_warnings.py` into `warnings` tests. CLI tests:
  - `status --json` against both flavors;
  - a bad config exits 2 and prints every problem;
  - `bump minor` prints the new version;
  - `hook health` exits 2 when it isn't set;
  - `hook tests` passes the exit code through (with a `sys.executable -c` hook);
  - `warnings`, with a hook printing one allowlisted and one unaccepted warning, exits 1 and names the unaccepted one;
  - `build` with a FakeRunner runs the build steps in order (preflight can fail fast: assert exit 1 and the preflight output).
- [ ] **Step 2: Run the tests and confirm they fail.** **Step 3: Implement.**
  - `docs/release-macos-app.md`:
    - every `release.json` key, with its type, default and meaning (from the spec's field contracts);
    - the hook environment variables;
    - how to adopt (add `release.json`, the cask template, a warnings allowlist and the hooks; create `<app>-releases`);
    - the owner prerequisites (certificates, `xcrun notarytool store-credentials <profile>`, Sparkle `generate_keys --account <account>`, `gh auth`).
  - The examples are the spec's adkitchen JSON and a cask template using every variable.
- [ ] **Step 4: Run the tests and confirm they pass.** `python3 -m pytest tools/apple -q`. Then run `python3 tools/apple/release_macos_app.py --help` and confirm it lists every command.

---

### Task 9: The `/release-macos-app` skill (mydevsetup)

**Files** (in `/Users/mfullerton/Development/mydevsetup/.claude/worktrees/release-skill`):
- Create: `source/agents/skills/release-macos-app/SKILL.md`
- Create: `source/agents/skills/release-macos-app/hosts/claude.yaml`
- Create: `source/agents/skills/release-macos-app/hosts/claude.md`
- Modify: `source/installer/manifest.json`, adding `"release-macos-app"` to `agents.skills`, alphabetically between `"proj"` and `"remember"`
- Test: `source/tests/test_release_macos_app_skill.py`

**Interfaces:**
- Consumes: the CLI commands from Task 8. The skill names them exactly: `status --json`, `bump patch|minor`, `hook tests`, `warnings`, `build --branch release-preparation --artifacts-root <MAIN>/build/release`, `install <zip>`, `installed`, `prepared`, `publish`, `verify`, `verify --timeout 0 --json`.

- [ ] **Step 1: Write the failing test** `test_release_macos_app_skill.py`, which pins these points:

```python
from pathlib import Path
import json
REPO_ROOT = Path(__file__).resolve().parent.parent
SKILL = REPO_ROOT / "agents/skills/release-macos-app"

def text(): return (SKILL / "SKILL.md").read_text()

def test_frontmatter_names_the_skill():
    assert text().startswith("---\nname: release-macos-app\n")

def test_ship_is_called_without_squash():
    t = text()
    assert "/ship -rebase -docs" in t
    assert "-squash" not in t.replace("`-squash`", "")   # only ever mentioned as the removed token

def test_model_invocation_is_disabled_for_claude():
    assert "disable-model-invocation: true" in (SKILL / "hosts/claude.yaml").read_text()

def test_cli_path_is_the_pinned_toolkit():
    assert "tools/apple/release_macos_app.py" in text()

def test_both_modes_documented():
    t = text()
    for needle in ("prepare", "publish", "hotfix", "--site", "release-preparation",
                   "git push origin release/", "verify --timeout 0 --json"):
        assert needle in t

def test_never_deploys_the_site():
    assert "never deploys the website" in text().lower() or "never deploy the website" in text().lower()

def test_registered_in_manifest():
    skills = json.loads((REPO_ROOT / "installer/manifest.json").read_text())["agents"]["skills"]
    assert "release-macos-app" in skills and skills == sorted(skills)
```

  (Before relying on it, confirm the manifest's `agents.skills` key path by reading `manifest.json` around line 280.)
- [ ] **Step 2: Run the test and confirm it fails.** From `source/`: `python3 -m pytest tests/test_release_macos_app_skill.py -n 0 -q`.
- [ ] **Step 3: Write the skill.**
  - **`SKILL.md`** is host-neutral:
    - It must not mention Claude, `PushNotification`, `ToolSearch`, `EnterWorktree` or `cwt`.
    - The shared-payload neutrality tests must stay green.
    - It ports Stenographer's `.claude/skills/prepare-release/SKILL.md` and `.claude/skills/release/SKILL.md`, merged into two modes per the spec's "The skill" section.
    - Every Stenographer path and script becomes a CLI call. `CLI` is `python3 external/agenticdevelopertoolkit/tools/apple/release_macos_app.py`, or the `toolkit` value that `status --json` reports.
    - The production rule appears near the top: typing the command is the owner's explicit trigger for exactly one release of one app; the skill never deploys the website, and it never re-runs `publish` after a part-way failure without the owner's explicit yes.
  - **`hosts/claude.yaml`:** `disable-model-invocation: true`, plus `argument-hint: "prepare [hotfix] | publish [hotfix] [--site ORIGIN]"`.
  - **`hosts/claude.md`:**
    - At the end of publish (step 6), and on any failure, send `PushNotification` (loaded with `ToolSearch select:PushNotification`).
    - Use `EnterWorktree` for the `proj wt create` ENTER directive.
- [ ] **Step 4: Run the tests and confirm they pass.** Run the new test, then the neutrality suites: `python3 -m pytest tests/test_release_macos_app_skill.py tests/test_shared_payload_neutrality.py tests/test_host_only_capability_leaks.py -n 0 -q`. Then run the full suite: `python3 -m pytest`.
- [ ] **Step 5:** Run `python3 source/update-version.py` from the repo root. The controller then commits and pushes.

---

## Execution Notes

- **Controller commits after each wave**, on the toolkit branch, staging only the wave's files:
  `git -C <toolkit> add <files>`, then `git -C <toolkit> commit -F <msgfile>`, then `git -C <toolkit> push`.
- **After Task 8**, bump the adkitchen worktree's submodule pointer and commit it on adkitchen's `release-macos-app` branch, so adkitchen pins the toolkit that has the CLI.
- **A whole-branch review at the end** covers both repos' full branches.
