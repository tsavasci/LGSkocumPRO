import SwiftData
import SwiftUI

struct AddPracticeExamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let student: Student

    @State private var name = ""
    @State private var date = Date()
    @State private var totalScore: String = ""
    @State private var notes = ""

    // Alert states
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Subject scores
    @State private var turkce = SubjectScores()
    @State private var matematik = SubjectScores()
    @State private var fen = SubjectScores()
    @State private var sosyal = SubjectScores()
    @State private var din = SubjectScores()
    @State private var ingilizce = SubjectScores()

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Sınav Bilgileri")) {
                    TextField("Sınav Adı", text: $name)
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Toplam Puan")
                            Spacer()
                            TextField("Puan", text: $totalScore)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            isScoreInvalid ? Color.red : Color.clear, lineWidth: 1)
                                )
                        }

                        if isScoreInvalid {
                            Text("LGS'de maksimum puan 500'dür")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                }

                Section(header: Text("Ders Puanları")) {
                    SubjectScoreRow(subject: "Türkçe", scores: $turkce)
                    SubjectScoreRow(subject: "Matematik", scores: $matematik)
                    SubjectScoreRow(subject: "Fen Bilimleri", scores: $fen)
                    SubjectScoreRow(subject: "Sosyal Bilgiler", scores: $sosyal)
                    SubjectScoreRow(subject: "Din Kültürü", scores: $din)
                    SubjectScoreRow(subject: "İngilizce", scores: $ingilizce)
                }

                Section(header: Text("Notlar")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Yeni Deneme Sınavı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveExam()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Hatalı Veri", isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && validateAllInputs().isEmpty
    }

    private var isScoreInvalid: Bool {
        if let score = Double(totalScore), score > 500 {
            return true
        }
        return false
    }

    private func validateAllInputs() -> String {
        // Validate subject question counts
        let subjects = [
            ("Türkçe", turkce, 20),
            ("Matematik", matematik, 20),
            ("Fen Bilimleri", fen, 20),
            ("Sosyal Bilgiler", sosyal, 10),
            ("Din Kültürü", din, 10),
            ("İngilizce", ingilizce, 10),
        ]

        for (subjectName, scores, maxQuestions) in subjects {
            let correct = Int(scores.correct) ?? 0
            let wrong = Int(scores.wrong) ?? 0
            let empty = Int(scores.empty) ?? 0
            let total = correct + wrong + empty

            if total > maxQuestions {
                return
                    "\(subjectName) dersi için toplam soru sayısı \(maxQuestions)'dan fazla olamaz. (Girilen: \(total))"
            }
        }

        // Validate total score
        if let score = Double(totalScore), score > 500 {
            return "LGS'de maksimum puan 500'dür. Lütfen geçerli bir puan giriniz."
        }

        return ""
    }

    private func saveExam() {
        let validationError = validateAllInputs()
        if !validationError.isEmpty {
            alertMessage = validationError
            showingAlert = true
            return
        }

        withAnimation {
            let exam = PracticeExam(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                date: date,
                totalScore: Double(totalScore) ?? 0.0,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            // Set subject net scores
            exam.turkceNet = turkce.net
            exam.matematikNet = matematik.net
            exam.fenNet = fen.net
            exam.sosyalNet = sosyal.net
            exam.dinNet = din.net
            exam.ingilizceNet = ingilizce.net

            // Set up the relationship
            exam.student = student

            do {
                // Insert the exam
                modelContext.insert(exam)

                // Manually add to student's exams array
                student.objectWillChange.send()
                student.practiceExams.append(exam)

                // Save changes
                try modelContext.save()

                // Dismiss after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    dismiss()
                }
            } catch {
                print("❌ Error saving practice exam: \(error.localizedDescription)")
            }
        }
    }
}

struct SubjectScores {
    var correct: String = ""
    var wrong: String = ""
    var empty: String = ""

    var net: Double {
        let correctCount = Double(correct) ?? 0
        let wrongCount = Double(wrong) ?? 0
        return max(0, correctCount - (wrongCount / 3))
    }
}

struct SubjectScoreRow: View {
    let subject: String
    @Binding var scores: SubjectScores

    private var netScore: String {
        String(format: "%.2f", scores.net)
    }

