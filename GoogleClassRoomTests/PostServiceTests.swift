

import XCTest
@testable import GoogleClassRoom

final class PostServiceTests: XCTestCase {

    var sut: MockPostService!

    override func setUp() {
        super.setUp()
        sut = MockPostService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    

    
    func test_createPost_asAnnouncement_returnsId() async throws {
        let request = CreatePostRequest(
            type: .post,
            title: "Важное объявление",
            text: "Занятие перенесено на пятницу",
            deadline: nil,
            maxScore: nil,
            taskType: nil,
            solvableAfterDeadline: nil,
            files: nil
        )

        let response = try await sut.createPost(courseId: UUID(), request: request)

        XCTAssertEqual(sut.createCallCount, 1)
        XCTAssertEqual(sut.lastCreatedRequest?.type, .post)
        XCTAssertEqual(response.type, .success)
        XCTAssertNotNil(response.data?.id)
    }

    

    
    func test_createTask_withDeadlineAndMaxScore_returnsId() async throws {
        let deadline = Date().addingTimeInterval(7 * 24 * 3600) 
        let request = CreatePostRequest(
            type: .task,
            title: "Лабораторная работа #1",
            text: "Реализовать алгоритм сортировки",
            deadline: deadline,
            maxScore: 10,
            taskType: .mandatory,
            solvableAfterDeadline: false,
            files: nil
        )

        let response = try await sut.createPost(courseId: UUID(), request: request)

        XCTAssertEqual(sut.lastCreatedRequest?.type, .task)
        XCTAssertEqual(sut.lastCreatedRequest?.maxScore, 10)
        XCTAssertEqual(sut.lastCreatedRequest?.taskType, .mandatory)
        XCTAssertEqual(response.type, .success)
    }

    
    func test_createTask_asOptional_setsTaskTypeOptional() async throws {
        let request = CreatePostRequest(
            type: .task,
            title: "Доп. задание",
            text: nil,
            deadline: nil,
            maxScore: 5,
            taskType: .optional,
            solvableAfterDeadline: nil,
            files: nil
        )

        _ = try await sut.createPost(courseId: UUID(), request: request)

        XCTAssertEqual(sut.lastCreatedRequest?.taskType, .optional)
    }

    
    func test_defaultMaxScore_isValid() {
        XCTAssertTrue(PostValidator.isValidMaxScore(5))
    }

    

    
    func test_createPost_withFiles_includesFileIds() async throws {
        let fileIds = [UUID(), UUID()]
        let request = CreatePostRequest(
            type: .post,
            title: "Материалы лекции",
            text: "Ссылки на материалы",
            deadline: nil,
            maxScore: nil,
            taskType: nil,
            solvableAfterDeadline: nil,
            files: fileIds
        )

        _ = try await sut.createPost(courseId: UUID(), request: request)

        XCTAssertEqual(sut.lastCreatedRequest?.files?.count, 2)
    }

    

    
    func test_deletePost_callsServiceWithCorrectId() async throws {
        let postId = UUID()
        sut.stubPostId = postId

        let response = try await sut.deletePost(id: postId)

        XCTAssertEqual(sut.deleteCallCount, 1)
        XCTAssertEqual(sut.lastDeletedPostId, postId)
        XCTAssertEqual(response.data?.id, postId)
    }

    

    
    func test_getFeed_returnsPostsInCourse() async throws {
        let courseId = UUID()
        sut.stubFeedItems = [
            CourseFeedItemDto(id: UUID(), type: .post, title: "Объявление", createdDate: Date()),
            CourseFeedItemDto(id: UUID(), type: .task, title: "Задание 1", createdDate: Date())
        ]

        let response = try await sut.getFeed(courseId: courseId, skip: 0, take: 20)

        XCTAssertEqual(sut.getFeedCallCount, 1)
        XCTAssertEqual(response.data?.records?.count, 2)
        XCTAssertEqual(response.data?.totalRecords, 2)
    }

    
    func test_getFeed_emptyFeed_returnsEmptyList() async throws {
        sut.stubFeedItems = []

        let response = try await sut.getFeed(courseId: UUID(), skip: 0, take: 20)

        XCTAssertEqual(response.data?.records?.count, 0)
        XCTAssertEqual(response.data?.totalRecords, 0)
    }

    

    
    func test_taskDeadline_mustBeInFuture() {
        let pastDate = Date().addingTimeInterval(-86400)
        let futureDate = Date().addingTimeInterval(86400)

        XCTAssertFalse(PostValidator.isDeadlineValid(pastDate))
        XCTAssertTrue(PostValidator.isDeadlineValid(futureDate))
    }

    
    func test_task_withoutDeadline_isAllowed() async throws {
        let request = CreatePostRequest(
            type: .task,
            title: "Задание без дедлайна",
            text: "Выполнить когда захотите",
            deadline: nil,
            maxScore: 5,
            taskType: .optional,
            solvableAfterDeadline: nil,
            files: nil
        )

        let response = try await sut.createPost(courseId: UUID(), request: request)
        XCTAssertEqual(response.type, .success)
        XCTAssertNil(sut.lastCreatedRequest?.deadline)
    }
}
