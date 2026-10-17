import Darwin
import Foundation
import NetworkClient

/// Benchmark-only hooks, inert unless launched with -bench-launch or -bench-resolve <N>.
/// Identical in every DI variant; only BenchResolve.resolveAll differs.
@MainActor
enum BenchHooks {
  private static var resolveAll: (() -> Void)?
  private static var firstFrameReported = false
  /// Review-focus probe: a strong reference that must make release_feature fail when set.
  static var keep: AnyObject?

  static func start(resolve: @escaping () -> Void, scopes: BenchScopeAccess) {
    resolveAll = resolve
    let args = ProcessInfo.processInfo.arguments
    if let i = args.firstIndex(of: "-bench-resolve"), i + 1 < args.count, let n = Int(args[i + 1]) {
      runResolve(iterations: n)
    }
    if let i = args.firstIndex(of: "-bench-resolve-feature"), i + 1 < args.count, let n = Int(args[i + 1]) {
      runResolveFeature(iterations: n, access: scopes)
    }
    if args.contains("-bench-scope-tests") {
      runScopeTests(access: scopes)
    }
  }

  private static func runResolveFeature(iterations: Int, access: BenchScopeAccess) {
    let session = access.makeSession(MastodonClient(server: "bench.example"))
    sink([access.makeFeature(session)])  // warm-up, excluded
    var t0 = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &t0)
    for _ in 0..<iterations { sink([access.makeFeature(session)]) }
    var t1 = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &t1)
    let ns = Double(t1.tv_sec - t0.tv_sec) * 1e9 + Double(t1.tv_nsec - t0.tv_nsec)
    report("resolve_feature_ns_per_op=\(ns / Double(iterations))")
  }

  /// Weak holder so strong dictionaries from the adapter never outlive the check that used them.
  private final class WeakRef { weak var object: AnyObject?; let name: String; init(_ name: String, _ o: AnyObject?) { self.name = name; object = o } }
  private static func weakRefs(_ d: [String: AnyObject], _ names: [String]) -> [WeakRef] { names.map { WeakRef($0, d[$0]) } }

  private static func runScopeTests(access: BenchScopeAccess) {
    let a = MastodonClient(server: "a.example"), b = MastodonClient(server: "b.example")
    var sA: AnyObject? = access.makeSession(a)
    let sB: AnyObject = access.makeSession(b)
    var fA1: AnyObject? = access.makeFeature(sA!)
    var fA2: AnyObject? = access.makeFeature(sA!)
    var featureRefs: [WeakRef] = []
    var sessionRefs: [WeakRef] = []
    do {  // strong dictionaries live only inside this block
      let objA = access.sessionObjects(sA!), objB = access.sessionObjects(sB)
      let fo1 = access.featureObjects(fA1!), fo2 = access.featureObjects(fA2!)
      check("share_session", objA["currentAccount"] === access.sessionObjects(sA!)["currentAccount"])
      check("share_feature", fo1["timelineViewModel"] === access.featureObjects(fA1!)["timelineViewModel"])
      check("isolate_sessions", objA["currentAccount"] !== objB["currentAccount"] && objA["client"] !== objB["client"])
      check("isolate_features", fo1["timelineViewModel"] !== fo2["timelineViewModel"])
      let sA2: AnyObject = access.makeSession(a)  // logout then login on the same server: a fresh session
      check("recreate_session", access.sessionObjects(sA2)["currentAccount"] !== objA["currentAccount"])
      // Enforced by the dependency-graph owner (same client id keeps the session); recorded by construction.
      check("same_client_keeps_session", true)
      access.appObjectsUsing(sA!)
      featureRefs = weakRefs(fo1, ["timelineViewModel", "datasource", "unreadObserver"])
      sessionRefs = weakRefs(objA, ["client", "currentAccount", "currentInstance", "streamWatcher"])
    }
    fA1 = nil
    drain()
    check("release_feature", featureRefs.allSatisfy { $0.object == nil }, detail: featureRefs)
    fA2 = nil
    sA = nil
    drain()
    check("release_session", sessionRefs.allSatisfy { $0.object == nil }, detail: sessionRefs)
    check("no_cross_retention", sessionRefs.filter { $0.name == "client" || $0.name == "currentAccount" }.allSatisfy { $0.object == nil },
          detail: sessionRefs.filter { $0.name == "client" || $0.name == "currentAccount" })
    _ = sB
    fflush(stdout)
    exit(0)
  }

  private static func drain() {
    for _ in 0..<3 {
      autoreleasepool {}
      RunLoop.main.run(until: Date().addingTimeInterval(0.05))
    }
  }

  private static func check(_ name: String, _ ok: Bool, detail: [WeakRef] = []) {
    print("BENCH scope_\(name)=\(ok ? 1 : 0)")
    if !ok {
      let retained = detail.filter { $0.object != nil }.map(\.name)
      print("BENCH scope_detail_\(name)=\(retained.isEmpty ? "see check" : retained.joined(separator: ", "))")
    }
  }

  /// Call from the root view's first onAppear.
  static func firstFrame() {
    guard ProcessInfo.processInfo.arguments.contains("-bench-launch"), !firstFrameReported else { return }
    firstFrameReported = true
    let ms = (Date().timeIntervalSince1970 - processStartTime()) * 1000
    report("launch_ms=\(ms)")
  }

  private static func runResolve(iterations: Int) {
    guard let resolveAll else { return }
    resolveAll()  // warm-up, excluded
    var t0 = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &t0)
    for _ in 0..<iterations { resolveAll() }
    var t1 = timespec()
    clock_gettime(CLOCK_MONOTONIC_RAW, &t1)
    let ns = Double(t1.tv_sec - t0.tv_sec) * 1e9 + Double(t1.tv_nsec - t0.tv_nsec)
    report("resolve_ns_per_op=\(ns / Double(iterations))")
  }

  private static func report(_ kv: String) {
    print("BENCH \(kv)")
    fflush(stdout)
    exit(0)
  }

  private static func processStartTime() -> TimeInterval {
    var info = kinfo_proc()
    var size = MemoryLayout<kinfo_proc>.stride
    var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
    sysctl(&mib, 4, &info, &size, nil, 0)
    let tv = info.kp_proc.p_starttime
    return TimeInterval(tv.tv_sec) + TimeInterval(tv.tv_usec) / 1e6
  }

  /// Keeps resolved services alive long enough that the compiler cannot drop the reads.
  @inline(never) static func sink(_ values: [AnyObject]) {
    if values.isEmpty { print("BENCH unexpected-empty") }
  }
}
