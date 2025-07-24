#if os(iOS) || os(tvOS) || os(watchOS)
  import Foundation
#endif

// NB: This Boolean is used to work around a crash experienced by beta users of Observation when
//     'Observable' was still a marker protocol and we attempt to dynamically cast to
//     'any Observable'.
@usableFromInline
let isObservationBeta: Bool = {
  #if os(iOS) || os(tvOS) || os(watchOS)
    let os = ProcessInfo.processInfo.operatingSystemVersion
    #if os(iOS) || os(tvOS)
      if (os.majorVersion, os.minorVersion, os.patchVersion) != (17, 0, 0) {
        return false
      }
    #elseif os(watchOS)
      if (os.majorVersion, os.minorVersion, os.patchVersion) != (10, 0, 0) {
        return false
      }
    #endif
    var size = 0
    sysctlbyname("kern.osversion", nil, &size, nil, 0)
    var version = [CChar](repeating: 0, count: size)
    let ret = sysctlbyname("kern.osversion", &version, &size, nil, 0)
    // NB: Beta builds end with a lowercase character (_e.g._, '21A5277j')
    return ret == 0 ? String(cString: version).last?.isLowercase == true : false
  #else
    return false
  #endif
}()
