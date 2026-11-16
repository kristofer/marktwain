import SwiftData
import SwiftUI

@main
struct MarkTwainApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
        }
        .modelContainer(for: MarkdownDocument.self)
    }
}
