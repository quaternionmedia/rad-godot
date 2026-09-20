# DRAFT — rad-godot adoption and scope

| | |
|---|---|
| **Status** | Draft |
| **Date** | 2026-09-19 |
| **Pends on** | rad: interaction contract, the menu addresses nine cells, platform plans, adoption and scope; qm: version-tags-are-claims, seams-on-standard-protocols, human-only contributorship |
| **Principle** | `seams-on-standard-protocols`; `decisions-are-documented`; `minimal-legible-deliverables` |

## Context

rad's platform-plans record orders the ports by host: web first, Android
second, and for every other surface it says only that the machine is
renderer-free and that a front end on an unnamed platform consuming the same
vectors "is the test that the seam is real". A Godot host has arrived: a small
3D graph editor whose whole interaction surface — create, connect, move, colour
— is direct manipulation of nodes and edges, which is the vocabulary the
contract was written for. That makes it the surface on which the seam is
tested, and this record is the plan for doing so.

The org's family record places a radial menu outside every roster family: it
is substrate, built into a host and shipping inside it. "The rad family" in
this repository's name therefore means the implementations of one contract —
`rad`, `rad-android`, `rad-godot` — and claims no roster family for any of them.

## 1. Scope

rad-godot is **two things in one repository**, split the day a second host
wants the first:

- **The addon**, `addons/rad/`: a portable menu for any Godot project. A pure
  core replaying rad's vectors; a session that turns pointer, key and cell
  input into machine events; a renderer that draws the ring. The addon holds
  no host reference and mutates nothing: it emits intents.
- **The host**, the graph scene: a demonstration that every node, edge, canvas
  and selection verb in the contract's standard vocabulary can be reached
  through the menu and applied through the host's own state.

Out of scope for the `0.0.x` line: a running MIDI clock or quantized
scheduler (the pure time functions are ported because the vectors require
them; nothing schedules); chord input beyond plain HID key timing; export
targets other than the desktop the loop runs on; persistence of the graph;
any network capability.

## 2. Revision triggers this repository knowingly trips

Named at plan time, as `rad-android` did, because drift is data:

1. **rad platform plans — host ordering.** "A host appears for a platform not
   named here … the ordering is about hosts, not platforms." This is that
   host. Consequence accepted: nothing from qmetronome's clock ground
   transfers, and no timing feature is claimed.
2. **rad adoption and scope — a further implementation ships.** rad's scope
   record owes an amendment when the renderer milestone here is claimed, and
   its platform-plans record owes a Godot section.
3. **rad core extraction (C13).** The reference core is read out of the
   single-file `index.html` between its banners, not out of a `core/`
   directory. Attested here as a second port that paid that cost. The port
   records the line range it was read from.
4. **Text in wedges, twelve characters.** Graph node labels are user-typed.
   The host's resolver shortens; the menu never ellipsizes. If the rule cannot
   hold on this surface, the answer is a vector upstream and not a workaround.
5. **The menu addresses nine cells — "a pointer-first host reports that the
   cell numbering constrains its rendering."** The host renders a ring and
   shows cell digits only where `cellAgreesWithRing` is true. If a reader
   reports the digits as wrong above four items, that record's trigger has
   fired and the report goes upstream.

## 3. The eight org obligations, answered for a Godot addon

| Obligation | rad-godot answer |
|---|---|
| Baseline component audit | Godot Engine (MIT) at the pinned version; gdUnit4 (MIT) vendored; godot-git-plugin (MIT, with its THIRDPARTY notice). Nothing else. |
| Cumulative licence gates | Every vendored addon carries its LICENSE in-tree; a REUSE pass is a step on the ladder before the release claim. |
| Service inventory | Empty by construction. The project declares no network permission and opens no socket. |
| Quarterly upstream scan | Godot release notes at the pinned minor; gdUnit4 releases. Calendared in this record's Amendments on ratification. |
| Seam protocol named | The rad contract plus the hash-pinned `conformance/vectors.json`. Inside Godot: one signal carrying an intent dictionary, and nothing else, crosses from the addon to the host. |
| Control-plane record | None. The addon is compiled into a host; there is no resident component. |
| Risk register | §6. |
| Carried patches | None; register created empty. |

## 4. Milestones

A milestone is claimed by a version tag and by nothing else.

