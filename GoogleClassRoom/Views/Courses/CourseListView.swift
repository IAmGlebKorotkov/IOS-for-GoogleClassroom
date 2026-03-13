

import SwiftUI

struct CourseListView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var vm = CourseListViewModel()

    @State private var showCreate = false
    @State private var showJoin = false

    var body: some View {
        NavigationStack {
            Group {
                if vm.isLoading && vm.courses.isEmpty {
                    ProgressView("Загрузка...")
                } else if vm.courses.isEmpty {
                    ContentUnavailableView(
                        "Нет курсов",
                        systemImage: "tray",
                        description: Text("Создайте курс или вступите по коду")
                    )
                } else {
                    List(vm.courses, id: \.id) { course in
                        NavigationLink(value: course) {
                            CourseRowView(course: course)
                        }
                    }
                    .refreshable { await vm.loadCourses() }
                }
            }
            .navigationTitle("Мои курсы")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Создать курс", systemImage: "plus") { showCreate = true }
                        Button("Вступить по коду", systemImage: "qrcode") { showJoin = true }
                        Divider()
                        Button("Выйти", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            Task { await authVM.logout() }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .navigationDestination(for: UserCourseDto.self) { course in
                CourseFeedView(
                    courseId: course.id,
                    courseTitle: course.title ?? "Курс",
                    role: course.role ?? .student
                )
            }
            .sheet(isPresented: $showCreate) {
                CreateCourseView(vm: vm)
            }
            .sheet(isPresented: $showJoin) {
                JoinCourseView(vm: vm)
            }
            .alert("Ошибка", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
        }
        .task { await vm.loadCourses() }
    }
}

private struct CourseRowView: View {
    let course: UserCourseDto

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(roleColor)
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(course.title ?? "Без названия")
                    .font(.headline)
                if let role = course.role {
                    Text(role == .teacher ? "Преподаватель" : "Студент")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var roleColor: Color {
        switch course.role {
        case .teacher: return .blue
        default: return .green
        }
    }
}
