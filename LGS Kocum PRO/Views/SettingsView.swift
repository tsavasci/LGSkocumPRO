import SwiftData
import SwiftUI
import UniformTypeIdentifiers

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
                        Text(
                            Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                                ?? "1.0.0"
                        )
                        .foregroundStyle(.secondary)
                    }

                    Link(
                        "Gizlilik Politikası",
                        destination: URL(string: "https://example.com/privacy")!)
                    Link(
                        "Kullanım Koşulları", destination: URL(string: "https://example.com/terms")!
                    )

                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            Image(systemName: "graduationcap.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(.blue)

                            Text("LGS Koçum PRO")
                                .font(.title2.bold())

                            Text(
                                "v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")"
                            )
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
            .confirmationDialog(
                "Verileri Sıfırla", isPresented: $showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sıfırla", role: .destructive) {
                    resetData()
                }
                Button("İptal", role: .cancel) {}
            } message: {
                Text(
                    "Tüm öğrenci verileri ve ayarlar silinecek. Bu işlem geri alınamaz.\n\nDevam etmek istiyor musunuz?"
                )
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
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.lastName) private var allStudents: [Student]
    @State private var exportFormat: ExportFormat = .csv
    @State private var includeAllData: Bool = true
    @State private var selectedStudents: Set<Student> = []
    @State private var isExporting = false
    @State private var exportedFileURL: URL?

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
                    .disabled(!includeAllData && selectedStudents.isEmpty || isExporting)
                    .frame(maxWidth: .infinity)

                    if isExporting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Dışa aktarılıyor...")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
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
            .fileExporter(
                isPresented: .constant(exportedFileURL != nil),
                document: ExportDocument(url: exportedFileURL),
                contentType: exportFormat == .csv ? .commaSeparatedText : .json,
                defaultFilename:
                    "LGS_Kocum_Data_\(DateFormatter.filenameDateFormatter.string(from: Date()))"
            ) { result in
                exportedFileURL = nil
                isExporting = false
                switch result {
                case .success(let url):
                    print("File exported successfully to: \(url)")
                case .failure(let error):
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func exportData() {
        isExporting = true

        Task {
            do {
                let studentsToExport = includeAllData ? allStudents : Array(selectedStudents)
                let url = try await generateExportFile(
                    students: studentsToExport, format: exportFormat)

                await MainActor.run {
                    exportedFileURL = url
                }
            } catch {
                await MainActor.run {
                    isExporting = false
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func generateExportFile(students: [Student], format: ExportFormat) async throws -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[
            0]
        let fileName = "LGS_Kocum_Data_\(DateFormatter.filenameDateFormatter.string(from: Date()))"

        switch format {
        case .csv:
            let fileURL = documentsPath.appendingPathComponent("\(fileName).csv")
            let csvContent = generateCSVContent(students: students)
            try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL

        case .json:
            let fileURL = documentsPath.appendingPathComponent("\(fileName).json")
            let jsonContent = try generateJSONContent(students: students)
            try jsonContent.write(to: fileURL)
            return fileURL

        case .pdf:
            // For PDF, we'll create a simple text-based PDF for now
            let fileURL = documentsPath.appendingPathComponent("\(fileName).pdf")
            let textContent = generateTextContent(students: students)
            try textContent.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        }
    }

    private func generateCSVContent(students: [Student]) -> String {
        var csv =
            "Ad,Soyad,Okul,Sınıf,Hedef Puan,Türkçe Net,Matematik Net,Fen Net,Sosyal Net,Din Net,İngilizce Net,Sınav Sayısı,Ortalama Puan\n"

        for student in students {
            let examCount = student.practiceExams.count
            let avgScore = student.currentAverageScore

            csv +=
                "\(student.firstName),\(student.lastName),\(student.school),\(student.grade),\(student.targetTotalScore),\(student.targetTurkceNet),\(student.targetMatematikNet),\(student.targetFenNet),\(student.targetSosyalNet),\(student.targetDinNet),\(student.targetIngilizceNet),\(examCount),\(avgScore)\n"
        }

        return csv
    }

    private func generateJSONContent(students: [Student]) throws -> Data {
        let exportData = students.map { student in
            return [
                "id": student.id.uuidString,
                "firstName": student.firstName,
                "lastName": student.lastName,
                "school": student.school,
                "grade": student.grade,
                "notes": student.notes,
                "createdAt": ISO8601DateFormatter().string(from: student.createdAt),
                "targets": [
                    "totalScore": student.targetTotalScore,
                    "turkceNet": student.targetTurkceNet,
                    "matematikNet": student.targetMatematikNet,
                    "fenNet": student.targetFenNet,
                    "sosyalNet": student.targetSosyalNet,
                    "dinNet": student.targetDinNet,
                    "ingilizceNet": student.targetIngilizceNet,
                ],
                "practiceExams": student.practiceExams.map { exam in
                    return [
                        "id": exam.id.uuidString,
                        "name": exam.name,
                        "date": ISO8601DateFormatter().string(from: exam.date),
                        "totalScore": exam.totalScore,
                        "notes": exam.notes,
                        "nets": [
                            "turkce": exam.turkceNet,
                            "matematik": exam.matematikNet,
                            "fen": exam.fenNet,
                            "sosyal": exam.sosyalNet,
                            "din": exam.dinNet,
                            "ingilizce": exam.ingilizceNet,
                        ],
                    ]
                },
            ]
        }

        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }

    private func generateTextContent(students: [Student]) -> String {
        var content = "LGS Koçum PRO - Veri Raporu\n"
        content +=
            "Oluşturulma Tarihi: \(DateFormatter.displayDateFormatter.string(from: Date()))\n\n"
        content += "==============================\n\n"

        for student in students {
            content += "ÖĞRENCİ: \(student.fullName)\n"
            content += "Okul: \(student.school)\n"
            content += "Sınıf: \(student.grade)\n"
            content += "Hedef Puan: \(student.targetTotalScore)\n"
            content += "Sınav Sayısı: \(student.practiceExams.count)\n"
            content += "Ortalama Puan: \(String(format: "%.1f", student.currentAverageScore))\n"
            content += "\nSınav Geçmişi:\n"

            for exam in student.practiceExams.sorted(by: { $0.date > $1.date }) {
                content +=
                    "- \(exam.name): \(exam.totalScore) puan (\(DateFormatter.shortDateFormatter.string(from: exam.date)))\n"
            }

            content += "\n==============================\n\n"
        }

        return content
    }
}

struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
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

                    Section(header: Text("Dosya Formatı Örneği")) {
                        if importFormat == .csv {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("CSV Başlık Satırı:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text("Ad,Soyad,Okul,Sınıf,Şube,Notlar")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(4)

                                Text("Örnek:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text("Ahmet,Yılmaz,Atatürk Ortaokulu,8,A,İyi çalışıyor")
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.primary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(4)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("JSON Örneği:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text(
                                    """
                                    [
                                      {
                                        "firstName": "Ahmet",
                                        "lastName": "Yılmaz",
                                        "school": "Atatürk Ortaokulu",
                                        "grade": 8,
                                        "branch": "A",
                                        "notes": "İyi çalışıyor"
                                      }
                                    ]
                                    """
                                )
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
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
                    isImporting = false
                }
            }
        }
    }

    func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Could not access file")
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            var importedCount = 0

            switch importFormat {
            case .csv:
                importedCount = try importCSVData(from: url)
            case .json:
                importedCount = try importJSONData(from: url)
            }

            print("Data imported successfully from \(url.lastPathComponent)")

            // Show success alert or message
            // In a full implementation, you'd add a state variable and alert here
            print("Başarıyla \(importedCount) öğrenci içe aktarıldı")
        } catch {
            print("Import failed: \(error.localizedDescription)")
            // Show error alert or message
        }

        dismiss()
    }

    func importCSVData(from url: URL) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else { return 0 }

        for line in lines.dropFirst() {
            let components = line.components(separatedBy: ",")
            guard components.count >= 2 else { continue }

            let student = Student(
                firstName: components[0].trimmingCharacters(in: .whitespacesAndNewlines),
                lastName: components[1].trimmingCharacters(in: .whitespacesAndNewlines),
                school: components.count > 2
                    ? components[2].trimmingCharacters(in: .whitespacesAndNewlines) : "",
                grade: components.count > 3
                    ? (Int(components[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 8) : 8,
                branch: components.count > 4
                    ? components[4].trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
                    : "",
                notes: components.count > 5
                    ? components[5].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            )

            modelContext.insert(student)
        }

        try modelContext.save()
        return lines.count - 1  // Number of imported students (excluding header)
    }

    func importJSONData(from url: URL) throws -> Int {
        let data = try Data(contentsOf: url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw ImportError.invalidFormat
        }

        for studentData in json {
            guard let firstName = studentData["firstName"] as? String,
                let lastName = studentData["lastName"] as? String
            else {
                continue
            }

            let student = Student(
                firstName: firstName,
                lastName: lastName,
                school: studentData["school"] as? String ?? "",
                grade: studentData["grade"] as? Int ?? 8,
                branch: (studentData["branch"] as? String ?? "").uppercased(),
                notes: studentData["notes"] as? String ?? ""
            )

            modelContext.insert(student)
        }

        try modelContext.save()
        return json.count  // Number of imported students
    }

    func parseDate(from string: String?) -> Date? {
        guard let string = string else { return nil }
        return ISO8601DateFormatter().date(from: string)
    }

    enum ImportError: Error {
        case invalidFormat
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
            firstName: ["Ahmet", "Ayşe", "Mehmet", "Zeynep", "Ali"][i - 1],
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

// MARK: - Supporting Types

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }

    var url: URL?

    init(url: URL?) {
        self.url = url
    }

    init(configuration: ReadConfiguration) throws {
        self.url = nil
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let url = url,
            let data = try? Data(contentsOf: url)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: - Date Formatters

extension DateFormatter {
    static let filenameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm"
        return formatter
    }()

    static let displayDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()

    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy"
        return formatter
    }()
}
