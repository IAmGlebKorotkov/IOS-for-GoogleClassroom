
import SwiftUI

struct CourseFeedView: View {
    @StateObject private var vm: CourseFeedViewModel
    private let role: UserRoleType
    @State private var showCreatePost = false

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

private struct FeedItemRowView: View {
    let item: CourseFeedItemDto
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.type == .task ? "checkmark.circle" : "doc.text")
                .font(.title2)
                .foregroundStyle(item.type == .task ? .orange : .blue)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                Text(item.createdDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