    private var maxQuestions: Int {
        switch subject {
        case "Türkçe", "Matematik", "Fen Bilimleri":
            return 20
        default:
            return 10
        }
    }

    private var totalQuestions: Int {
        let correct = Int(scores.correct) ?? 0
        let wrong = Int(scores.wrong) ?? 0
        let empty = Int(scores.empty) ?? 0
        return correct + wrong + empty
    }

    private var isOverLimit: Bool {
        totalQuestions > maxQuestions
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(subject)
                    .font(.headline)
                    .foregroundColor(isOverLimit ? .red : .primary)

                Spacer()

                Text("\(totalQuestions)/\(maxQuestions)")
                    .font(.caption)
                    .foregroundColor(isOverLimit ? .red : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isOverLimit ? Color.red.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.bottom, 4)

            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Doğru")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $scores.correct)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Yanlış")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $scores.wrong)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Boş")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("0", text: $scores.empty)
                        .keyboardType(.numberPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Net")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(netScore)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(8)
                        .background(isOverLimit ? Color.red.opacity(0.1) : Color(.systemGray6))
                        .cornerRadius(6)
                        .foregroundColor(isOverLimit ? .red : .primary)
                }
            }
        }
        .padding(.vertical, 8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isOverLimit ? Color.red : Color.clear, lineWidth: 1)
        )
    }
}

