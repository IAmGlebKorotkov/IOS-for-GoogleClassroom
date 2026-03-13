

import XCTest
@testable import GoogleClassRoom

@MainActor
final class SolutionViewModelTests: XCTestCase {

    var mockService: MockSolutionService!
    var sut: SolutionViewModel!
    let testTaskId = UUID()

    override func setUp() {
        super.setUp()
        mockService = MockSolutionService()
        sut = SolutionViewModel(taskId: testTaskId, maxScore: 10, service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    

    
    func test_load_populatesSolution() async {
        mockService.stubSolutionStatus = .pending

        await sut.load()

        XCTAssertNotNil(sut.solution)
        XCTAssertEqual(sut.solution?.status, .pending)
        XCTAssertFalse(sut.isLoading)
    }

    
    func test_load_whenNotFound_solutionIsNil() async {
        mockService.submitError = NetworkError.notFound 
        
        
        await sut.load()
        XCTAssertNotNil(sut.solution) 
    }

    

    
    func test_canSubmit_whenNoSolution_isTrue() {
        XCTAssertTrue(sut.canSubmit) 
    }

    
    func test_canSubmit_whenSolutionReturned_isTrue() async {
        mockService.stubSolutionStatus = .returned
        await sut.load()
        XCTAssertTrue(sut.canSubmit)
    }

    
    func test_canSubmit_whenSolutionPending_isFalse() async {
        mockService.stubSolutionStatus = .pending
        await sut.load()
        XCTAssertFalse(sut.canSubmit)
    }

    
    func test_canSubmit_whenSolutionChecked_isFalse() async {
        mockService.stubSolutionStatus = .checked
        await sut.load()
        XCTAssertFalse(sut.canSubmit)
    }

    
    func test_canCancel_whenPending_isTrue() async {
        mockService.stubSolutionStatus = .pending
        await sut.load()
        XCTAssertTrue(sut.canCancel)
    }

    
    func test_canCancel_whenChecked_isFalse() async {
        mockService.stubSolutionStatus = .checked
        await sut.load()
        XCTAssertFalse(sut.canCancel)
    }

    
    func test_canCancel_whenReturned_isFalse() async {
        mockService.stubSolutionStatus = .returned
        await sut.load()
        XCTAssertFalse(sut.canCancel)
    }

    

    
    func test_submit_callsServiceAndReloads() async {
        await sut.submit(text: "Мой ответ на задание")

        XCTAssertEqual(mockService.submitCallCount, 1)
        XCTAssertEqual(mockService.lastSubmitRequest?.text, "Мой ответ на задание")
        XCTAssertNotNil(sut.successMessage)
    }

    
    func test_submit_withEmptyText_sendsNilText() async {
        await sut.submit(text: "")

        XCTAssertEqual(mockService.submitCallCount, 1)
        XCTAssertNil(mockService.lastSubmitRequest?.text)
    }

    
    func test_submit_whenServiceThrows_setsErrorMessage() async {
        mockService.submitError = NetworkError.serverError("Already submitted")

        await sut.submit(text: "Текст")

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }

    

    
    func test_cancelSolution_clearsSolutionAndCallsService() async {
        mockService.stubSolutionStatus = .pending
        await sut.load()
        XCTAssertNotNil(sut.solution)

        await sut.cancelSolution()

        XCTAssertNil(sut.solution)
        XCTAssertEqual(mockService.deleteCallCount, 1)
    }

    
    func test_cancelSolution_whenForbidden_setsErrorMessage() async {
        mockService.deleteError = NetworkError.forbidden

        await sut.cancelSolution()

        XCTAssertNotNil(sut.errorMessage)
    }
}

@MainActor
final class ReviewSolutionViewModelTests: XCTestCase {

    var mockService: MockSolutionService!
    var sut: ReviewSolutionViewModel!
    let testTaskId = UUID()

    override func setUp() {
        super.setUp()
        mockService = MockSolutionService()
        sut = ReviewSolutionViewModel(taskId: testTaskId, maxScore: 10, service: mockService)
    }

    override func tearDown() {
        sut = nil
        mockService = nil
        super.tearDown()
    }

    

    
    func test_loadSolutions_populatesSolutionsArray() async {
        mockService.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: UUID(), credentials: "Студент А"), text: "Ответ", score: nil, status: .pending, files: nil, updatedDate: Date()),
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: UUID(), credentials: "Студент Б"), text: "", score: 8, status: .checked, files: nil, updatedDate: Date())
        ]

        await sut.loadSolutions()

        XCTAssertEqual(sut.solutions.count, 2)
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_loadSolutions_whenEmpty_solutionsIsEmpty() async {
        mockService.stubSolutions = []

        await sut.loadSolutions()

        XCTAssertEqual(sut.solutions.count, 0)
    }

    

    
    func test_review_withValidScore_callsServiceWithCheckedStatus() async {
        let solutionId = UUID()

        await sut.review(solutionId: solutionId, score: 8, status: .checked, comment: "Хорошая работа")

        XCTAssertEqual(mockService.reviewCallCount, 1)
        XCTAssertEqual(mockService.lastReviewRequest?.score, 8)
        XCTAssertEqual(mockService.lastReviewRequest?.status, .checked)
        XCTAssertEqual(mockService.lastReviewRequest?.comment, "Хорошая работа")
        XCTAssertNotNil(sut.successMessage)
    }

    
    func test_review_withReturnedStatus_callsServiceWithoutScore() async {
        await sut.review(solutionId: UUID(), score: nil, status: .returned, comment: "Нужно доработать")

        XCTAssertEqual(mockService.lastReviewRequest?.status, .returned)
        XCTAssertNil(mockService.lastReviewRequest?.score)
    }

    
    func test_review_withScoreExceedingMax_setsErrorWithoutCallingService() async {
        await sut.review(solutionId: UUID(), score: 15, status: .checked, comment: nil)

        XCTAssertEqual(mockService.reviewCallCount, 0)
        XCTAssertNotNil(sut.errorMessage)
    }

    
    func test_review_withZeroScore_callsService() async {
        await sut.review(solutionId: UUID(), score: 0, status: .checked, comment: nil)

        XCTAssertEqual(mockService.reviewCallCount, 1)
    }

    
    func test_review_whenForbidden_setsErrorMessage() async {
        mockService.reviewError = NetworkError.forbidden

        await sut.review(solutionId: UUID(), score: 5, status: .checked, comment: nil)

        XCTAssertNotNil(sut.errorMessage)
        XCTAssertNil(sut.successMessage)
    }
}
