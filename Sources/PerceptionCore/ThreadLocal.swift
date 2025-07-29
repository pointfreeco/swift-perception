//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
//
//===----------------------------------------------------------------------===//

// https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/_ThreadLocal.swift

#if canImport(Darwin)
import Darwin
#elseif canImport(Bionic)
@preconcurrency import Bionic
#elseif canImport(Glibc)
@preconcurrency import Glibc
#elseif canImport(Musl)
@preconcurrency import Musl
#elseif canImport(WinSDK)
import WinSDK
#elseif canImport(threads_h)
internal import threads_h
#elseif canImport(threads)
internal import threads
#endif

struct _ThreadLocal {
    static var value: UnsafeMutableRawPointer? {
        get {
#if canImport(Darwin) || canImport(Bionic) || canImport(Glibc) || canImport(Musl)
            pthread_getspecific(key.key)
#elseif USE_TSS
            tss_get(key.key)
#elseif canImport(WinSDK)
            FlsGetValue(key.key)
#elseif os(WASI)
            key.key.pointee
#endif
        }

        set {
#if canImport(Darwin) || canImport(Bionic) || canImport(Glibc) || canImport(Musl)
            pthread_setspecific(key.key, newValue)
#elseif USE_TSS
            tss_set(key.key, newValue)
#elseif canImport(WinSDK)
            FlsSetValue(key.key, newValue)
#elseif os(WASI)
            key.key.pointee = newValue
#endif
        }
    }

#if canImport(Darwin) || canImport(Bionic) || canImport(Glibc) || canImport(Musl)
    fileprivate typealias PlatformKey = pthread_key_t
#elseif USE_TSS
    fileprivate typealias PlatformKey = tss_t
#elseif canImport(WinSDK)
    fileprivate typealias PlatformKey = DWORD
#elseif os(WASI)
    fileprivate typealias PlatformKey = UnsafeMutablePointer<UnsafeMutableRawPointer?>
#endif

    fileprivate struct Key {
        fileprivate let key: PlatformKey

        init() {
#if canImport(Darwin) || canImport(Bionic) || canImport(Glibc) || canImport(Musl)
            var key = PlatformKey()
            pthread_key_create(&key, nil)
            self.key = key
#elseif USE_TSS
            var key = PlatformKey()
            tss_create(&key, nil)
            self.key = key
#elseif canImport(WinSDK)
            key = FlsAlloc(nil)
#elseif os(WASI)
            key = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)
#endif
        }
    }

    fileprivate static let key = Key()
}
