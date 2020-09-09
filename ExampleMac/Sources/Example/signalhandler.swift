import Foundation

// MARK: - SignalHandler
struct SignalHandler {
  struct Signal: Hashable {
    static let hangup = Signal(rawValue: SIGHUP)
    static let interrupt = Signal(rawValue: SIGINT)
    static let quit = Signal(rawValue: SIGQUIT)
    static let abort = Signal(rawValue: SIGABRT)
    static let kill = Signal(rawValue: SIGKILL)
    static let alarm = Signal(rawValue: SIGALRM)
    static let termination = Signal(rawValue: SIGTERM)
    static let userDefined1 = Signal(rawValue: SIGUSR1)
    static let userDefined2 = Signal(rawValue: SIGUSR2)

    /// Signals that cause the process to exit
    static let exitSignals = [
      hangup,
      interrupt,
      quit,
      abort,
      alarm,
      termination
    ]

    let rawValue: Int32
    init(rawValue: Int32) {
      self.rawValue = rawValue
    }
  }

  typealias CSignalHandler = @convention(c) (Int32) -> Void
  typealias SignalHandler = (Signal) -> Void

  private static var handlers = [Signal: [SignalHandler]]()

  private static var cHandler: CSignalHandler = { rawSignal in
    let signal = Signal(rawValue: rawSignal)

    guard let signalHandlers = handlers[signal] else {
      return
    }

    for handler in signalHandlers {
      handler(signal)
    }
  }

  /// Handle some signals
  static func handle(signals: [Signal], handler: @escaping SignalHandler) {
    for signal in signals {
      // Since Swift has no way of running code on "struct creation", we need to initialize here…
      if handlers[signal] == nil {
        handlers[signal] = []
      }
      handlers[signal]?.append(handler)

      var signalAction = sigaction(
        __sigaction_u: unsafeBitCast(cHandler, to: __sigaction_u.self),
        sa_mask: 0,
        sa_flags: 0
      )

      _ = withUnsafePointer(to: &signalAction) { pointer in
        sigaction(signal.rawValue, pointer, nil)
      }
    }
  }

  /// Raise a signal
  static func raise(signal: Signal) {
    _ = Darwin.raise(signal.rawValue)
  }

  /// Ignore a signal
  static func ignore(signal: Signal) {
    _ = Darwin.signal(signal.rawValue, SIG_IGN)
  }

  /// Restore default signal handling
  static func restore(signal: Signal) {
    _ = Darwin.signal(signal.rawValue, SIG_DFL)
  }
}

extension Array where Element == SignalHandler.Signal {
  static let exitSignals = SignalHandler.Signal.exitSignals
}
// MARK: -