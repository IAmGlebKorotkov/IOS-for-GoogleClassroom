
import Foundation
import Combine

struct AnalyticsCell {
    enum Value {
        case score(Int)
        case returned
        case pending
        case notSubmitted
    }
    let value: Value
}

struct AnalyticsRow {
    let member: CourseMemberDto
    let cells: [UUID: AnalyticsCell] 
    var averageScore: Double {
        let scores = cells.values.compactMap {
            if case .score(let s) = $0.value { return s } else { return nil }
        }
        guard !scores.isEmpty else { return 0 }
        return Double(scores.reduce(0, +)) / Double(scores.count)
    }
}

struct AnalyticsTask {
    let id: UUID
    let title: String
    let createdDate: Date
    let deadline: Date?
    let taskType: TaskType?
}

@MainActor
final class AnalyticsViewModel: ObservableObject {

    @Published var tasks: [AnalyticsTask] = []
    @Published var rows: [AnalyticsRow] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    
    @Published var studentSearch = ""
    @Published var showMandatoryOnly = false
    @Published var startDate: Date? = nil
    @Published var endDate: Date? = nil

    let courseId: UUID

    private let courseService: CourseServiceProtocol
    private let postService: PostServiceProtocol
    private let solutionService: SolutionServiceProtocol

    init(courseId: UUID,
         courseService: CourseServiceProtocol? = nil,
         postService: PostServiceProtocol? = nil,
         solutionService: SolutionServiceProtocol? = nil) {
        self.courseId = courseId
        self.courseService = courseService ?? ServiceLocator.shared.courseService
        self.postService = postService ?? ServiceLocator.shared.postService
        self.solutionService = solutionService ?? ServiceLocator.shared.solutionService
    }

    

    func loadData() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            
            let membersResp = try await courseService.getMembers(courseId: courseId, skip: 0, take: 200, query: nil)
            let students = (membersResp.data?.records ?? []).filter { $0.role == .student }

            
            let feedResp = try await postService.getFeed(courseId: courseId, skip: 0, take: 200)
            let taskItems = (feedResp.data?.records ?? []).filter { $0.type == .task }

            
            var analyticsTasks: [AnalyticsTask] = []
            for item in taskItems {
                if let detail = try? await postService.getPost(id: item.id) {
                    analyticsTasks.append(AnalyticsTask(
                        id: item.id,
                        title: item.title,
                        createdDate: item.createdDate,
                        deadline: detail.data?.deadline,
                        taskType: detail.data?.taskType
                    ))
                } else {
                    analyticsTasks.append(AnalyticsTask(
                        id: item.id,
                        title: item.title,
                        createdDate: item.createdDate,
                        deadline: nil,
                        taskType: nil
                    ))
                }
            }
            tasks = analyticsTasks

            
            var solutionsByTask: [UUID: [SolutionListItemDto]] = [:]
            for task in analyticsTasks {
                let solResp = try await solutionService.getSolutions(taskId: task.id, skip: 0, take: 200, status: nil, studentId: nil)
                solutionsByTask[task.id] = solResp.data?.records ?? []
            }

            
            rows = students.map { student in
                var cells: [UUID: AnalyticsCell] = [:]
                for task in analyticsTasks {
                    let solutions = solutionsByTask[task.id] ?? []
                    if let sol = solutions.first(where: { $0.user.id == student.id }) {
                        let cell: AnalyticsCell
                        switch sol.status {
                        case .checked:
                            cell = AnalyticsCell(value: .score(sol.score ?? 0))
                        case .returned:
                            cell = AnalyticsCell(value: .returned)
                        case .pending:
                            cell = AnalyticsCell(value: .pending)
                        }
                        cells[task.id] = cell
                    } else {
                        cells[task.id] = AnalyticsCell(value: .notSubmitted)
                    }
                }
                return AnalyticsRow(member: student, cells: cells)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    

    var filteredTasks: [AnalyticsTask] {
        tasks.filter { task in
            if showMandatoryOnly && task.taskType != .mandatory { return false }
            if let start = startDate {
                let date = task.deadline ?? task.createdDate
                if date < start { return false }
            }
            if let end = endDate {
                let date = task.deadline ?? task.createdDate
                if date > end { return false }
            }
            return true
        }
    }

    var filteredRows: [AnalyticsRow] {
        rows.filter { row in
            if studentSearch.isEmpty { return true }
            return row.member.credentials.localizedCaseInsensitiveContains(studentSearch)
        }
    }
}
