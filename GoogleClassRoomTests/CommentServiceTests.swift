

import XCTest
@testable import GoogleClassRoom

final class CommentServiceTests: XCTestCase {

    var sut: MockCommentService!

    override func setUp() {
        super.setUp()
        sut = MockCommentService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    

    
    func test_addCommentToPost_withText_returnsId() async throws {
        let request = AddCommentRequest(text: "Отличный материал!")

        let response = try await sut.addCommentToPost(postId: UUID(), request: request)

        XCTAssertEqual(sut.addPostCommentCallCount, 1)
        XCTAssertEqual(sut.lastAddedPostComment?.text, "Отличный материал!")
        XCTAssertEqual(response.type, .success)
        XCTAssertNotNil(response.data?.id)
    }

    
    func test_addCommentToPost_emptyText_failsValidation() {
        XCTAssertFalse(CommentValidator.isValidText(""))
    }

    
    func test_addCommentToPost_whitespaceText_failsValidation() {
        XCTAssertFalse(CommentValidator.isValidText("   "))
    }

    

    
    func test_getPostComments_returnsAllComments() async throws {
        let author = CommentAuthorDto(id: UUID(), credentials: "Иван")
        sut.stubComments = [
            CommentDto(id: UUID(), text: "Первый", isDeleted: false, author: author, nestedCount: 0),
            CommentDto(id: UUID(), text: "Второй", isDeleted: false, author: author, nestedCount: 0)
        ]

        let response = try await sut.getPostComments(postId: UUID(), skip: 0, take: 20)

        XCTAssertEqual(sut.getPostCommentsCallCount, 1)
        XCTAssertEqual(response.data?.records.count, 2)
        XCTAssertEqual(response.data?.totalRecords, 2)
    }

    
    func test_getPostComments_emptyList_returnsZero() async throws {
        sut.stubComments = []

        let response = try await sut.getPostComments(postId: UUID(), skip: 0, take: 20)

        XCTAssertEqual(response.data?.records.count, 0)
        XCTAssertEqual(response.data?.totalRecords, 0)
    }

    

    
    func test_addCommentToSolution_withText_returnsId() async throws {
        let request = AddCommentRequest(text: "Обратите внимание на оформление")

        let response = try await sut.addCommentToSolution(solutionId: UUID(), request: request)

        XCTAssertEqual(sut.addSolutionCommentCallCount, 1)
        XCTAssertEqual(sut.lastAddedSolutionComment?.text, "Обратите внимание на оформление")
        XCTAssertEqual(response.type, .success)
    }

    

    
    func test_getSolutionComments_returnsComments() async throws {
        let author = CommentAuthorDto(id: UUID(), credentials: "Преподаватель")
        sut.stubComments = [
            CommentDto(id: UUID(), text: "Хорошая работа", isDeleted: false, author: author, nestedCount: 0)
        ]

        let response = try await sut.getSolutionComments(solutionId: UUID(), skip: 0, take: 20)

        XCTAssertEqual(sut.getSolutionCommentsCallCount, 1)
        XCTAssertEqual(response.data?.records.count, 1)
    }

    

    
    func test_replyToComment_withText_returnsId() async throws {
        let commentId = UUID()
        let request = AddCommentRequest(text: "Согласен!")

        let response = try await sut.replyToComment(commentId: commentId, request: request)

        XCTAssertEqual(sut.replyCallCount, 1)
        XCTAssertEqual(sut.lastRepliedToCommentId, commentId)
        XCTAssertEqual(response.type, .success)
    }

    
    func test_replyToComment_emptyText_failsValidation() {
        XCTAssertFalse(CommentValidator.isValidText(""))
    }

    
    func test_getReplies_returnsNestedComments() async throws {
        let author = CommentAuthorDto(id: UUID(), credentials: "Студент")
        sut.stubReplies = [
            CommentDto(id: UUID(), text: "Ответ", isDeleted: false, author: author, nestedCount: 0)
        ]

        let response = try await sut.getReplies(commentId: UUID(), skip: 0, take: 20)

        XCTAssertEqual(sut.getRepliesCallCount, 1)
        XCTAssertEqual(response.data?.records.count, 1)
    }

    

    
    func test_editComment_withNewText_callsService() async throws {
        let commentId = UUID()
        let request = EditCommentRequest(text: "Исправленный текст")

        let response = try await sut.editComment(commentId: commentId, request: request)

        XCTAssertEqual(sut.editCallCount, 1)
        XCTAssertEqual(sut.lastEditedComment?.text, "Исправленный текст")
        XCTAssertEqual(response.type, .success)
    }

    
    func test_editComment_emptyText_failsValidation() {
        XCTAssertFalse(CommentValidator.isValidText(""))
    }

    

    

    
    func test_commentValidator_validText_isTrue() {
        XCTAssertTrue(CommentValidator.isValidText("Хороший вопрос!"))
    }

    
    func test_commentValidator_tooLongText_isFalse() {
        let longText = String(repeating: "а", count: 2001)
        XCTAssertFalse(CommentValidator.isValidText(longText))
    }

    
    func test_commentValidator_maxLengthText_isTrue() {
        let maxText = String(repeating: "а", count: 2000)
        XCTAssertTrue(CommentValidator.isValidText(maxText))
    }
}
