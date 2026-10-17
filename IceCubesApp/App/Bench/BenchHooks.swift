import Darwin
import Foundation

/// Benchmark-only hooks, inert unless launched with -bench-launch or -bench-resolve <N>.
/// Identical in every DI variant; only BenchResolve.resolveAll differs.
@MainActor
enum BenchHooks {
  private static var resolveAll: (() -> Void)?
  private static var firstFrameReported = false

  static func start(resolve: @escaping () -> Void) {
    resolveAll = resolve
    let args = ProcessInfo.processInfo.arguments
    if let i = args.firstIndex(of: "-bench-resolve"), i + 1 < args.count, let n = Int(args[i + 1]) {
      runResolve(iterations: n)
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
