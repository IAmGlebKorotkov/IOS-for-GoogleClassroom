import SwiftUI

struct TeamTaskView: View {
    @StateObject private var vm: TeamTaskViewModel
    let taskTitle: String
    let maxScore: Int?

    @State private var showRename = false
    @State private var renameTeamId: UUID?
    @State private var newTeamName = ""

    init(assignmentId: UUID, role: UserRoleType, taskTitle: String, maxScore: Int?) {
        _vm = StateObject(wrappedValue: TeamTaskViewModel(assignmentId: assignmentId, role: role))
        self.taskTitle = taskTitle
        self.maxScore = maxScore
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.teams.isEmpty {
                ProgressView("Загрузка команд…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if vm.teams.isEmpty {
                ContentUnavailableView(
                    "Нет команд",
                    systemImage: "person.3",
                    description: Text("Команды ещё не созданы")
                )
            } else {
                List {
                    if let myTeam = vm.myTeam {
                        Section("Моя команда") {
                            TeamCardView(
                                team: myTeam,
                                isMine: true,
                                isCaptain: vm.isCaptain,
                                onLeave: { Task { await vm.leaveTeam() } },
                                onTransferCaptain: { userId in Task { await vm.transferCaptain(toUserId: userId) } },
                                onStartVoting: { Task { await vm.startVoting() } }
                            )
                        }
                    }

                    let otherTeams = vm.teams.filter { $0.id != vm.myTeam?.id }
                    if !otherTeams.isEmpty {
                        Section("Все команды (\(vm.teams.count))") {
                            ForEach(otherTeams) { team in
                                teamRow(team: team)
                            }
                        }
                    } else if vm.myTeam != nil {
                        Section("Все команды (\(vm.teams.count))") {
                            ForEach(vm.teams) { team in
                                teamRow(team: team)
                            }
                        }
                    }
                }
                .refreshable { await vm.load() }
            }
        }
        .navigationTitle("Команды")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if vm.role == .teacher {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        ForEach(vm.teams) { team in
                            Button("Переименовать «\(team.name)»") {
                                renameTeamId = team.id
                                newTeamName = team.name
                                showRename = true
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
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
        .alert("Переименовать команду", isPresented: $showRename) {
            TextField("Новое название", text: $newTeamName)
            Button("Сохранить") {
                if let id = renameTeamId {
                    Task { await vm.renameTeam(teamId: id, newName: newTeamName) }
                }
            }
            Button("Отмена", role: .cancel) {}
        }
        .task { await vm.load() }
    }

    @ViewBuilder
    private func teamRow(team: TeamDto) -> some View {
        DisclosureGroup {
            ForEach(team.members, id: \.userId) { member in
                HStack {
                    Image(systemName: member.role == .leader ? "crown.fill" : "person.fill")
                        .foregroundStyle(member.role == .leader ? .yellow : .secondary)
                        .font(.caption)
                    Text(member.credentials)
                        .font(.subheadline)
                    if member.role == .leader {
                        Text("Капитан")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(4)
                    }
                    Spacer()
                    if vm.role == .teacher {
                        if member.role != .leader {
                            Button {
                                Task { await vm.setFixedCaptain(teamId: team.id, userId: member.userId) }
                            } label: {
                                Image(systemName: "crown")
                                    .font(.caption)
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.borderless)
                        }
                        Button(role: .destructive) {
                            Task { await vm.removeStudent(teamId: team.id, studentId: member.userId) }
                        } label: {
                            Image(systemName: "xmark.circle")
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name).font(.headline)
                    Text("\(team.members.count) участников")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if vm.myTeam == nil && vm.role == .student {
                    Button("Вступить") {
                        Task { await vm.joinTeam(team.id) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }
        }
    }
}

private struct TeamCardView: View {
    let team: TeamDto
    let isMine: Bool
    let isCaptain: Bool
    let onLeave: () -> Void
    let onTransferCaptain: (UUID) -> Void
    let onStartVoting: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.blue)
                Text(team.name)
                    .font(.headline)
                Spacer()
                if isCaptain {
                    Label("Капитан", systemImage: "crown.fill")
                        .font(.caption.bold())
                        .foregroundStyle(.orange)
                }
            }

            ForEach(team.members, id: \.userId) { member in
                HStack(spacing: 6) {
                    Image(systemName: member.role == .leader ? "crown.fill" : "person.fill")
                        .font(.caption)
                        .foregroundStyle(member.role == .leader ? .yellow : .secondary)
                    Text(member.credentials)
                        .font(.subheadline)
                    Spacer()
                    if isCaptain && member.role != .leader {
                        Button("Назначить капитаном") {
                            onTransferCaptain(member.userId)
                        }
                        .font(.caption)
                        .buttonStyle(.borderless)
                        .foregroundStyle(.blue)
                    }
                }
            }

            HStack {
                Button(role: .destructive) {
                    onLeave()
                } label: {
                    Label("Выйти из команды", systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.subheadline)
                }
                .buttonStyle(.bordered)

                if isCaptain {
                    Spacer()
                    Button {
                        onStartVoting()
                    } label: {
                        Label("Голосование", systemImage: "hand.raised")
                            .font(.subheadline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
