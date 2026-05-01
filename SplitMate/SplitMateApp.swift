import SwiftUI
import SwiftData

@main
struct SplitMateApp: App {
    init() {
        FontRegistration.registerCustomFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
