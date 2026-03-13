

import XCTest
@testable import GoogleClassRoom

@MainActor
final class AnalyticsViewModelTests: XCTestCase {

    var mockCourseService: MockCourseService!
    var mockPostService: MockPostService!
    var mockSolutionService: MockSolutionService!
    var sut: AnalyticsViewModel!
    let testCourseId = UUID()

    override func setUp() {
        super.setUp()
        mockCourseService = MockCourseService()
        mockPostService = MockPostService()
        mockSolutionService = MockSolutionService()
        sut = AnalyticsViewModel(
            courseId: testCourseId,
            courseService: mockCourseService,
            postService: mockPostService,
            solutionService: mockSolutionService
        )
    }

    override func tearDown() {
        sut = nil
        mockCourseService = nil
        mockPostService = nil
        mockSolutionService = nil
        super.tearDown()
    }

    

    
    func test_loadData_buildsRowsForEachStudent() async {
        let studentId = UUID()
        let taskId = UUID()

        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: studentId, credentials: "Студент А", email: "a@a.com", role: .student)
        ], totalRecords: 1)

        mockPostService.stubFeedItems = [
            CourseFeedItemDto(id: taskId, type: .task, title: "Задание 1", createdDate: Date())
        ]

        mockSolutionService.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: studentId, credentials: "Студент А"), text: "Ответ", score: 8, status: .checked, files: nil, updatedDate: Date())
        ]

        await sut.loadData()

        XCTAssertEqual(sut.rows.count, 1)
        XCTAssertEqual(sut.tasks.count, 1)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    
    func test_loadData_excludesTeachersFromRows() async {
        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: UUID(), credentials: "Преп.", email: "t@t.com", role: .teacher),
            CourseMemberDto(id: UUID(), credentials: "Студент", email: "s@s.com", role: .student)
        ], totalRecords: 2)
        mockPostService.stubFeedItems = []

        await sut.loadData()

        XCTAssertEqual(sut.rows.count, 1)
        XCTAssertEqual(sut.rows.first?.member.role, .student)
    }

    
    func test_loadData_excludesPostTypeFromTasks() async {
        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [], totalRecords: 0)
        mockPostService.stubFeedItems = [
            CourseFeedItemDto(id: UUID(), type: .post, title: "Объявление", createdDate: Date()),
            CourseFeedItemDto(id: UUID(), type: .task, title: "Задание", createdDate: Date())
        ]

        await sut.loadData()

        XCTAssertEqual(sut.tasks.count, 1)
        XCTAssertEqual(sut.tasks.first?.title, "Задание")
    }

    
    func test_loadData_whenNoSolution_cellIsNotSubmitted() async {
        let studentId = UUID()
        let taskId = UUID()

        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: studentId, credentials: "Студент", email: "s@s.com", role: .student)
        ], totalRecords: 1)
        mockPostService.stubFeedItems = [
            CourseFeedItemDto(id: taskId, type: .task, title: "Задание", createdDate: Date())
        ]
        mockSolutionService.stubSolutions = [] 

        await sut.loadData()

        let cell = sut.rows.first?.cells[taskId]
        if case .notSubmitted = cell?.value {  } else {
            XCTFail("Expected notSubmitted, got \(String(describing: cell?.value))")
        }
    }

    
    func test_loadData_whenChecked_cellShowsScore() async {
        let studentId = UUID()
        let taskId = UUID()

        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: studentId, credentials: "Студент", email: "s@s.com", role: .student)
        ], totalRecords: 1)
        mockPostService.stubFeedItems = [
            CourseFeedItemDto(id: taskId, type: .task, title: "Задание", createdDate: Date())
        ]
        mockSolutionService.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: studentId, credentials: "Студент"), text: "", score: 9, status: .checked, files: nil, updatedDate: Date())
        ]

        await sut.loadData()

        let cell = sut.rows.first?.cells[taskId]
        if case .score(let s) = cell?.value {
            XCTAssertEqual(s, 9)
        } else {
            XCTFail("Expected score cell")
        }
    }

    
    func test_loadData_whenPending_cellIsPending() async {
        let studentId = UUID()
        let taskId = UUID()

        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: studentId, credentials: "Студент", email: "s@s.com", role: .student)
        ], totalRecords: 1)
        mockPostService.stubFeedItems = [
            CourseFeedItemDto(id: taskId, type: .task, title: "Задание", createdDate: Date())
        ]
        mockSolutionService.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: studentId, credentials: "Студент"), text: "", score: nil, status: .pending, files: nil, updatedDate: Date())
        ]

        await sut.loadData()

        let cell = sut.rows.first?.cells[taskId]
        if case .pending = cell?.value {  } else {
            XCTFail("Expected pending cell")
        }
    }

    
    func test_loadData_whenReturned_cellIsReturned() async {
        let studentId = UUID()
        let taskId = UUID()

        mockCourseService.stubMembers = CourseMembersPagedResponse(records: [
            CourseMemberDto(id: studentId, credentials: "Студент", email: "s@s.com", role: .student)
        ], totalRecords: 1)
        mockPostService.stubFeedItems = [
            CourseFeedItemDto(id: taskId, type: .task, title: "Задание", createdDate: Date())
        ]
        mockSolutionService.stubSolutions = [
            SolutionListItemDto(id: UUID(), user: UserCredentialsDto(id: studentId, credentials: "Студент"), text: "", score: nil, status: .returned, files: nil, updatedDate: Date())
        ]

        await sut.loadData()

        let cell = sut.rows.first?.cells[taskId]
        if case .returned = cell?.value {  } else {
            XCTFail("Expected returned cell")
        }
    }

    

    
    func test_analyticsRow_averageScore_withTwoCheckedCells() {
        let taskId1 = UUID()
        let taskId2 = UUID()
        let member = CourseMemberDto(id: UUID(), credentials: "Студент", email: "s@s.com", role: .student)
        let row = AnalyticsRow(member: member, cells: [
            taskId1: AnalyticsCell(value: .score(8)),
            taskId2: AnalyticsCell(value: .score(6))
        ])

        XCTAssertEqual(row.averageScore, 7.0, accuracy: 0.001)
    }

    
    func test_analyticsRow_averageScore_withNoCheckedCells_isZero() {
        let taskId = UUID()
        let member = CourseMemberDto(id: UUID(), credentials: "Студент", email: "s@s.com", role: .student)
        let row = AnalyticsRow(member: member, cells: [
            taskId: AnalyticsCell(value: .pending)
        ])

        XCTAssertEqual(row.averageScore, 0.0)
    }

    
    func test_analyticsRow_averageScore_ignoresPendingAndReturned() {
        let member = CourseMemberDto(id: UUID(), credentials: "Студент", email: "s@s.com", role: .student)
        let row = AnalyticsRow(member: member, cells: [
            UUID(): AnalyticsCell(value: .score(10)),
            UUID(): AnalyticsCell(value: .pending),
            UUID(): AnalyticsCell(value: .returned),
            UUID(): AnalyticsCell(value: .notSubmitted)
        ])

        XCTAssertEqual(row.averageScore, 10.0, accuracy: 0.001)
    }

    

    
    func test_filteredTasks_showMandatoryOnly_excludesOptionalTasks() {
        sut.tasks = [
            AnalyticsTask(id: UUID(), title: "Обяз.", createdDate: Date(), deadline: nil, taskType: .mandatory),
            AnalyticsTask(id: UUID(), title: "Доп.", createdDate: Date(), deadline: nil, taskType: .optional),
            AnalyticsTask(id: UUID(), title: "Без типа", createdDate: Date(), deadline: nil, taskType: nil)
        ]
        sut.showMandatoryOnly = true

        let result = sut.filteredTasks

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Обяз.")
    }

    
    func test_filteredTasks_withoutFilter_returnsAllTasks() {
        sut.tasks = [
            AnalyticsTask(id: UUID(), title: "А", createdDate: Date(), deadline: nil, taskType: .mandatory),
            AnalyticsTask(id: UUID(), title: "Б", createdDate: Date(), deadline: nil, taskType: .optional)
        ]
        sut.showMandatoryOnly = false

        XCTAssertEqual(sut.filteredTasks.count, 2)
    }

    
    func test_filteredTasks_withStartDate_excludesEarlierTasks() {
        let yesterday = Date().addingTimeInterval(-86400)
        let tomorrow = Date().addingTimeInterval(86400)
        let nextWeek = Date().addingTimeInterval(7 * 86400)

        sut.tasks = [
            AnalyticsTask(id: UUID(), title: "Старое", createdDate: yesterday, deadline: nil, taskType: nil),
            AnalyticsTask(id: UUID(), title: "Новое", createdDate: nextWeek, deadline: nil, taskType: nil)
        ]
        sut.startDate = tomorrow

        let result = sut.filteredTasks

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Новое")
    }

    
    func test_filteredTasks_withEndDate_excludesLaterTasks() {
        let yesterday = Date().addingTimeInterval(-86400)
        let tomorrow = Date().addingTimeInterval(86400)
        let nextWeek = Date().addingTimeInterval(7 * 86400)

        sut.tasks = [
            AnalyticsTask(id: UUID(), title: "Скоро", createdDate: tomorrow, deadline: nil, taskType: nil),
            AnalyticsTask(id: UUID(), title: "Далеко", createdDate: nextWeek, deadline: nil, taskType: nil)
        ]
        sut.endDate = Date().addingTimeInterval(2 * 86400) 

        let result = sut.filteredTasks

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.title, "Скоро")
    }

    
    func test_filteredRows_withStudentSearch_matchesByName() {
        let member1 = CourseMemberDto(id: UUID(), credentials: "Иван Иванов", email: "ivan@test.com", role: .student)
        let member2 = CourseMemberDto(id: UUID(), credentials: "Мария Петрова", email: "maria@test.com", role: .student)
        sut.rows = [
            AnalyticsRow(member: member1, cells: [:]),
            AnalyticsRow(member: member2, cells: [:])
        ]
        sut.studentSearch = "Иван"

        let result = sut.filteredRows

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.member.credentials, "Иван Иванов")
    }

    
    func test_filteredRows_withEmptySearch_returnsAllRows() {
        let member1 = CourseMemberDto(id: UUID(), credentials: "Иван", email: "i@i.com", role: .student)
        let member2 = CourseMemberDto(id: UUID(), credentials: "Мария", email: "m@m.com", role: .student)
        sut.rows = [
            AnalyticsRow(member: member1, cells: [:]),
            AnalyticsRow(member: member2, cells: [:])
        ]
        sut.studentSearch = ""

        XCTAssertEqual(sut.filteredRows.count, 2)
    }

    
    func test_filteredRows_searchIsCaseInsensitive() {
        let member = CourseMemberDto(id: UUID(), credentials: "Иван Иванов", email: "i@i.com", role: .student)
        sut.rows = [AnalyticsRow(member: member, cells: [:])]
        sut.studentSearch = "иван"

        XCTAssertEqual(sut.filteredRows.count, 1)
    }
}
