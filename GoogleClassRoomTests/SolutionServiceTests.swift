

import XCTest
@testable import GoogleClassRoom

final class SolutionServiceTests: XCTestCase {

    var sut: MockSolutionService!

    override func setUp() {
        super.setUp()
        sut = MockSolutionService()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    

    
    func test_submitSolution_withText_returnsId() async throws {
        let request = SubmitSolutionRequest(text: "Мой ответ", files: nil)

        let response = try await sut.submitSolution(taskId: UUID(), request: request)

        XCTAssertEqual(sut.submitCallCount, 1)
        XCTAssertEqual(sut.lastSubmitRequest?.text, "Мой ответ")
        XCTAssertEqual(response.type, .success)
        XCTAssertNotNil(response.data?.id)
    }

    
    func test_submitSolution_withFiles_includesFileIds() async throws {
        let fileIds = [UUID(), UUID()]
        let request = SubmitSolutionRequest(text: nil, files: fileIds)

        _ = try await sut.submitSolution(taskId: UUID(), request: request)

        XCTAssertEqual(sut.lastSubmitRequest?.files?.count, 2)
    }

    
    func test_submitSolution_whenAlreadyPending_throwsError() async {
        sut.submitError = NetworkError.serverError("Solution already submitted")

        do {
            _ = try await sut.submitSolution(taskId: UUID(), request: SubmitSolutionRequest(text: "text", files: nil))
            XCTFail("Expected error")
        } catch {
            XCTAssertEqual(sut.submitCallCount, 1)
        }
    }

    

    
    func test_canSubmit_whenStatusIsReturned_isTrue() {
        XCTAssertTrue(SolutionValidator.canSubmit(status: .returned))
    }

    
    func test_canSubmit_whenStatusIsPending_isFalse() {
        XCTAssertFalse(SolutionValidator.canSubmit(status: .pending))
    }

    
    func test_canSubmit_whenStatusIsNil_isTrue() {
        XCTAssertTrue(SolutionValidator.canSubmit(status: nil))
    }

    
    func test_canSubmit_whenStatusIsChecked_isFalse() {
        XCTAssertFalse(SolutionValidator.canSubmit(status: .checked))
    }

    

    
    func test_deleteSolution_whenPending_succeeds() async throws {
        let taskId = UUID()
        let response = try await sut.deleteSolution(taskId: taskId)

        XCTAssertEqual(sut.deleteCallCount, 1)
        XCTAssertEqual(response.type, .success)
    }

    
    func test_canCancel_whenPending_isTrue() {
        XCTAssertTrue(SolutionValidator.canCancel(status: .pending))
    }

    
    func test_canCancel_whenChecked_isFalse() {
        XCTAssertFalse(SolutionValidator.canCancel(status: .checked))
    }

    

    
    func test_getSolution_returnsCurrentStatus() async throws {
        sut.stubSolutionStatus = .pending

        let response = try await sut.getSolution(taskId: UUID())

        XCTAssertEqual(response.data?.status, .pending)
        XCTAssertNotNil(response.data?.id)
    }

    
    func test_getSolution_whenChecked_hasScore() async throws {
        sut.stubSolutionStatus = .checked

        let response = try await sut.getSolution(taskId: UUID())

        XCTAssertEqual(response.data?.status, .checked)
    }

    

    
    func test_getSolutions_returnsAllSolutions() async throws {
        sut.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: UUID(), credentials: "Студент А"), text: "", score: nil, status: .pending, files: nil, updatedDate: Date()),
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: UUID(), credentials: "Студент Б"), text: "", score: 8, status: .checked, files: nil, updatedDate: Date())
        ]

        let response = try await sut.getSolutions(taskId: UUID(), skip: 0, take: 20, status: nil, studentId: nil)

        XCTAssertEqual(response.data?.records.count, 2)
        XCTAssertEqual(response.data?.totalRecords, 2)
    }

    
    func test_getSolutions_filteredByStatus_returnsMatchingOnly() async throws {
        sut.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: UUID(), credentials: "Студент А"), text: "", score: nil, status: .pending, files: nil, updatedDate: Date())
        ]

        let response = try await sut.getSolutions(taskId: UUID(), skip: 0, take: 20, status: .pending, studentId: nil)

        XCTAssertEqual(response.data?.records.first?.status, .pending)
    }

    
    func test_getSolutions_empty_returnsEmptyList() async throws {
        sut.stubSolutions = []

        let response = try await sut.getSolutions(taskId: UUID(), skip: 0, take: 20, status: nil, studentId: nil)

        XCTAssertEqual(response.data?.totalRecords, 0)
    }

    

    
    func test_reviewSolution_withScore_callsService() async throws {
        let request = ReviewSolutionRequest(score: 9, status: .checked, comment: "Отлично!")

        let response = try await sut.reviewSolution(solutionId: UUID(), request: request)

        XCTAssertEqual(sut.reviewCallCount, 1)
        XCTAssertEqual(sut.lastReviewRequest?.score, 9)
        XCTAssertEqual(sut.lastReviewRequest?.status, .checked)
        XCTAssertEqual(response.type, .success)
    }

    
    func test_reviewSolution_withReturnedStatus_setsReturnedStatus() async throws {
        let request = ReviewSolutionRequest(score: nil, status: .returned, comment: "Нужно доработать")

        _ = try await sut.reviewSolution(solutionId: UUID(), request: request)

        XCTAssertEqual(sut.lastReviewRequest?.status, .returned)
    }

    

    
    func test_scoreValidation_negativeScore_isFalse() {
        XCTAssertFalse(SolutionValidator.isScoreValid(-1, maxScore: 10))
    }

    
    func test_scoreValidation_scoreExceedsMaxScore_isFalse() {
        XCTAssertFalse(SolutionValidator.isScoreValid(11, maxScore: 10))
    }

    
    func test_scoreValidation_zeroScore_isValid() {
        XCTAssertTrue(SolutionValidator.isScoreValid(0, maxScore: 10))
    }

    
    func test_scoreValidation_maxScore_isValid() {
        XCTAssertTrue(SolutionValidator.isScoreValid(10, maxScore: 10))
    }
}
