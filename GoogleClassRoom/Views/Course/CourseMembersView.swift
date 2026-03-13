
import SwiftUI

struct CourseMembersView: View {
    @StateObject private var vm: CourseMembersViewModel

    init(courseId: UUID) {
        _vm = StateObject(wrappedValue: CourseMembersViewModel(courseId: courseId))
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.members.isEmpty {
                ProgressView("Загрузка участников...")
            } else if vm.members.isEmpty {
                ContentUnavailableView("Нет участников", systemImage: "person.slash")
            } else {
                List {
                    let teachers = vm.members.filter { $0.role == .teacher }
                    let students = vm.members.filter { $0.role == .student }

                    if !teachers.isEmpty {
                        Section("Преподаватели (\(teachers.count))") {
                            ForEach(teachers, id: \.id) { member in
                                MemberRowView(member: member) { action in
                                    Task { await handle(action: action, member: member) }
                                }
                            }
                        }
                    }

                    if !students.isEmpty {
                        Section("Ученики (\(students.count))") {
                            ForEach(students, id: \.id) { member in
                                MemberRowView(member: member) { action in
                                    Task { await handle(action: action, member: member) }
                                }
                            }
                        }
                    }
                }
                .refreshable { await vm.loadMembers() }
            }
        }
        .navigationTitle("Участники")
        .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task { await vm.loadMembers() }
    }

    private func handle(action: MemberAction, member: CourseMemberDto) async {
        switch action {
        case .promote:
            await vm.changeRole(userId: member.id, to: .teacher)
        case .demote:
            await vm.changeRole(userId: member.id, to: .student)
        case .remove:
            await vm.removeMember(userId: member.id)
        }
    }
}

enum MemberAction { case promote, demote, remove }

private struct MemberRowView: View {
    let member: CourseMemberDto
    let onAction: (MemberAction) -> Void

    var body: some View {
        HStack {
            Image(systemName: member.role == .teacher ? "person.fill.badge.plus" : "person.fill")
                .foregroundStyle(member.role == .teacher ? .blue : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(member.credentials)
                    .font(.headline)
                Text(member.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Menu {
                if member.role == .student {
                    Button("Сделать преподавателем", systemImage: "arrow.up.circle") {
                        onAction(.promote)
                    }
                } else {
                    Button("Сделать учеником", systemImage: "arrow.down.circle") {
                        onAction(.demote)
                    }
                }
                Button("Удалить из курса", systemImage: "trash", role: .destructive) {
                    onAction(.remove)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}
