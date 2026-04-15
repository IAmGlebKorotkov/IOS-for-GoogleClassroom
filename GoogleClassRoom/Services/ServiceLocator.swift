
import Foundation

final class ServiceLocator {
    static let shared = ServiceLocator()
    private init() {}

    lazy var authService: AuthServiceProtocol = AuthService()
    lazy var courseService: CourseServiceProtocol = CourseService()
    lazy var postService: PostServiceProtocol = PostService()
    lazy var solutionService: SolutionServiceProtocol = SolutionService()
    lazy var commentService: CommentServiceProtocol = CommentService()
    lazy var userService: UserServiceProtocol = UserService()
    lazy var fileService: FileServiceProtocol = FileService()
    lazy var teamService: TeamServiceProtocol = TeamService()
    lazy var teamTaskService: TeamTaskServiceProtocol = TeamTaskService()
    lazy var gradeDistributionService: GradeDistributionServiceProtocol = GradeDistributionService()
}
