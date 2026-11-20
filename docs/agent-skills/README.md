# Agent skills — iOS performance

Vendored copies of three performance-review skills from
[Livsy90/iOS-Performance-Agent-Skills](https://github.com/Livsy90/iOS-Performance-Agent-Skills),
MIT licensed. The upstream package is normally installed with `npx skills add`;
that command needs a terminal and Node, neither of which exists on the device
this project is edited from, so the documents are copied here instead.

Folder names match the upstream repository exactly, so the `references/…` paths
each document routes to resolve to the same file names upstream. Only the three
top-level `SKILL.md` documents are mirrored; a reference file is fetched from
`raw.githubusercontent.com/Livsy90/iOS-Performance-Agent-Skills/main/<skill>/references/<file>`
the first time a task needs it, rather than carrying all thirty into the repo.

| Folder | Covers |
| --- | --- |
| `ios-performance-profiling/` | Choosing and interpreting profiling work: Instruments, traces, signposts, XCTest metrics, MetricKit, Organizer, hangs, hitches, memory, disk, network, power |
| `swiftui-performance/` | Change locality in SwiftUI: identity, state ownership, dependency breadth, body cost, row and list structure, bindings, layout, drawing, async lifecycle |
| `swift-concurrency-performance/` | Task lifetime, actor and `MainActor` isolation, cancellation, task groups, `AsyncSequence`, continuations, reentrancy, blocking work |

## How they are used here

They are review guides, not build rules. Three points from them carry into every
performance answer in this project:

1. **Evidence before optimisation.** A change is only called an improvement
   when there is a before/after measurement. Where the only evidence is a code
   reading, say that it is a code reading and name what would confirm it. This
   matters here because the app is built on a remote Mac and cannot be profiled
   on a device from the editor at all — Simulator builds are the only local
   check, and the documents are explicit that Simulator results mislead for
   launch, scrolling, memory pressure, power and thermals.
2. **Change locality over micro-optimisation.** For SwiftUI the question is
   always which change invalidates which views and how much work follows, not
   whether a particular call is fast.
3. **Smallest fix first.** Targeted refactors, not architectural rewrites, and
   no `.equatable()`, memoisation or caching proposed as a blanket remedy.

The documents also route to `ios-launch-performance`,
`ios-perceived-performance` and `swift-runtime-performance`, which are not
mirrored here. If a task turns on launch cost, perceived latency or runtime
allocation behaviour, fetch that skill the same way and add it beside these.

## Notes from installing these

Two things worth knowing before the next performance task:

- These files are a copy, not the installed tool. The instructions in each
  document still say to read `references/…` files that are not in the repo; fetch
  those from the upstream `main` branch when a task actually needs one, and note
  in the answer that it was read rather than assumed.
- A few patterns the SwiftUI guide calls red flags are already in the codebase
  and were written on purpose — the backdrop's soft blooms, the frosted panels,
  and the theme-13 texture plates. They are worth answering for by measurement if
  a scrolling hitch is ever reported, but they are not to be pre-emptively
  stripped: the guide's own rule is to connect a fix to evidence first.