| Tag | Claim |
|---|---|
| **v0.0.0** | This plan and the architecture record, reviewed; the vectors pinned; the loop verifies the pin. *(this tag)* |
| v0.0.1 | `addons/rad/core` replays every case in the pinned vector file green, headless, from the test command; the core-boundary lint refuses any scene, input or engine API in `core/`. |
| v0.0.2 | The session and renderer: release-select and tap-select per contract, keyboard path, the nine cells, ring fitted to the viewport. The by-hand checklist (44-unit targets at eight items, dead-zone cancel, outward cancel, keyboard-only path) recorded in the handoff. |
| v0.0.3 | The host routes the contract's node, edge, canvas and selection vocabulary through a graph store; the menu is the only way to reach those verbs; number-key typing is gone. |
| v0.0.4 | Theme tokens from rad's token record; accessibility labels on every wedge through the engine's accessibility layer; the meters HUD in the reference's line grammar. |
| v0.0.5 | A host outside this repository consumes `addons/rad/` at a tag, locked by hash, with its own resolver and its own test that every verb goes through its state — titanharvest's tool ring or golfvs's placement ring, whichever milestone arrives first (§9). The split in the revision triggers fires here. |
| v0.1.0 | First release claim: checklist on a physical touch device, licence pass green, the two records ratified. |

## 5. Metrics

rad's budgets apply unchanged: one input per action for release-select; time
to commit p95 within one frame; grid jitter not claimed, because nothing here
quantizes. The host adds one metric when v0.0.3 is claimed: open-to-first-
highlight, measured from the invoking input's timestamp to the first
highlight effect, so a slow resolver shows as a number and not as a feel.

## 6. Risk register

| Risk | Likelihood | Mitigation |
|---|---|---|
| Vector drift against rad | High over time | Byte-exact copy, `vectors.lock`, `tools/check_vector_pin.py` on every `check`; a divergence adds a vector upstream before any code changes here. |
| JSON numbers arrive as floats in GDScript | Certain | The replayer compares indices and cells as integers explicitly; the first green run is checked against a deliberately wrong expected index. |
| Accessibility on a custom-drawn control | Medium | v0.0.4 uses the engine's accessibility properties; if a hand-drawn wedge cannot carry a label, wedges become child controls. |
| Input ordering between the host's `_input` and the menu | Medium | One adapter path in the addon, documented in the architecture record; the host yields to an open menu by a single guard. |
| Number-key typing removed from the host | Low | A product change, named in §7 for the human to confirm; the colour verb replaces it through the menu. |

## 7. What only a human can do

Confirm the repository name and its casing; create the remote and choose its
visibility; decide whether governance is mounted as a submodule or in the
lighter shape the org's other Godot project took; confirm the retirement of
number-key typing; ratify this record and the architecture record.

## 8. Open questions

- **Q1** Name casing: `rad-godot`, matching `rad` and `rad-android`.
- **Q2** Repository visibility at creation.
- **Q3** `governance/qm` submodule with a `project/rad-godot` branch, or the
  lighter shape without a submodule.
- **Q4** Whether the host stays 3D or gains a 2D mode for the touch checklist.

Answers land as Amendments here.

## 9. The organisation's other Godot projects

Two exist, both in the `games` family, both on the engine this repository
pins, both with gdUnit4 and a docs-coupling gate of the same shape. Each has
one place a ring belongs and several where it does not, read from its design
document rather than assumed:

- **titanharvest** — the tool swap in its verbs fork (`DESIGN.md` §5.2): a
  ring of at most eight with at most one submenu under every reading of the
  fork, first needed at its M2. The ring is the surface the fork is played
  on, not a side taken in it.
- **golfvs** — the defender's authoring surface (`DESIGN.md` §11.4,
  `DefensePlan`): placement from a budget and per-defender focus, first
  needed at its M5. Not the stroke, not the club selector, not the first run,
  each of which that project has decided against menus for.

`docs/integrations.md` is the ledger: how a host consumes the addon (copy at a
tag, lock by hash, resolver and one signal, one test in the host), each host's
status, what blocks it on both sides, and the proposal text each host's design
document receives when its pull-request slot is free. A host's decision is
made in that host's decision log and nowhere here.

## Revision triggers

- Any §2 upstream amendment lands — re-derive the affected section.
- A host outside this repository consumes `addons/rad/` — split the addon to
  its own repository, and the graph scene here becomes one host among the
  others in `docs/integrations.md`.
- The vector file's schema gains a key the replayer does not dispatch on —
  extend the replayer in the same change as the pin bump.
- A Godot minor release changes input, drawing or accessibility API the addon
  relies on — the engine pin moves only with a decision recorded here.

## Amendments

*(none)*
