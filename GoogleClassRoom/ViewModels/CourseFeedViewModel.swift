

import Foundation
import Combine

@MainActor
final class CourseFeedViewModel: ObservableObject {

    @Published var items: [CourseFeedItemDto] = []
    @Published var inviteCode: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    let courseId: UUID
    let courseTitle: String

    private let postService: PostServiceProtocol
    private let courseService: CourseServiceProtocol
    private var currentSkip = 0
    private let pageSize = 20
    private(set) var hasMore = true

    init(
        courseId: UUID,
        courseTitle: String,
        postService: PostServiceProtocol? = nil,
        courseService: CourseServiceProtocol? = nil
    ) {
        self.courseId = courseId
        self.courseTitle = courseTitle
        self.postService = postService ?? ServiceLocator.shared.postService
        self.courseService = courseService ?? ServiceLocator.shared.courseService
    }

    func loadFeed(reset: Bool = false) async {
        if reset {
            currentSkip = 0
            hasMore = true
            items = []
            await loadCourseDetails()
        }
        guard hasMore else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let response = try await postService.getFeed(
                courseId: courseId,
                skip: currentSkip,
                take: pageSize
            )
            let newItems = response.data?.records ?? []
            items.append(contentsOf: newItems)
            currentSkip += newItems.count
            hasMore = newItems.count == pageSize
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadCourseDetails() async {
        do {
            let response = try await courseService.getCourse(id: courseId)
            inviteCode = response.data?.inviteCode
        } catch {
            // Не критично — просто не покажем код
        }
    }
}
