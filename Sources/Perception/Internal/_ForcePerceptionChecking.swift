import Foundation

// The beta builds which included of Observation used the `@_marker` protocol for Observable.
// Since the API changed and the protocol no longer matches there's a runtime crash when trying
// to cast to `any Observable` on a beta build.
//
// As a result, the following check has been implemented to disable Observation on any of the
// following beta OS versions:
//
// - iOS 17.0.0
// - watchOS 10.0.0
// - tvOS 17.0.0
//
// This safeguard makes sure that `Perception` is used in place of `Observation`.
//
// +----------------------------------------+---------------------+----------------------+
// | isMinimumSupportedObservationOSVersion | isKernelVersionBeta | isObservationAllowed |
// +----------------------------------------+---------------------+----------------------+
// |                 FALSE                  |        FALSE        |         TRUE         |
// |                 FALSE                  |        TRUE         |         TRUE         |
// |                 TRUE                   |        FALSE        |         TRUE         |
// |                 TRUE                   |        TRUE         |         FALSE        |
// +----------------------------------------+---------------------+----------------------+
//
// ```
// Example of a crash trace:
// 0  libswiftCore.dylib 0x39be20 tryCast(swift::OpaqueValue*, swift::TargetMetadata<swift::InProcess> const*, swift::OpaqueValue*, swift::TargetMetadata<swift::InProcess> const*, swift::TargetMetadata<swift::InProcess> const*&, swift::TargetMetadata<swift::InProcess> const*&, bool, bool) +
// ```
var isObservationAllowed: Bool { !(isMinimumSupportedObservationOSVersion && isKernelVersionBeta) }

private var kernelVersion: String {
  var size = 0
  sysctlbyname("kern.osversion", nil, &size, nil, 0)
  var version = [CChar](repeating: 0, count: size)
  sysctlbyname("kern.osversion", &version, &size, nil, 0)
  return String(cString: version)
}

// isKernelVersionBeta is denoted by a lowercase character as the last character of the string. e.g. 21A5277j
private var isKernelVersionBeta: Bool { kernelVersion.last?.isLowercase == true }

private var isMinimumSupportedObservationOSVersion: Bool {
  let os = ProcessInfo.processInfo.operatingSystemVersion
  #if os(iOS) || os(tvOS)
  return (os.majorVersion, os.minorVersion, os.patchVersion) == (17, 0, 0)
  #elseif os(watchOS)
  return (os.majorVersion, os.minorVersion, os.patchVersion) == (10, 0, 0)
  #elseif os(macOS)
  return false
  #endif
}
