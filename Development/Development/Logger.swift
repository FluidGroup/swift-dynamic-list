import os.log

public enum Log {

  public static let generic = Logger({
    OSLog.makeOSLogInDebug { OSLog.init(subsystem: "app.muukii", category: "generic") }
  }())
}


extension OSLog {

  @inline(__always)
  fileprivate static func makeOSLogInDebug(isEnabled: Bool = true, _ factory: () -> OSLog) -> OSLog {
#if DEBUG
    return factory()
#else
    return .disabled
#endif
  }

}
