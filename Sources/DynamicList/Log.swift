
import os.log

enum Log {

  static func debug(
    dso: UnsafeRawPointer = #dsohandle,
    file: StaticString = #file,
    line: UInt = #line,
    _ log: OSLog,
    _ object: @autoclosure () -> Any
  ) {
    os_log(.debug, dso: dso, log: log, "%{public}@", "\(object())")
  }

  static func error(
    dso: UnsafeRawPointer = #dsohandle,
    file: StaticString = #file,
    line: UInt = #line,
    _ log: OSLog,
    _ object: @autoclosure () -> Any
  ) {
    os_log(.error, dso: dso, log: log, "%{public}@", "\(object())")
  }

}

extension OSLog {

  @inline(__always)
  private static func makeOSLogInDebug(isEnabled: Bool = true, _ factory: () -> OSLog) -> OSLog {
#if DEBUG
    return factory()
#else
    return .disabled
#endif
  }

  static let generic: OSLog = makeOSLogInDebug { OSLog.init(subsystem: "app.muukii", category: "generic") }
}
