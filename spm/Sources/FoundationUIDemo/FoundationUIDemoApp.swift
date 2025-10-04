#if os(Linux) || os(macOS)

import DefaultBackend
import Foundation
import SwiftCrossUI

@main
struct YourApp: App {
    var body: some Scene {
        WindowGroup("FoundationUI Demo") {
            FoundationUIDemoRootViewL()
        }
    }
}

///  Flagged off for now
#else  // #elseif os(macOS)

import SwiftUI

@main
struct FoundationUIDemoApp: App {
    var body: some Scene {
        WindowGroup {
            FoundationUIDemoRootViewM()
        }
    }
}
#endif
