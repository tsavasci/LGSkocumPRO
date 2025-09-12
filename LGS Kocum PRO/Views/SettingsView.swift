import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("appearance") private var appearance: Appearance = .system
    @State private var showingExportOptions = false
    @State private var showingImportOptions = false
    @State private var showingResetConfirmation = false
    
    enum Appearance: String, CaseIterable, Identifiable {
        case light = "Açık"
        case dark = "Koyu"
        case system = "Sisteme Uygun"
        
        var id: String { self.rawValue }
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light: return .light
            case .dark: return .dark
            case .system: return nil
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Appearance Section
                Section(header: Text("Görünüm")) {
                    Picker("Tema", selection: $appearance) {
                        ForEach(Appearance.allCases) { appearance in
                            Text(appearance.rawValue).tag(appearance)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, 8)
                }
                
                // Data Management Section
                Section(header: Text("Veri Yönetimi")) {
                    Button("Verileri Dışa Aktar") {
                        showingExportOptions = true
                    }
                    
                    Button("Verileri İçe Aktar") {
                        showingImportOptions = true
                    }
                    
                    Button("Verileri Sıfırla", role: .destructive) {
                        showingResetConfirmation = true
                    }
                }
                
                // App Info Section
                Section(header: Text("Uygulama Hakkında")) {
                    HStack {
                        Text("Versiyon")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Gizlilik Politikası", destination: URL(string: "https://example.com/privacy")!)
                    Link("Kullanım Koşulları", destination: URL(string: "https://example.com/terms")!)
                    
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)
                            
                            Text("LGS Koçum PRO")
                                .font(.title2.bold())
                            
                            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text("© 2025 Tüm Hakları Saklıdır")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                        }
                        .padding(.vertical, 20)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Ayarlar")
            .confirmationDialog("Verileri Sıfırla", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Sıfırla", role: .destructive) {
                    resetData()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text("Tüm öğrenci verileri ve ayarlar silinecek. Bu işlem geri alınamaz.\n\nDevam etmek istiyor musunuz?")
            }
            .sheet(isPresented: $showingExportOptions) {
                ExportDataView()
            }
            .sheet(isPresented: $showingImportOptions) {
                ImportDataView()
            }
        }
        .preferredColorScheme(appearance.colorScheme)
    }
    
    private func resetData() {
        // Delete all students (this will cascade to delete related practice exams and question performances)
        do {
            try modelContext.delete(model: Student.self)
        } catch {
            print("Failed to reset data: \(error.localizedDescription)")
        }
    }
}

// MARK: - Supporting Views

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var exportFormat: ExportFormat = .csv
    @State private var includeAllData: Bool = true
    @State private var selectedStudents: Set<Student> = []
    
    enum ExportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        case pdf = "PDF"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dışa Aktarma Seçenekleri")) {
                    Picker("Format", selection: $exportFormat) {
                        ForEach(ExportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    
                    Toggle("Tüm Verileri Dışa Aktar", isOn: $includeAllData)
                    
                    if !includeAllData {
                        NavigationLink("Öğrencileri Seç") {
                            StudentSelectionView(selectedStudents: $selectedStudents)
                        }
                    }
                }
                
                Section {
                    Button("Dışa Aktar") {
                        exportData()
                    }
                    .disabled(!includeAllData && selectedStudents.isEmpty)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Veri Dışa Aktar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func exportData() {
        // Implementation for exporting data
        // This would generate a file in the selected format and share it
        print("Exporting data as \(exportFormat.rawValue)")
        dismiss()
    }
}

struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var importFormat: ImportFormat = .csv
    @State private var importSource: ImportSource = .files
    @State private var isImporting = false
    
    enum ImportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        
        var id: String { self.rawValue }
    }
    
    enum ImportSource: String, CaseIterable, Identifiable {
        case files = "Dosyalar"
        case icloud = "iCloud"
        case other = "Diğer"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("İçe Aktarma Seçenekleri")) {
                    Picker("Kaynak", selection: $importSource) {
                        ForEach(ImportSource.allCases) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    
                    Picker("Format", selection: $importFormat) {
                        ForEach(ImportFormat.allCases) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                }
                
                Section {
                    Button("Dosya Seç") {
                        isImporting = true
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Veri İçe Aktar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: importFormat == .csv ? [.commaSeparatedText] : [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importData(from: url)
                    }
                case .failure(let error):
                    print("Error selecting file: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func importData(from url: URL) {
        // Implementation for importing data
        print("Importing data from \(url.lastPathComponent) as \(importFormat.rawValue)")
        // Process the file and import the data
        dismiss()
    }
}

struct StudentSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedStudents: Set<Student>
    @Query(sort: \Student.lastName) private var students: [Student]
    
    var body: some View {
        List(students) { student in
            HStack {
                Text(student.fullName)
                Spacer()
                if selectedStudents.contains(where: { $0.id == student.id }) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if let index = selectedStudents.firstIndex(where: { $0.id == student.id }) {
                    selectedStudents.remove(at: index)
                } else {
                    selectedStudents.insert(student)
                }
            }
        }
        .navigationTitle("Öğrenci Seç")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Tamam") {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, configurations: config)
    
    // Add example students
    for i in 1...5 {
        let student = Student(
            firstName: ["Ahmet", "Ayşe", "Mehmet", "Zeynep", "Ali"][i-1],
            lastName: "Öğrenci \(i)",
            school: "Örnek Okul",
            grade: 8
        )
        container.mainContext.insert(student)
    }
    
    return NavigationStack {
        SettingsView()
    }
    .modelContainer(container)
}
