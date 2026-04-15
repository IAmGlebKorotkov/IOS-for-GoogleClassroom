import SwiftUI

struct GradeDistributionView: View {

    @StateObject private var vm: GradeDistributionViewModel
    let teamName: String

    init(teamId: UUID, assignmentId: UUID, teamName: String, isCaptain: Bool) {
        _vm = StateObject(wrappedValue: GradeDistributionViewModel(teamId: teamId, assignmentId: assignmentId, isCaptain: isCaptain))
        self.teamName = teamName
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.distribution == nil {
                ProgressView("Загрузка…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let dist = vm.distribution {
                distributionContent(dist: dist)
            } else {
                ContentUnavailableView(
                    "Нет данных",
                    systemImage: "chart.pie",
                    description: Text("Оценка команды ещё не выставлена")
                )
            }
        }
        .navigationTitle("Распределение оценок")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .alert("Готово", isPresented: .constant(vm.successMessage != nil)) {
            Button("OK") { vm.successMessage = nil }
        } message: {
            Text(vm.successMessage ?? "")
        }
        .task { await vm.load() }
    }

    private func distributionContent(dist: GradeDistributionResponseDto) -> some View {
        Form {
            Section {
                LabeledContent("Команда", value: teamName)
                LabeledContent("Общая оценка команды", value: String(format: "%.1f", dist.teamRawScore))
                LabeledContent("Распределено", value: String(format: "%.1f / %.1f", dist.sumDistributed, dist.teamRawScore))
            } header: {
                Text("Информация")
            }

            Section {
                ForEach(dist.entries, id: \.userId) { entry in
                    HStack {
                        Text(memberName(userId: entry.userId, entries: dist.entries))
                            .font(.subheadline)
                        Spacer()
                        if vm.isCaptain {
                            TextField("Баллы", text: Binding(
                                get: { vm.editablePoints[entry.userId] ?? String(format: "%.1f", entry.points) },
                                set: { vm.editablePoints[entry.userId] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 70)
                            .padding(6)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        } else {
                            Text(String(format: "%.1f", entry.points))
                                .font(.subheadline.bold())
                        }
                    }
                }
            } header: {
                Text("Баллы участников")
            } footer: {
                if vm.isCaptain {
                    Text("Сумма баллов должна равняться общей оценке команды (\(String(format: "%.1f", dist.teamRawScore)))")
                        .font(.caption)
                }
            }

            if dist.distributionChanged {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Распределение уже изменено")
                            .font(.subheadline)
                    }
                    Text("Проголосуйте «за» или «против» текущего распределения:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button {
                            Task { await vm.vote(.for) }
                        } label: {
                            Label("За", systemImage: "hand.thumbsup.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)

                        Button {
                            Task { await vm.vote(.against) }
                        } label: {
                            Label("Против", systemImage: "hand.thumbsdown.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                    }
                } header: {
                    Text("Голосование")
                }
            }

            if vm.isCaptain {
                Section {
                    Button {
                        Task { await vm.save() }
                    } label: {
                        Group {
                            if vm.isSaving {
                                ProgressView()
                            } else {
                                Text("Сохранить распределение")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(vm.isSaving)
                }
            }
        }
    }

    private func memberName(userId: UUID, entries: [GradeDistributionEntryDto]) -> String {
        return "Участник"
    }
}
