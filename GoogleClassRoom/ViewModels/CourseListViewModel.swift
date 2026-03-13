

import Foundation
import Combine

@MainActor
final class CourseListViewModel: ObservableObject {

    @Published var courses: [UserCourseDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: CourseServiceProtocol

    init(service: CourseServiceProtocol? = nil) {
        self.service = service ?? ServiceLocator.shared.courseService
    }

    func loadCourses() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.getUserCourses(skip: 0, take: 50)
            courses = response.data?.records ?? []
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createCourse(title: String) async {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Введите название курса"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await service.createCourse(title: title)
            await loadCourses()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinCourse(code: String) async {
        guard !code.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Введите код приглашения"
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await service.joinCourse(inviteCode: code)
            await loadCourses()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
