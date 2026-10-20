import SwiftUI

@main
struct OrelioApp: App {
    @StateObject private var library = LibraryStore()
    @StateObject private var exporter = ExportManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(library)
                .environmentObject(exporter)
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: LibraryStore

    var body: some View {
        TabView(selection: $store.currentTab) {
            LibraryView()
                .tabItem { Label("Library", systemImage: "square.grid.2x2") }
                .tag(AppTab.library)
            EditorView()
                .tabItem { Label("Edit", systemImage: "slider.horizontal.3") }
                .tag(AppTab.editor)
            CollageView()
                .tabItem { Label("Collage", systemImage: "rectangle.3.group") }
                .tag(AppTab.collage)
            BatchExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                .tag(AppTab.export)
        }
        .tint(Color(red: 0.773, green: 0.482, blue: 0.337))
        .alert("Action unavailable", isPresented: Binding(
            get: { store.errorMessage != nil },
            set: { if !$0 { store.clearError() } }
        )) {
            Button("OK") { store.clearError() }
        } message: { Text(store.errorMessage ?? "") }
    }
}
