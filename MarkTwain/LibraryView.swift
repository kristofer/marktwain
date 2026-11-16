import SwiftData
import SwiftUI
import UIKit
import WebKit

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MarkdownDocument.importedAt, order: .reverse)
    private var documents: [MarkdownDocument]
    @State private var selection: UUID?
    @State private var showingImporter = false
    @State private var errorMessage: String?
    @State private var previewWebView: WKWebView?

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                ForEach(documents) { document in
                    NavigationLink(value: document.id) {
                        Label(document.name, systemImage: "doc.text")
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if documents.isEmpty {
                    ContentUnavailableView(
                        "Your Markdown Library",
                        systemImage: "doc.text",
                        description: Text("Use the plus button to import a Markdown file.")
                    )
                    .allowsHitTesting(false)
                }
            }
            .navigationTitle("Mark Twain")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Import Markdown", systemImage: "plus") {
                        showingImporter = true
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                        .disabled(documents.isEmpty)
                }
            }
        } detail: {
            if let document = documents.first(where: { $0.id == selection }) {
                MarkdownWebView(markdown: document.markdown) { webView in
                    previewWebView = webView
                }
                    .navigationTitle(document.name)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button("PRINT", systemImage: "printer") {
                                guard let previewWebView else { return }
                                let printController = UIPrintInteractionController.shared
                                let printInfo = UIPrintInfo(dictionary: nil)
                                printInfo.jobName = document.name
                                printInfo.outputType = .general
                                printController.printInfo = printInfo
                                printController.printFormatter = previewWebView.viewPrintFormatter()

                                if UIDevice.current.userInterfaceIdiom == .pad {
                                    printController.present(
                                        from: CGRect(
                                            x: previewWebView.bounds.maxX,
                                            y: previewWebView.bounds.minY,
                                            width: 0,
                                            height: 0
                                        ),
                                        in: previewWebView,
                                        animated: true
                                    )
                                } else {
                                    printController.present(animated: true)
                                }
                            }
                            .disabled(previewWebView == nil)
                        }
                    }
            } else {
                ContentUnavailableView(
                    "Select a Document",
                    systemImage: "book",
                    description: Text("Import a Markdown file or choose one from your library.")
                )
            }
        }
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.markdownDocument, .plainText],
            allowsMultipleSelection: true
        ) { result in
            do {
                try importDocuments(result.get())
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .onOpenURL { url in
            do {
                try importDocuments([url])
            } catch {
                errorMessage = error.localizedDescription
            }
        }
        .alert("Unable to Open Document", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func importDocuments(_ urls: [URL]) throws {
        for url in urls {
            let document = try DocumentImport.read(url)
            modelContext.insert(document)
            do {
                try modelContext.save()
                selection = document.id
            } catch {
                modelContext.rollback()
                throw error
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let previousSelection = selection
        for index in offsets {
            let document = documents[index]
            if selection == document.id {
                selection = nil
            }
            modelContext.delete(document)
        }
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            selection = previousSelection
            errorMessage = error.localizedDescription
        }
    }
}
