
import SwiftUI

struct AnalyticsView: View {
    @StateObject private var vm: AnalyticsViewModel
    @State private var showFilters = false

    init(courseId: UUID) {
        _vm = StateObject(wrappedValue: AnalyticsViewModel(courseId: courseId))
    }

    var body: some View {
        Group {
            if vm.isLoading {
                ProgressView("Загрузка данных…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.rows.isEmpty {
                ContentUnavailableView(
                    "Нет данных",
                    systemImage: "chart.bar",
                    description: Text("В курсе нет учеников или заданий")
                )
            } else {
                VStack(spacing: 0) {
                    filterBar
                    Divider()
                    gradeTable
                }
            }
        }
        .navigationTitle("Аналитика")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle\(showFilters ? ".fill" : "")")
                }
            }
        }
        .sheet(isPresented: $showFilters) {
            FiltersView(vm: vm)
        }
        .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task { await vm.loadData() }
    }

    

    private var filterBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("Поиск ученика", text: $vm.studentSearch)
                .textFieldStyle(.plain)
            if !vm.studentSearch.isEmpty {
                Button { vm.studentSearch = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }

    

    private var gradeTable: some View {
        ScrollView([.horizontal, .vertical]) {
            let visibleTasks = vm.filteredTasks
            let visibleRows = vm.filteredRows

            LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(visibleRows, id: \.member.id) { row in
                        HStack(spacing: 0) {
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(row.member.credentials)
                                    .font(.subheadline.bold())
                                    .lineLimit(1)
                                let avg = row.averageScore
                                Text(avg > 0 ? String(format: "Ср: %.1f", avg) : "—")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(width: 140, alignment: .leading)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 10)
                            .background(Color(.systemBackground))

                            Divider()

                            
                            ForEach(visibleTasks, id: \.id) { task in
                                CellView(cell: row.cells[task.id] ?? AnalyticsCell(value: .notSubmitted))
                                    .frame(width: 90)
                                Divider()
                            }
                        }
                        .overlay(alignment: .bottom) {
                            Divider()
                        }
                    }
                } header: {
                    headerRow(tasks: visibleTasks)
                }
            }
        }
    }

    private func headerRow(tasks: [AnalyticsTask]) -> some View {
        HStack(spacing: 0) {
            Text("Ученик / Ср.балл")
                .font(.caption.bold())
                .frame(width: 140, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))

            Divider()

            ForEach(tasks, id: \.id) { task in
                VStack(spacing: 2) {
                    Text(task.title)
                        .font(.caption2.bold())
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    if task.taskType == .mandatory {
                        Text("обяз.")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }
                .frame(width: 90)
                .padding(.vertical, 6)
                .background(Color(.systemGray5))

                Divider()
            }
        }
    }
}

private struct CellView: View {
    let cell: AnalyticsCell

    var body: some View {
        ZStack {
            cellBackground
            Text(cellText)
                .font(.caption.bold())
                .foregroundStyle(cellTextColor)
                .multilineTextAlignment(.center)
                .padding(4)
        }
        .frame(height: 48)
    }

    private var cellText: String {
        switch cell.value {
        case .score(let s): return "\(s)"
        case .returned: return "Возвр."
        case .pending: return "Ожид."
        case .notSubmitted: return "—"
        }
    }

    private var cellBackground: Color {
        switch cell.value {
        case .score: return Color.green.opacity(0.15)
        case .returned: return Color.red.opacity(0.12)
        case .pending: return Color.orange.opacity(0.12)
        case .notSubmitted: return Color.clear
        }
    }

    private var cellTextColor: Color {
        switch cell.value {
        case .score: return .green
        case .returned: return .red
        case .pending: return .orange
        case .notSubmitted: return .secondary
        }
    }
}

private struct FiltersView: View {
    @ObservedObject var vm: AnalyticsViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var useStartDate = false
    @State private var useEndDate = false
    @State private var localStart = Date()
    @State private var localEnd = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Задания") {
                    Toggle("Только обязательные", isOn: $vm.showMandatoryOnly)
                }
                Section("Период (дедлайн / дата создания)") {
                    Toggle("С даты", isOn: $useStartDate)
                    if useStartDate {
                        DatePicker("Начало", selection: $localStart, displayedComponents: .date)
                    }
                    Toggle("По дату", isOn: $useEndDate)
                    if useEndDate {
                        DatePicker("Конец", selection: $localEnd, displayedComponents: .date)
                    }
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Сбросить") {
                        vm.showMandatoryOnly = false
                        vm.startDate = nil
                        vm.endDate = nil
                        useStartDate = false
                        useEndDate = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Применить") {
                        vm.startDate = useStartDate ? localStart : nil
                        vm.endDate = useEndDate ? localEnd : nil
                        dismiss()
                    }
                }
            }
            .onAppear {
                useStartDate = vm.startDate != nil
                useEndDate = vm.endDate != nil
                localStart = vm.startDate ?? Date()
                localEnd = vm.endDate ?? Date()
            }
        }
    }
}
