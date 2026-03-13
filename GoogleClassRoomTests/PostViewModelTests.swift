

import XCTest
@testable import GoogleClassRoom

@MainActor
final class PostDetailViewModelTests: XCTestCase {

    var mockPostService: MockPostService!
    var mockCommentService: MockCommentService!
    var sut: PostDetailViewModel!
    let testPostId = UUID()
    let testCourseId = UUID()

    override func setUp() {
        super.setUp()
        mockPostService = MockPostService()
        mockCommentService = MockCommentService()
        sut = PostDetailViewModel(
            postId: testPostId,
            courseId: testCourseId,
            postService: mockPostService,
            commentService: mockCommentService
        )
    }

    override func tearDown() {
        sut = nil
        mockPostService = nil
        mockCommentService = nil
        super.tearDown()
    }

    

    
    func test_load_populatesPostAndComments() async {
        let author = CommentAuthorDto(id: UUID(), credentials: "Студент")
        mockCommentService.stubComments = [
            CommentDto(id: UUID(), text: "Первый", isDeleted: false, author: author, nestedCount: 0)
        ]

        await sut.load()

        XCTAssertNotNil(sut.post)
        XCTAssertEqual(sut.comments.count, 1)
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_load_withNoComments_commentsIsEmpty() async {
        mockCommentService.stubComments = []

        await sut.load()

        XCTAssertNotNil(sut.post)
        XCTAssertEqual(sut.comments.count, 0)
    }

    
    func test_load_completesAndResetsIsLoading() async {
        await sut.load()
        XCTAssertFalse(sut.isLoading)
    }

    

    
    func test_addComment_withValidText_callsServiceAndReloadsComments() async {
        await sut.addComment(text: "Отличный материал!")

        XCTAssertEqual(mockCommentService.addPostCommentCallCount, 1)
        XCTAssertEqual(mockCommentService.lastAddedPostComment?.text, "Отличный материал!")
    }

    
    func test_addComment_withEmptyText_setsValidationErrorWithoutCallingService() async {
        await sut.addComment(text: "")

        XCTAssertEqual(mockCommentService.addPostCommentCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_addComment_withWhitespaceOnly_setsValidationError() async {
        await sut.addComment(text: "   ")

        XCTAssertEqual(mockCommentService.addPostCommentCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_addComment_tooLongText_setsValidationError() async {
        let longText = String(repeating: "а", count: 2001)

        await sut.addComment(text: longText)

        XCTAssertEqual(mockCommentService.addPostCommentCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    

    
    func test_deleteComment_removesCommentFromLocalArray() async {
        let commentId = UUID()
        let author = CommentAuthorDto(id: UUID(), credentials: "Автор")
        mockCommentService.stubComments = [
            CommentDto(id: commentId, text: "Текст", isDeleted: false, author: author, nestedCount: 0)
        ]
        await sut.load()
        XCTAssertEqual(sut.comments.count, 1)

        await sut.deleteComment(commentId)

        XCTAssertEqual(sut.comments.count, 0)
        XCTAssertEqual(mockCommentService.deleteCallCount, 1)
    }

    
    func test_deleteComment_whenForbidden_setsErrorMessage() async {
        mockCommentService.deleteCommentError = NetworkError.forbidden

        await sut.deleteComment(UUID())

        XCTAssertNotNil(sut.errorMessage)
    }
}

@MainActor
final class CreatePostViewModelTests: XCTestCase {

    var mockPostService: MockPostService!
    var sut: CreatePostViewModel!
    let testCourseId = UUID()

    override func setUp() {
        super.setUp()
        mockPostService = MockPostService()
        sut = CreatePostViewModel(courseId: testCourseId, service: mockPostService)
    }

    override func tearDown() {
        sut = nil
        mockPostService = nil
        super.tearDown()
    }

    

    
    func test_createPost_withValidTitle_callsServiceAndReturnsTrue() async {
        let success = await sut.createPost(
            type: .post,
            title: "Важное объявление",
            text: "Текст",
            deadline: nil,
            maxScore: 5,
            taskType: .mandatory,
            solvableAfterDeadline: false
        )

        XCTAssertTrue(success)
        XCTAssertEqual(mockPostService.createCallCount, 1)
        XCTAssertEqual(mockPostService.lastCreatedRequest?.type, .post)
    }

    
    func test_createPost_withEmptyTitle_setsErrorAndReturnsFalse() async {
        let success = await sut.createPost(
            type: .post,
            title: "   ",
            text: "",
            deadline: nil,
            maxScore: 5,
            taskType: .mandatory,
            solvableAfterDeadline: false
        )

        XCTAssertFalse(success)
        XCTAssertEqual(mockPostService.createCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    

    
    func test_createTask_withValidData_callsServiceWithTaskType() async {
        let deadline = Date().addingTimeInterval(86400)
        let success = await sut.createPost(
            type: .task,
            title: "Лабораторная #1",
            text: "Условие задания",
            deadline: deadline,
            maxScore: 10,
            taskType: .mandatory,
            solvableAfterDeadline: false
        )

        XCTAssertTrue(success)
        XCTAssertEqual(mockPostService.lastCreatedRequest?.type, .task)
        XCTAssertEqual(mockPostService.lastCreatedRequest?.maxScore, 10)
        XCTAssertEqual(mockPostService.lastCreatedRequest?.taskType, .mandatory)
    }

    
    func test_createTask_withZeroMaxScore_setsErrorAndReturnsFalse() async {
        let success = await sut.createPost(
            type: .task,
            title: "Задание",
            text: "",
            deadline: nil,
            maxScore: 0,
            taskType: .mandatory,
            solvableAfterDeadline: false
        )

        XCTAssertFalse(success)
        XCTAssertEqual(mockPostService.createCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_createTask_withPastDeadline_setsErrorAndReturnsFalse() async {
        let pastDeadline = Date().addingTimeInterval(-86400)

        let success = await sut.createPost(
            type: .task,
            title: "Задание",
            text: "",
            deadline: pastDeadline,
            maxScore: 5,
            taskType: .mandatory,
            solvableAfterDeadline: false
        )

        XCTAssertFalse(success)
        XCTAssertEqual(mockPostService.createCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_createTask_withoutDeadline_createsSuccessfully() async {
        let success = await sut.createPost(
            type: .task,
            title: "Доп. задание",
            text: "",
            deadline: nil,
            maxScore: 5,
            taskType: .optional,
            solvableAfterDeadline: false
        )

        XCTAssertTrue(success)
        XCTAssertNil(mockPostService.lastCreatedRequest?.deadline)
    }

    
    func test_createTask_defaultMaxScore_isAccepted() async {
        let success = await sut.createPost(
            type: .task,
            title: "Задание",
            text: "",
            deadline: nil,
            maxScore: 5,
            taskType: .mandatory,
            solvableAfterDeadline: false
        )

        XCTAssertTrue(success)
        XCTAssertEqual(mockPostService.lastCreatedRequest?.maxScore, 5)
    }
}