struct EditPracticeExamView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let student: Student
    let exam: PracticeExam

    @State private var name = ""
    @State private var date = Date()
    @State private var totalScore: String = ""
    @State private var notes = ""

    // Alert states
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Subject scores
    @State private var turkce = SubjectScores()
    @State private var matematik = SubjectScores()
    @State private var fen = SubjectScores()
    @State private var sosyal = SubjectScores()
    @State private var din = SubjectScores()
    @State private var ingilizce = SubjectScores()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sınav Bilgileri")) {
                    TextField("Sınav Adı", text: $name)
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Toplam Puan")
                            Spacer()
                            TextField("Puan", text: $totalScore)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(
                                            isEditScoreInvalid ? Color.red : Color.clear,
                                            lineWidth: 1)
                                )
                        }

                        if isEditScoreInvalid {
                            Text("LGS'de maksimum puan 500'dür")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                    }
                }

                Section(header: Text("Ders Puanları")) {
                    SubjectScoreRow(subject: "Türkçe", scores: $turkce)
                    SubjectScoreRow(subject: "Matematik", scores: $matematik)
                    SubjectScoreRow(subject: "Fen Bilimleri", scores: $fen)
                    SubjectScoreRow(subject: "Sosyal Bilgiler", scores: $sosyal)
                    SubjectScoreRow(subject: "Din Kültürü", scores: $din)
                    SubjectScoreRow(subject: "İngilizce", scores: $ingilizce)
                }

                Section(header: Text("Notlar")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Deneme Sınavı Düzenle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        updateExam()
                    }
                    .disabled(!isEditFormValid)
                }
            }
        }
        .alert("Hatalı Veri", isPresented: $showingAlert) {
            Button("Tamam", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            loadExamData()
        }
    }

    private func loadExamData() {
        name = exam.name
        date = exam.date
        totalScore = String(format: "%.0f", exam.totalScore)
        notes = exam.notes

        // Load subject scores (converting from net back to approximate correct/wrong)
        turkce.correct = String(format: "%.0f", exam.turkceNet)
        matematik.correct = String(format: "%.0f", exam.matematikNet)
        fen.correct = String(format: "%.0f", exam.fenNet)
        sosyal.correct = String(format: "%.0f", exam.sosyalNet)
        din.correct = String(format: "%.0f", exam.dinNet)
        ingilizce.correct = String(format: "%.0f", exam.ingilizceNet)
    }

    private var isEditFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && validateEditInputs().isEmpty
    }

    private var isEditScoreInvalid: Bool {
        if let score = Double(totalScore), score > 500 {
            return true
        }
        return false
    }

    private func validateEditInputs() -> String {
        // Validate subject question counts
        let subjects = [
            ("Türkçe", turkce, 20),
            ("Matematik", matematik, 20),
            ("Fen Bilimleri", fen, 20),
            ("Sosyal Bilgiler", sosyal, 10),
            ("Din Kültürü", din, 10),
            ("İngilizce", ingilizce, 10),
        ]

        for (subjectName, scores, maxQuestions) in subjects {
            let correct = Int(scores.correct) ?? 0
            let wrong = Int(scores.wrong) ?? 0
            let empty = Int(scores.empty) ?? 0
            let total = correct + wrong + empty

            if total > maxQuestions {
                return
                    "\(subjectName) dersi için toplam soru sayısı \(maxQuestions)'dan fazla olamaz. (Girilen: \(total))"
            }
        }

        // Validate total score
        if let score = Double(totalScore), score > 500 {
            return "LGS'de maksimum puan 500'dür. Lütfen geçerli bir puan giriniz."
        }

        return ""
    }

    private func updateExam() {
        let validationError = validateEditInputs()
        if !validationError.isEmpty {
            alertMessage = validationError
            showingAlert = true
            return
        }

        withAnimation {
            // Update exam properties
            exam.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            exam.date = date
            exam.totalScore = Double(totalScore) ?? exam.totalScore
            exam.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

            // Update subject net scores
            exam.turkceNet = turkce.net
            exam.matematikNet = matematik.net
            exam.fenNet = fen.net
            exam.sosyalNet = sosyal.net
            exam.dinNet = din.net
            exam.ingilizceNet = ingilizce.net

            do {
                try modelContext.save()

                // Dismiss after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            } catch {
                print("❌ Error updating practice exam: \(error.localizedDescription)")
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, configurations: config)

    let student = Student(
        firstName: "Ahmet",
        lastName: "Yılmaz",
        school: "Örnek Ortaokulu",
        grade: 8
    )

    let exam = PracticeExam(
        name: "Örnek Deneme",
        date: Date(),
        totalScore: 450,
        notes: "İyi performans"
    )

    container.mainContext.insert(student)
    container.mainContext.insert(exam)

    return NavigationStack {
        EditPracticeExamView(student: student, exam: exam)
    }
    .modelContainer(container)
}

struct AddQuestionPerformanceView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let student: Student

    @State private var selectedSubject = "Türkçe"
    @State private var date = Date()
    @State private var correctCount = ""
    @State private var wrongCount = ""
    @State private var emptyCount = ""
    @State private var timeInMinutes = ""
    @State private var notes = ""

    private let subjects = [
        "Türkçe", "Matematik", "Fen Bilimleri", "Sosyal Bilgiler", "Din Kültürü", "İngilizce",
    ]

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Soru Çözümü Bilgileri")) {
                    Picker("Ders", selection: $selectedSubject) {
                        ForEach(subjects, id: \.self) { subject in
                            Text(subject).tag(subject)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                }

                Section(header: Text("Soru Sayıları")) {
                    HStack {
                        Text("Doğru")
                        Spacer()
                        TextField("0", text: $correctCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack {
                        Text("Yanlış")
                        Spacer()
                        TextField("0", text: $wrongCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack {
                        Text("Boş")
                        Spacer()
                        TextField("0", text: $emptyCount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }

                    HStack {
                        Text("Süre (dakika) - Opsiyonel")
                        Spacer()
                        TextField("0", text: $timeInMinutes)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 60)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }

                Section(header: Text("Notlar")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Yeni Soru Çözümü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveQuestionPerformance()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var isFormValid: Bool {
        let correct = Int(correctCount) ?? 0
        let wrong = Int(wrongCount) ?? 0
        let empty = Int(emptyCount) ?? 0
        return correct + wrong + empty > 0
    }

    private func saveQuestionPerformance() {
        withAnimation {
            let questionPerformance = QuestionPerformance(
                subject: selectedSubject,
                topic: selectedSubject,  // Şu an için ders adı ile aynı
                correct: Int(correctCount) ?? 0,
                wrong: Int(wrongCount) ?? 0,
                empty: Int(emptyCount) ?? 0,
                timeInMinutes: Int(timeInMinutes) ?? 0,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
            )

            questionPerformance.date = date
            questionPerformance.student = student

            do {
                modelContext.insert(questionPerformance)
                student.questionPerformances.append(questionPerformance)
                try modelContext.save()

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    dismiss()
                }
            } catch {
                print("❌ Error saving question performance: \(error.localizedDescription)")
            }
        }
    }
}
