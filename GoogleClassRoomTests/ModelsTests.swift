

import XCTest
@testable import GoogleClassRoom

final class AuthValidatorTests: XCTestCase {

    

    func test_validEmail_returnsTrue() {
        XCTAssertTrue(AuthValidator.isValidEmail("user@example.com"))
    }

    func test_validEmail_withSubdomain_returnsTrue() {
        XCTAssertTrue(AuthValidator.isValidEmail("user@mail.example.com"))
    }

    func test_emailWithoutAt_returnsFalse() {
        XCTAssertFalse(AuthValidator.isValidEmail("userexample.com"))
    }

    func test_emailWithoutDomain_returnsFalse() {
        XCTAssertFalse(AuthValidator.isValidEmail("user@"))
    }

    func test_emptyEmail_returnsFalse() {
        XCTAssertFalse(AuthValidator.isValidEmail(""))
    }

    

    func test_validPassword_6chars_returnsTrue() {
        XCTAssertTrue(AuthValidator.isValidPassword("abc123"))
    }

    func test_validPassword_20chars_returnsTrue() {
        XCTAssertTrue(AuthValidator.isValidPassword("abcdefghij1234567890"))
    }

    func test_passwordTooShort_returnsFalse() {
        XCTAssertFalse(AuthValidator.isValidPassword("abc"))
    }

    func test_passwordTooLong_returnsFalse() {
        XCTAssertFalse(AuthValidator.isValidPassword("abcdefghij12345678901"))
    }

    func test_emptyPassword_returnsFalse() {
        XCTAssertFalse(AuthValidator.isValidPassword(""))
    }
}

final class PostValidatorTests: XCTestCase {

    

    func test_nonEmptyTitle_isValid() {
        XCTAssertTrue(PostValidator.isValidTitle("Домашнее задание #1"))
    }

    func test_emptyTitle_isInvalid() {
        XCTAssertFalse(PostValidator.isValidTitle(""))
    }

    func test_whitespaceOnlyTitle_isInvalid() {
        XCTAssertFalse(PostValidator.isValidTitle("   "))
    }

    

    func test_positiveScore_isValid() {
        XCTAssertTrue(PostValidator.isValidMaxScore(5))
        XCTAssertTrue(PostValidator.isValidMaxScore(100))
    }

    func test_zeroScore_isInvalid() {
        XCTAssertFalse(PostValidator.isValidMaxScore(0))
    }

    func test_negativeScore_isInvalid() {
        XCTAssertFalse(PostValidator.isValidMaxScore(-1))
    }

    

    func test_futureDeadline_isValid() {
        let future = Date().addingTimeInterval(3600) 
        XCTAssertTrue(PostValidator.isDeadlineValid(future))
    }

    func test_pastDeadline_isInvalid() {
        let past = Date().addingTimeInterval(-3600) 
        XCTAssertFalse(PostValidator.isDeadlineValid(past))
    }
}

final class SolutionValidatorTests: XCTestCase {

    

    func test_scoreWithinMaxScore_isValid() {
        XCTAssertTrue(SolutionValidator.isScoreValid(5, maxScore: 10))
        XCTAssertTrue(SolutionValidator.isScoreValid(0, maxScore: 10))
        XCTAssertTrue(SolutionValidator.isScoreValid(10, maxScore: 10))
    }

    func test_scoreExceedingMaxScore_isInvalid() {
        XCTAssertFalse(SolutionValidator.isScoreValid(11, maxScore: 10))
    }

    func test_negativeScore_isInvalid() {
        XCTAssertFalse(SolutionValidator.isScoreValid(-1, maxScore: 10))
    }

    

    func test_canSubmit_whenNoSolutionExists() {
        XCTAssertTrue(SolutionValidator.canSubmit(status: nil))
    }

    func test_canSubmit_whenSolutionReturned() {
        XCTAssertTrue(SolutionValidator.canSubmit(status: .returned))
    }

    func test_cannotSubmit_whenSolutionPending() {
        XCTAssertFalse(SolutionValidator.canSubmit(status: .pending))
    }

    func test_cannotSubmit_whenSolutionChecked() {
        XCTAssertFalse(SolutionValidator.canSubmit(status: .checked))
    }

    

    func test_canCancel_whenSolutionPending() {
        XCTAssertTrue(SolutionValidator.canCancel(status: .pending))
    }

    func test_cannotCancel_whenSolutionChecked() {
        XCTAssertFalse(SolutionValidator.canCancel(status: .checked))
    }

    func test_cannotCancel_whenSolutionReturned() {
        XCTAssertFalse(SolutionValidator.canCancel(status: .returned))
    }
}

final class CommentValidatorTests: XCTestCase {

    func test_nonEmptyText_isValid() {
        XCTAssertTrue(CommentValidator.isValidText("Отличная работа!"))
    }

    func test_emptyText_isInvalid() {
        XCTAssertFalse(CommentValidator.isValidText(""))
    }

    func test_whitespaceOnlyText_isInvalid() {
        XCTAssertFalse(CommentValidator.isValidText("   "))
    }
}
