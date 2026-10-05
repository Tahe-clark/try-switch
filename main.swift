// DepCache - small CLI exploring dependency resolution + build caching
// Kelyan Tahe

import Foundation

struct Package {
    let name: String
    let dependencies: [String]
}

enum ResolutionError: Error, CustomStringConvertible {
    case cycleDetected
    var description: String { "cycle detected, can't resolve a build order" }
}

// topological sort (Kahn's algorithm) - figure out a valid build order
func resolveBuildOrder(_ packages: [Package]) throws -> [String] {
    var remaining: [String: Int] = [:]
    for pkg in packages {
        remaining[pkg.name] = pkg.dependencies.count
    }

    var ready = packages.filter { remaining[$0.name] == 0 }.map { $0.name }
    var order: [String] = []

    while !ready.isEmpty {
        let current = ready.removeFirst()
        order.append(current)

        for pkg in packages where pkg.dependencies.contains(current) {
            remaining[pkg.name]! -= 1
            if remaining[pkg.name] == 0 {
                ready.append(pkg.name)
            }
        }
    }

    guard order.count == packages.count else { throw ResolutionError.cycleDetected }
    return order
}

// simple hash-based cache - skip rebuilding a target if its inputs are unchanged
final class BuildCache {
    private var lastHash: [String: String] = [:]

    private func fnv1a(_ text: String) -> String {
        var h: UInt64 = 0xcbf29ce484222325
        for b in text.utf8 {
            h ^= UInt64(b)
            h = h &* 0x100000001b3
        }
        return String(h, radix: 16)
    }

    @discardableResult
    func build(_ target: String, inputs: String) -> Bool {
        let h = fnv1a(inputs)
        if lastHash[target] == h {
            print("  cache hit   -> \(target)")
            return false
        }
        print("  building    -> \(target)")
        lastHash[target] = h
        return true
    }
}

// --- demo ---

let packages = [
    Package(name: "App", dependencies: ["Networking", "UI"]),
    Package(name: "UI", dependencies: ["Core"]),
    Package(name: "Networking", dependencies: ["Core"]),
    Package(name: "Core", dependencies: []),
]

print("build order:")
do {
    print(try resolveBuildOrder(packages).joined(separator: " -> "))
} catch {
    print(error)
}

print("\ncache behaviour:")
let cache = BuildCache()
cache.build("Core", inputs: "struct Core {}")
cache.build("Core", inputs: "struct Core {}")              // unchanged -> cache hit
cache.build("Core", inputs: "struct Core { let x = 1 }")   // changed -> rebuild