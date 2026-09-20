# Godot hosts — the integration ledger

This is where the effort to put `addons/rad/` into the organisation's other
Godot projects is tracked. One section per host, a status line that moves only
with a commit in that host or in this repository, and a dated log at the end.
A claim in this page links to what makes it true; a host's own `DESIGN.md` and
`DECISIONS.md` are where its decision lands, and nothing here puts anything
there.

**Status vocabulary.** `not started` → `proposed in host` (a `[PROPOSED]`
bullet in the host's design document, on a pull request there) → `in flight`
(a branch in the host consuming a tagged `addons/rad/`) → `consuming <tag>`
(merged, lock in place, host gate green) → `retired`.

## How a host consumes the addon

The same shape for every host, and the shape this repository already uses for
rad's vectors:

1. **Copy, do not submodule.** The host copies `addons/rad/` from a version
   tag of this repository (version-tags-are-claims: a tag is the only thing
   that asserts the addon works). A submodule would mount the graph scene, the
   test harness and the records into a game; the seam is one directory.
2. **Lock it.** `addons/rad/rad.lock` in the host records
   `{rad_godot_ref, tag, sha256}` where the hash is over the copied tree, and a
   host check recomputes it on every run — `tools/check_vector_pin.py` here is
   the pattern, and a host takes it as `tools/check_rad_lock.py`. Upgrading is
   one reviewed change to the directory and the lock together.
3. **Provide a resolver, connect one signal.** The host writes
   `resolve(context) -> MenuSpec` in its own vocabulary and connects
   `committed(intent)` to the object that owns its state. The menu holds no
   reference to the game.
4. **Add one test in the host.** Every verb the resolver offers is applied
   through the host's state object and nowhere else — the contract's "the menu
   never mutates the scene", asserted where the scene is.
5. **Keep the host's own gates.** Its docs-coupling check, its engine pin, its
   headless suite. The addon adds no gate to a host; it adds a lock.

The first host outside this repository is the scope record's split trigger:
when it consumes the addon, `addons/rad/` moves to its own repository and the
graph scene here becomes a host like any other. That is planned, not feared.

## titanharvest

| | |
|---|---|
| Repository | `quaternionmedia/titanharvest`, private; local clone at `Documents/titanharvest` |
| Family | `games` (org record on `evolve/games-family`) |
| Shared ground | Godot `4.7.2-stable` by the same pin file; gdUnit4 vendored the same way; `tools/dev.ps1 check\|test` the same loop |
| **Where the menu fits** | `docs/DESIGN.md` §5.2 *The verbs* — the `[OPEN]` fork between source 2's **tools** (shovel, scythe, sledgehammer, water cannon with modes electrification / pressure jet / caustic chems) and source 3's **weapons** (autocannon, missile launcher, flamethrower, laser, melee). Every reading of that fork is a ring of at most eight with at most one submenu (the water cannon's modes), and §5.3's sidegrades are a second ring per item at most. The ring renders whichever roster the fork picks, so it does not prejudge the fork — it is the surface the fork is played on. |
| Vocabulary | `equip:<tool>` and `mode:<mode>` as host verbs; later `upgrade:*` / `sidegrade:*` from §5.3 |
| Input | Desktop first: right-click or a held key opens (tap-select), long-press on touch (release-select); keyboard by the nine cells — four tools sit at the cardinals, where `cellAgreesWithRing` is true. A gamepad is the nine-cells record's own trigger ("a surface with directions but no digits") and is not promised. |
| **First needed at** | **M2 — The Field** ("break rock, dig, water, harvest with the tools"); the fork is decided at M3's gate. |
| Needs from rad-godot | v0.0.2 at least (session, renderer, keyboard path); v0.0.3's store pattern is the shape §5.2's host wiring should copy. |
| Host-side blockers | M1 (the dome) is next there, not M2. The contributor's slot is free: PR #2 merged as `a5d3216`. |
| **Status** | `proposed in host` — on `main` since PR #3 (`1b86508`): the `[PROPOSED]` bullet in `DESIGN.md` §5.2 and its pending-list line, awaiting ratification in `DECISIONS.md`. The PR's gates (docs coupling, gdUnit4 headless) ran green; the docs check had been seen red first with the pending list one short. |
| Next step | Ratify or strike in `DECISIONS.md`. Nothing else until M2 opens. |

**Proposal text, as committed on that branch** (a `[PROPOSED]` bullet in §5.2;
the pending list in `DECISIONS.md` gained "the tool swap is a rad ring"):

> - `[PROPOSED]` **The tool swap is a rad ring.** Whichever reading of the
>   verbs fork is taken, the mech selects its tool from a radial menu that is
>   `rad-godot`'s `addons/rad/`, copied at a version tag and locked by hash,
>   with this project's resolver naming the roster and its modes. The ring
>   commits intents; the mech applies them. Release-select on touch,
>   tap-select on desktop, and the numpad cells for the keyboard. This does
>   not decide the fork: it decides what the fork is played on, and it makes
>   the M3 gate a comparison between rosters rather than between menus.

## golfvs

| | |
|---|---|
| Repository | `quaternionmedia/golfvs`, public; cloned 2026-09-19 to `Documents/golfvs` (the vault folder `Documents/pk/qmp/golfvs` is empty and is not a clone) |
| Family | `games` |
| Shared ground | Godot `4.7.2.stable` pinned (its ADR-008), gdUnit4 vendored, a docs-coupling check of the same shape |
| **Where the menu does not fit**, and why | The stroke (one continuous gesture, ADR-007), the club selector (a wordless bar, ADR-018), and the whole first run (pillar 3: "no menus between the urge to play and the first swing"; ADR-014: zero words). Nothing here proposes a ring anywhere a new player is. |
| **Where it fits** | `docs/DESIGN.md` §11.4 *DefensePlan* — the human defender's authoring surface. A long-press on the ground opens a ring of sports the budget still allows (the contract's canvas → `add-node` shape); a long-press on a placed defender opens focus triggers (`apex` / `landing` / `crossing_altitude`), `move` and `remove` (node → configure / delete). ADR-009's rule that exactly one defender may move between lies is the resolver setting `enabled: false` on the others — a greyed wedge the machine refuses to commit, which the vectors already pin. The M4 replay forks (Retry / Defend / Ghost) at a scrub point are a second, smaller ring. |
| Vocabulary | `place:<sport>`, `focus:<trigger>`, `move`, `remove`; `fork:retry` / `fork:defend` / `fork:ghost` |
| Input | One thumb: release-select is the primary style; the ring is fitted to a phone viewport by `fitRing` / `clampRingCentre`, which the vectors pin at small sizes. |
| **First needed at** | **M5 — Local + Postal** ("Pass-and-play VS (placement UI, budget)", Defense Range re-planning); M4's fork ring is a possible earlier point. The project is at M0 with M1–M3 work ahead of it. |
| Needs from rad-godot | v0.0.2 plus the touch checklist from the scope record's Q4 (a 2D or touch mode for the host here, so the checklist is run on a phone before a phone game copies the addon). **Symbols by default, words eventual** — the human's reading, 2026-09-19: golfvs shows icons on the wedges and the name in the accessibility tree at first, and shows words when the project decides to; every item carries its label from the start, so turning words on is a theme change. The question for rad upstream is therefore narrower than "is icon-only conformant": it is whether a renderer may *hide* a label it holds, which is a theme decision under rad's token record rather than a contract one. Raise it there before M5; rad-android's icon-first wedges with the name in the hub on highlight are the precedent. |
| Host-side blockers | One open pull request (#1, `camera-orbit-and-selector-corner`, ADR-020 to ADR-030) holds the contributor's slot. Its head was read for this page: placement stays at M5, the first run gains no menu, and §11.4 is byte-identical to `main`'s, so the branch below rebases clean when #1 lands. |
| **Status** | `proposed in host` — on the pushed branch `origin/docs/rad-defence-ring` (commit `48dedef` off `e904819`, clone at `Documents/golfvs`), no pull request while #1 holds the slot. Its gates were run locally on the branch: docs check (seen red with the pending list one short, then green), import, the gdUnit4 suite, and the headless round replaying every stroke to its own hash. |
| Next step | When #1 merges: rebase, open the pull request; ratify or strike in `DECISIONS.md`. Raise the hidden-label question in rad's records before M5. |

**Proposal text, as committed on that branch** (a `[PROPOSED]` bullet in §11.4;
the pending list gained "DefensePlan authored through a rad ring"):

> - `[PROPOSED]` **The plan is authored through a rad ring.** Placement and
>   focus are set by long-press: on the ground, a ring of the sports the
>   budget still allows; on a defender, its focus trigger, `move` and
>   `remove`, with `move` enabled on exactly one defender per lie (ADR-009)
>   and greyed on the rest — a wedge the menu refuses to commit. The ring is
>   `rad-godot`'s `addons/rad/`, copied at a version tag and locked by hash;
>   the resolver is this project's, and the intents are applied by
>   `DefensePlan`, so a human's plan and an AI's stay one code path. It draws
>   **symbols by default** — an icon on each wedge, the name in the
>   accessibility tree — and **words when this project decides to show them**:
>   every item carries its label from the start, so turning words on is a
>   theme change and not a redesign. Nothing about the stroke, the club
>   selector (ADR-018) or the first run (ADR-014) changes; the ring first
>   appears where a human defends a whole hole, at M5.

## Log

| Date | Host | Event |
|---|---|---|
| 2026-09-19 | both | Ledger opened. Where each host would use the ring read from its design document at the host's current head (golfvs: the open pull request's head). Both contributor slots occupied by in-flight pull requests; nothing proposed in either host yet. |
| 2026-09-19 | titanharvest | PR #2 merged (`a5d3216`); slot free. Local branch `docs/rad-tool-ring` (`a98e291`) carries the §5.2 proposal, the pending-list line and a handoff section; docs check seen red then green. Not pushed, by instruction. Status → `proposed in host`. |
| 2026-09-19 | golfvs | Cloned to `Documents/golfvs`. Local branch `docs/rad-defence-ring` (`48dedef`) carries the §11.4 proposal with the human's reading — symbols by default, words eventual — the pending-list line and a handoff item; docs check seen red then green. PR #1 still holds the slot; §11.4 unchanged on its head. Status → `proposed in host`. |
| 2026-09-19 | titanharvest | Branch pushed; PR #3 opened, assigned to the requester, no reviewer; gates green; merged by its author as `1b86508` (the repository's own precedent, PR #2). Branch and worktree removed; local `main` fast-forwarded. |
| 2026-09-19 | golfvs | Branch pushed as `origin/docs/rad-defence-ring` after its three gates ran green locally. No pull request: #1 holds the slot. |
