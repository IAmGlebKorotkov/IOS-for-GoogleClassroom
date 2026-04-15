
import SwiftUI

struct CourseFeedView: View {
    @StateObject private var vm: CourseFeedViewModel
    private let role: UserRoleType
    @State private var showCreatePost = false
    @State private var showInviteCode = false

    init(courseId: UUID, courseTitle: String, role: UserRoleType) {
        _vm = StateObject(wrappedValue: CourseFeedViewModel(courseId: courseId, courseTitle: courseTitle))
        self.role = role
    }

    var body: some View {
        Group {
            if vm.isLoading && vm.items.isEmpty {
                ProgressView("Загрузка...")
            } else if vm.items.isEmpty {
                ContentUnavailableView(
                    "Нет записей",
                    systemImage: "doc.text",
                    description: Text("Здесь пока ничего нет")
                )
            } else {
                List {
                    ForEach(vm.items, id: \.id) { item in
                        NavigationLink(value: NavDestination.post(item)) {
                            FeedItemRowView(item: item)
                        }
                        .onAppear {
                            if item.id == vm.items.last?.id {
                                Task { await vm.loadFeed() }
                            }
                        }
                    }
                }
                .refreshable { await vm.loadFeed(reset: true) }
            }
        }
        .navigationTitle(vm.courseTitle)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            if role == .teacher {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showCreatePost = true
                    } label: {
                        Image(systemName: "plus")
                    }

                    Button {
                        showInviteCode = true
                    } label: {
                        Image(systemName: "person.badge.key.fill")
                    }

                    NavigationLink(value: NavDestination.members) {
                        Image(systemName: "person.2")
                    }

                    NavigationLink(value: NavDestination.analytics) {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }
            }
        }
        .navigationDestination(for: NavDestination.self) { dest in
            switch dest {
            case .post(let item):
                PostDetailView(postId: item.id, courseId: vm.courseId, title: item.title, role: role)
            case .members:
                CourseMembersView(courseId: vm.courseId)
            case .analytics:
                AnalyticsView(courseId: vm.courseId)
            }
        }
        .sheet(isPresented: $showCreatePost) {
            CreatePostView(courseId: vm.courseId)
        }
        .sheet(isPresented: $showInviteCode) {
            InviteCodeSheet(courseTitle: vm.courseTitle, inviteCode: vm.inviteCode)
        }
        .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
            Button("OK") { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .task { await vm.loadFeed(reset: true) }
    }

    enum NavDestination: Hashable {
        case post(CourseFeedItemDto)
        case members
        case analytics
    }
}

private struct InviteCodeSheet: View {
    let courseTitle: String
    let inviteCode: String?
    @Environment(\.dismiss) private var dismiss
    @State private var copied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                VStack(spacing: 12) {
                    Image(systemName: "person.badge.key.fill")
                        .font(.system(size: 52))
                        .foregroundStyle(.blue)

                    Text("Код приглашения")
                        .font(.title2.bold())

                    Text("Поделитесь этим кодом со студентами, чтобы они могли вступить в курс «\(courseTitle)»")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                if let code = inviteCode {
                    VStack(spacing: 16) {
                        Text(code)
                            .font(.system(size: 34, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 16)
                            .background(Color(.systemGray6))
                            .cornerRadius(14)

                        HStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = code
                                copied = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                            } label: {
                                Label(copied ? "Скопировано!" : "Копировать", systemImage: copied ? "checkmark" : "doc.on.doc")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(copied ? Color.green.opacity(0.15) : Color(.systemGray6))
                                    .foregroundStyle(copied ? .green : .primary)
                                    .cornerRadius(12)
                            }
                            .animation(.easeInOut(duration: 0.2), value: copied)

                            ShareLink(item: "Код для вступления в курс «\(courseTitle)»: \(code)") {
                                Label("Поделиться", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(.blue)
                                    .foregroundStyle(.white)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ProgressView("Загрузка кода…")
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") { dismiss() }
                }
            }
        }
    }
}

private struct FeedItemRowView: View {
    let item: CourseFeedItemDto

    private var icon: String {
        switch item.type {
        case .task: return "checkmark.circle"
        case .teamTask: return "person.3"
        case .post: return "doc.text"
        }
    }

    private var iconColor: Color {
        switch item.type {
        case .task: return .orange
        case .teamTask: return .purple
        case .post: return .blue
        }
    }

    private var typeLabel: String {
        switch item.type {
        case .task: return "Задание"
        case .teamTask: return "Командное задание"
        case .post: return "Материал"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(iconColor)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                HStack(spacing: 6) {
                    Text(typeLabel)
                        .font(.caption2)
                        .foregroundStyle(iconColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(iconColor.opacity(0.12))
                        .cornerRadius(4)
                    Text(item.createdDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
