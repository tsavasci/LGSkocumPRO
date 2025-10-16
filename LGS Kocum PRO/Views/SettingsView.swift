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
            ZStack {
                // Modern Gradient Background
                LinearGradient(
                    colors: [
                        Color(hex: "667eea").opacity(0.05),
                        Color(hex: "764ba2").opacity(0.05),
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                Form {
                    // Appearance Section
                    Section(
                        header: Text("Görünüm")
                            .font(.headline)
                            .foregroundStyle(Color.primaryGradient)
                    ) {
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
                    Section(
                        header: Text("Veri Yönetimi")
                            .font(.headline)
                            .foregroundStyle(Color.primaryGradient)
                    ) {
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

                    // Test Section (Development)
                    Section(
                        header: Text("Geliştirici")
                            .font(.headline)
                            .foregroundStyle(Color.primaryGradient)
                    ) {
                        NavigationLink("Firebase Test") {
                            FirebaseTestView()
                        }
                    }
                    
                    // App Info Section
                    Section(
                        header: Text("Uygulama Hakkında")
                            .font(.headline)
                            .foregroundStyle(Color.primaryGradient)
                    ) {
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
                            "Kullanım Koşulları",
                            destination: URL(string: "https://example.com/terms")!
                        )

                        HStack {
                            Spacer()
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primaryGradient)
                                        .frame(width: 80, height: 80)

                                    Image(systemName: "graduationcap.fill")
                                        .font(.system(size: 40))
                                        .foregroundStyle(.white)
                                }

                                Text("LGS Koçum PRO")
                                    .font(.title2.bold())
                                    .foregroundStyle(Color.primaryGradient)

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
                    }
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
            "Ad,Soyad,Okul,Sınıf,Şube,Hedef Toplam,Hedef Türkçe,Hedef Matematik,Hedef Fen,Hedef Sosyal,Hedef Din,Hedef İngilizce,Notlar\n"

        for student in students {
            csv +=
                "\(student.firstName),\(student.lastName),\(student.school),\(student.grade),\(student.branch),\(student.targetTotalScore),\(student.targetTurkceNet),\(student.targetMatematikNet),\(student.targetFenNet),\(student.targetSosyalNet),\(student.targetDinNet),\(student.targetIngilizceNet),\(student.notes)\n"
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
    @State private var selectedDataTypes: Set<DataType> = [.students]
    @State private var importStatusMessage = ""
    @State private var showingImportResult = false

    enum ImportFormat: String, CaseIterable, Identifiable {
        case csv = "CSV"
        case json = "JSON"
        case excel = "Excel"

        var id: String { self.rawValue }
    }

    enum ImportSource: String, CaseIterable, Identifiable {
        case files = "Dosyalar"
        case icloud = "iCloud"

        var id: String { self.rawValue }
    }

    enum DataType: String, CaseIterable, Identifiable {
        case students = "Öğrenci Bilgileri"
        case exams = "Sınav Sonuçları"
        case performance = "Soru Performansı"
        case targets = "Hedef Puanlar"

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

                Section(header: Text("Aktarılacak Veri Türleri")) {
                    ForEach(DataType.allCases) { dataType in
                        HStack {
                            Image(
                                systemName: selectedDataTypes.contains(dataType)
                                    ? "checkmark.square.fill" : "square"
                            )
                            .foregroundColor(selectedDataTypes.contains(dataType) ? .blue : .gray)
                            .onTapGesture {
                                if selectedDataTypes.contains(dataType) {
                                    selectedDataTypes.remove(dataType)
                                } else {
                                    selectedDataTypes.insert(dataType)
                                }
                            }

                            Text(dataType.rawValue)
                                .onTapGesture {
                                    if selectedDataTypes.contains(dataType) {
                                        selectedDataTypes.remove(dataType)
                                    } else {
                                        selectedDataTypes.insert(dataType)
                                    }
                                }

                            Spacer()
                        }
                    }
                }

                Section(header: Text("Dosya Formatı Örnekleri")) {
                    if importFormat == .csv {
                        VStack(alignment: .leading, spacing: 8) {
                            if selectedDataTypes.contains(.students) {
                                Text("Öğrenci CSV Başlıkları:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text(
                                    "Ad,Soyad,Okul,Sınıf,Şube,Hedef Toplam,Hedef Türkçe,Hedef Matematik,Hedef Fen,Hedef Sosyal,Hedef Din,Hedef İngilizce,Notlar"
                                )
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                            }

                            if selectedDataTypes.contains(.exams) {
                                Text("Sınav CSV Başlıkları:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text(
                                    "ÖğrenciAdı,ÖğrenciSoyadı,SınavAdı,Tarih,ToplamPuan,TürkçeNet,MatematikNet,FenNet,SosyalNet,DinNet,İngilizceNet,Notlar"
                                )
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                            }

                            if selectedDataTypes.contains(.performance) {
                                Text("Performans CSV Başlıkları:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)

                                Text(
                                    "Öğrenci,ÖğrenciSoyadı,Ders,Konu,DoğruSayısı,YanlışSayısı,BoşSayısı,Süre,Notlar,Tarih"
                                )
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color(.systemGray6))
                                .cornerRadius(4)
                            }
                        }
                    } else if importFormat == .json {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("JSON Yapısı:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text(
                                """
                                {
                                  "students": [...],
                                  "exams": [...],
                                  "performance": [...]
                                }
                                """
                            )
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .cornerRadius(4)
                        }
                    } else if importFormat == .excel {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Excel Sayfa Yapısı:")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Text(
                                "• Sayfa 1: Öğrenciler\n• Sayfa 2: Sınavlar\n• Sayfa 3: Performans"
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
                allowedContentTypes: getContentTypes(for: importFormat),
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
            .alert("İçe Aktarma Sonucu", isPresented: $showingImportResult) {
                Button("Tamam") {}
            } message: {
                Text(importStatusMessage)
            }
        }
    }

    private func getContentTypes(for format: ImportFormat) -> [UTType] {
        switch format {
        case .csv:
            return [.commaSeparatedText]
        case .json:
            return [.json]
        case .excel:
            return [UTType(filenameExtension: "xlsx") ?? .data]
        }
    }

    private func importData(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            print("Could not access file")
            return
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            var results: [String: Int] = [:]

            switch importFormat {
            case .csv:
                results = try importCSVData(from: url)
            case .json:
                results = try importJSONData(from: url)
            case .excel:
                results = try importExcelData(from: url)
            }

            let totalImported = results.values.reduce(0, +)
            var message = "Toplam \(totalImported) kayıt başarıyla içe aktarıldı:\n\n"
            for (key, count) in results {
                if count > 0 {
                    message += "• \(key): \(count)\n"
                }
            }

            importStatusMessage = message
            showingImportResult = true

            print("Data imported successfully from \(url.lastPathComponent)")
        } catch {
            importStatusMessage = "Aktarma hatası: \(error.localizedDescription)"
            showingImportResult = true
            print("Import failed: \(error.localizedDescription)")
        }

        dismiss()
    }

    private func importCSVData(from url: URL) throws -> [String: Int] {
        let content = try String(contentsOf: url, encoding: .utf8)
        var results: [String: Int] = [:]

        // Detect CSV type based on header or filename
        if content.contains("ÖğrenciAdı,ÖğrenciSoyadı,SınavAdı")
            && selectedDataTypes.contains(.exams)
        {
            results["Sınavlar"] = try importExamCSV(content: content)
        } else if content.contains("Öğrenci,ÖğrenciSoyadı,Ders,Konu,DoğruSayısı")
            && selectedDataTypes.contains(.performance)
        {
            results["Performans"] = try importPerformanceCSV(content: content)
        } else if selectedDataTypes.contains(.students) {
            results["Öğrenciler"] = try importStudentCSV(content: content)
        }

        try modelContext.save()
        return results
    }

    func importStudentCSV(content: String) throws -> Int {
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
                notes: components.count > 12
                    ? components[12].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            )

            // Import target scores if available
            // CSV format: Ad,Soyad,Okul,Sınıf,Şube,Hedef Toplam,Hedef Türkçe,Hedef Matematik,Hedef Fen,Hedef Sosyal,Hedef Din,Hedef İngilizce,Notlar
            if components.count > 5,
                let targetTotal = Double(
                    components[5].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetTotalScore = targetTotal
            }
            if components.count > 6,
                let targetTurkce = Double(
                    components[6].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetTurkceNet = targetTurkce
            }
            if components.count > 7,
                let targetMat = Double(
                    components[7].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetMatematikNet = targetMat
            }
            if components.count > 8,
                let targetFen = Double(
                    components[8].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetFenNet = targetFen
            }
            if components.count > 9,
                let targetSosyal = Double(
                    components[9].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetSosyalNet = targetSosyal
            }
            if components.count > 10,
                let targetDin = Double(
                    components[10].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetDinNet = targetDin
            }
            if components.count > 11,
                let targetIng = Double(
                    components[11].trimmingCharacters(in: .whitespacesAndNewlines))
            {
                student.targetIngilizceNet = targetIng
            }

            modelContext.insert(student)
        }

        return lines.count - 1
    }

    func importExamCSV(content: String) throws -> Int {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return 0 }

        // Get existing students
        let students = try modelContext.fetch(FetchDescriptor<Student>())
        var studentMap: [String: Student] = [:]
        for student in students {
            studentMap["\(student.firstName) \(student.lastName)"] = student
        }

        var importedCount = 0

        for line in lines.dropFirst() {
            let components = line.components(separatedBy: ",")
            guard components.count >= 4 else { continue }

            let studentName =
                "\(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) \(components[1].trimmingCharacters(in: .whitespacesAndNewlines))"
            guard let student = studentMap[studentName] else { continue }

            let examName = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let totalScore =
                Double(components[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

            let exam = PracticeExam(name: examName, totalScore: totalScore)

            // Add subject nets if available
            if components.count > 5, let turkceNet = Double(components[5]) {
                exam.turkceNet = turkceNet
            }
            if components.count > 6, let matNet = Double(components[6]) {
                exam.matematikNet = matNet
            }
            if components.count > 7, let fenNet = Double(components[7]) {
                exam.fenNet = fenNet
            }
            if components.count > 8, let sosyalNet = Double(components[8]) {
                exam.sosyalNet = sosyalNet
            }
            if components.count > 9, let dinNet = Double(components[9]) {
                exam.dinNet = dinNet
            }
            if components.count > 10, let ingNet = Double(components[10]) {
                exam.ingilizceNet = ingNet
            }
            if components.count > 11 {
                exam.notes = components[11].trimmingCharacters(in: .whitespacesAndNewlines)
            }

            exam.student = student
            modelContext.insert(exam)
            importedCount += 1
        }

        return importedCount
    }

    func importPerformanceCSV(content: String) throws -> Int {
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else { return 0 }

        // Get existing students
        let students = try modelContext.fetch(FetchDescriptor<Student>())
        var studentMap: [String: Student] = [:]
        for student in students {
            studentMap["\(student.firstName) \(student.lastName)"] = student
        }

        var importedCount = 0

        for line in lines.dropFirst() {
            let components = line.components(separatedBy: ",")
            guard components.count >= 7 else { continue }

            let studentName =
                "\(components[0].trimmingCharacters(in: .whitespacesAndNewlines)) \(components[1].trimmingCharacters(in: .whitespacesAndNewlines))"
            guard let student = studentMap[studentName] else { continue }

            let subject = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let topic = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
            let correctCount =
                Int(components[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let wrongCount = Int(components[5].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            let emptyCount = Int(components[6].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

            let performance = QuestionPerformance(
                subject: subject,
                topic: topic,
                correct: correctCount,
                wrong: wrongCount,
                empty: emptyCount,
                timeInMinutes: components.count > 7
                    ? (Int(components[7].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0) : 0,
                notes: components.count > 8
                    ? components[8].trimmingCharacters(in: .whitespacesAndNewlines) : ""
            )

            // Parse date if available
            if components.count > 9 {
                performance.date =
                    parseDate(from: components[9].trimmingCharacters(in: .whitespacesAndNewlines))
                    ?? Date()
            }

            performance.student = student
            modelContext.insert(performance)
            importedCount += 1
        }

        return importedCount
    }

    private func importJSONData(from url: URL) throws -> [String: Int] {
        let data = try Data(contentsOf: url)
        var results: [String: Int] = [:]

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ImportError.invalidFormat
        }

        // Import students
        if let studentsData = json["students"] as? [[String: Any]],
            selectedDataTypes.contains(.students)
        {
            results["Öğrenciler"] = try importStudentsFromJSON(studentsData)
        }

        // Import exams
        if let examsData = json["exams"] as? [[String: Any]], selectedDataTypes.contains(.exams) {
            results["Sınavlar"] = try importExamsFromJSON(examsData)
        }

        // Import performance data
        if let performanceData = json["performance"] as? [[String: Any]],
            selectedDataTypes.contains(.performance)
        {
            results["Performans"] = try importPerformanceFromJSON(performanceData)
        }

        try modelContext.save()
        return results
    }

    private func importStudentsFromJSON(_ studentsData: [[String: Any]]) throws -> Int {
        for studentData in studentsData {
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

            // Import target scores
            if let targetTotal = studentData["targetTotalScore"] as? Double {
                student.targetTotalScore = targetTotal
            }
            if let targetTurkce = studentData["targetTurkceNet"] as? Double {
                student.targetTurkceNet = targetTurkce
            }
            // ... other target scores

            modelContext.insert(student)
        }
        return studentsData.count
    }

    private func importExamsFromJSON(_ examsData: [[String: Any]]) throws -> Int {
        // Get existing students
        let students = try modelContext.fetch(FetchDescriptor<Student>())
        var studentMap: [String: Student] = [:]
        for student in students {
            studentMap["\(student.firstName) \(student.lastName)"] = student
        }

        var importedCount = 0

        for examData in examsData {
            guard let studentFirstName = examData["studentFirstName"] as? String,
                let studentLastName = examData["studentLastName"] as? String,
                let examName = examData["examName"] as? String,
                let totalScore = examData["totalScore"] as? Double
            else {
                continue
            }

            let studentName = "\(studentFirstName) \(studentLastName)"
            guard let student = studentMap[studentName] else { continue }

            let exam = PracticeExam(name: examName, totalScore: totalScore)

            // Parse date if available
            if let dateString = examData["date"] as? String {
                exam.date = parseDate(from: dateString) ?? Date()
            }

            // Add subject nets
            if let turkceNet = examData["turkceNet"] as? Double {
                exam.turkceNet = turkceNet
            }
            if let matematikNet = examData["matematikNet"] as? Double {
                exam.matematikNet = matematikNet
            }
            if let fenNet = examData["fenNet"] as? Double {
                exam.fenNet = fenNet
            }
            if let sosyalNet = examData["sosyalNet"] as? Double {
                exam.sosyalNet = sosyalNet
            }
            if let dinNet = examData["dinNet"] as? Double {
                exam.dinNet = dinNet
            }
            if let ingilizceNet = examData["ingilizceNet"] as? Double {
                exam.ingilizceNet = ingilizceNet
            }
            if let notes = examData["notes"] as? String {
                exam.notes = notes
            }

            exam.student = student
            modelContext.insert(exam)
            importedCount += 1
        }

        return importedCount
    }

    private func importPerformanceFromJSON(_ performanceData: [[String: Any]]) throws -> Int {
        // Get existing students
        let students = try modelContext.fetch(FetchDescriptor<Student>())
        var studentMap: [String: Student] = [:]
        for student in students {
            studentMap["\(student.firstName) \(student.lastName)"] = student
        }

        var importedCount = 0

        for performanceData in performanceData {
            guard let studentFirstName = performanceData["studentFirstName"] as? String,
                let studentLastName = performanceData["studentLastName"] as? String,
                let subject = performanceData["subject"] as? String,
                let topic = performanceData["topic"] as? String,
                let correctCount = performanceData["correctCount"] as? Int,
                let wrongCount = performanceData["wrongCount"] as? Int,
                let emptyCount = performanceData["emptyCount"] as? Int
            else {
                continue
            }

            let studentName = "\(studentFirstName) \(studentLastName)"
            guard let student = studentMap[studentName] else { continue }

            let performance = QuestionPerformance(
                subject: subject,
                topic: topic,
                correct: correctCount,
                wrong: wrongCount,
                empty: emptyCount,
                timeInMinutes: performanceData["timeInMinutes"] as? Int ?? 0,
                notes: performanceData["notes"] as? String ?? ""
            )

            // Parse date if available
            if let dateString = performanceData["date"] as? String {
                performance.date = parseDate(from: dateString) ?? Date()
            }

            performance.student = student
            modelContext.insert(performance)
            importedCount += 1
        }

        return importedCount
    }

    private func importExcelData(from url: URL) throws -> [String: Int] {
        // Excel import would require additional framework like xlsxwriter
        // For now, return empty result
        var results: [String: Int] = [:]
        results["Excel"] = 0
        return results
    }

    private func parseDate(from string: String?) -> Date? {
        guard let string = string else { return nil }

        // Try different date formats
        let formatters = [
            ISO8601DateFormatter(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd.MM.yyyy"
                return formatter
            }(),
            {
                let formatter = DateFormatter()
                formatter.dateFormat = "dd/MM/yyyy"
                return formatter
            }(),
        ]

        for formatter in formatters {
            if let iso8601Formatter = formatter as? ISO8601DateFormatter {
                if let date = iso8601Formatter.date(from: string) {
                    return date
                }
            } else if let dateFormatter = formatter as? DateFormatter {
                if let date = dateFormatter.date(from: string) {
                    return date
                }
            }
        }

        return nil
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
