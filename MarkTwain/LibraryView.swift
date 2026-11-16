import SwiftData
import SwiftUI

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \MarkdownDocument.importedAt, order: .reverse)
    private var documents: [MarkdownDocument]
    @State private var selection: UUID?
    @State private var showingImporter = false
    @State private var errorMessage: String?

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
                MarkdownWebView(markdown: document.markdown)
                    .navigationTitle(document.name)
                    .navigationBarTitleDisplayMode(.inline)
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
