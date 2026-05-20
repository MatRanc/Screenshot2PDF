import SwiftUI

@main
struct Screenshot2PDFApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 520, minHeight: 460)
        }
        .windowResizability(.contentSize)
    }
}
