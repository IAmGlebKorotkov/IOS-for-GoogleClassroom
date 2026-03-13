
import Foundation
import Combine

@MainActor
final class CourseMembersViewModel: ObservableObject {
    @Published var members: [CourseMemberDto] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    let courseId: UUID

    private let service: CourseServiceProtocol

    init(courseId: UUID, service: CourseServiceProtocol? = nil) {
        self.courseId = courseId
        self.service = service ?? ServiceLocator.shared.courseService
    }

    func loadMembers() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await service.getMembers(courseId: courseId, skip: 0, take: 100, query: nil)
            members = response.data?.records ?? []
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func changeRole(userId: UUID, to role: UserRoleType) async {
        do {
            _ = try await service.changeMemberRole(courseId: courseId, userId: userId, role: role)
            await loadMembers()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeMember(userId: UUID) async {
        do {
            _ = try await service.removeMember(courseId: courseId, userId: userId)
            members.removeAll { $0.id == userId }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
