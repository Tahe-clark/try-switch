# DepCache

A small Swift command-line tool exploring two core build-system concepts: dependency resolution and build caching.

## Why

I built this while preparing a co-op application for a Core Build team — I wanted to actually understand, hands-on, how a package manager decides what order to build things in, and how a build system avoids redoing work it doesn't need to.

## What it does

**1. Dependency resolution** — given a small graph of packages (e.g. `App` depends on `UI` and `Networking`, both of which depend on `Core`), the tool computes a valid build order using topological sort (Kahn's algorithm). This is the same core idea a real package manager like SwiftPM uses to decide what to build first.

**2. Build caching** — simulates how a build system avoids unnecessary rebuilds. Before "building" a target, it hashes the target's inputs. If the hash matches the last recorded one, the build is skipped (cache hit); if the inputs changed, it rebuilds and stores the new hash.

## Example output

```
build order:
Core -> UI -> Networking -> App

cache behaviour:
  building    -> Core
  cache hit   -> Core
  building    -> Core
```

## Run it

Paste `main.swift` into an online Swift runner (e.g. swiftfiddle.com) or run locally with:

```
swift main.swift
```
