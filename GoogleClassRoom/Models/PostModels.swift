import Foundation

enum PostType: String, Codable, Hashable {
    case post
    case task
    case teamTask = "teaM_TASK"
}

enum CaptainSelectionMode: String, Codable {
    case firstMember
    case teacherFixed
    case votingAndLottery
}

enum TaskType: String, Codable {
    case mandatory
    case optional
}

enum CriterionTypeDto: String, Codable, Hashable {
    case weighted
    case quality
    case bonusPenalty
    case blocking
}

enum CriterionDirection: String, Codable, Hashable {
    case add
    case subtract
}

struct FileDto: Codable, Equatable {
    let id: String?
    let name: String?
}

struct CriterionDefinitionDto: Codable, Hashable {
    var id: UUID? = nil
    var type: CriterionTypeDto
    var title: String? = nil
    var orderIndex: Int
    var maxScore: Double? = nil
    var weight: Double? = nil
    var threshold: Double? = nil
    var score: Double? = nil
    var direction: CriterionDirection? = nil
    var maxAllowedScore: Double? = nil
}

struct CriterionDto: Codable, Hashable, Identifiable {
    let id: UUID
    let type: CriterionTypeDto
    let title: String?
    let orderIndex: Int
    let maxScore: Double?
    let weight: Double?
    let threshold: Double?
    let score: Double?
    let direction: CriterionDirection?
    let maxAllowedScore: Double?
}

struct WeightedValueDto: Codable, Hashable {
    let criterionId: UUID
    let score: Double
}

struct ToggledValueDto: Codable, Hashable {
    let criterionId: UUID
    let enabled: Bool
}

struct EvaluationDto: Codable, Hashable {
    var weightedValues: [WeightedValueDto]?
    var toggledValues: [ToggledValueDto]?

    var isEmpty: Bool {
        (weightedValues?.isEmpty ?? true) && (toggledValues?.isEmpty ?? true)
    }
}

struct GradePreviewRequestDto: Encodable {
    let evaluation: EvaluationDto
}

struct GradeBreakdownDto: Codable, Hashable {
    let baseTeacherScore: Double
    let baseStudentScore: Double?
    let baseScore: Double
    let afterQualityCoefficient: Double
    let latePenalty: Double
    let afterLatePenalty: Double
    let afterBlocking: Double
    let finalScore: Double
    let expiredDays: Int
    let thresholdApplied: Bool
    let thresholdReason: String?
}

enum CriterionCalculator {
    static func makeEvaluation(
        criteria: [CriterionDto],
        weightedScores: [UUID: Double],
        toggledCriteria: Set<UUID>
    ) -> EvaluationDto {
        let weightedValues = criteria
            .filter { $0.type == .weighted }
            .map { WeightedValueDto(criterionId: $0.id, score: weightedScores[$0.id] ?? 0) }

        let toggledValues = criteria
            .filter { $0.type != .weighted }
            .map { ToggledValueDto(criterionId: $0.id, enabled: toggledCriteria.contains($0.id)) }

        return EvaluationDto(
            weightedValues: weightedValues.isEmpty ? nil : weightedValues,
            toggledValues: toggledValues.isEmpty ? nil : toggledValues
        )
    }

    static func estimatedScore(criteria: [CriterionDto], evaluation: EvaluationDto) -> Double {
        let weightedById = Dictionary(uniqueKeysWithValues: (evaluation.weightedValues ?? []).map { ($0.criterionId, $0.score) })
        let toggledById = Dictionary(uniqueKeysWithValues: (evaluation.toggledValues ?? []).map { ($0.criterionId, $0.enabled) })

        var score = 0.0
        var maxWeighted = 0.0

        for criterion in criteria where criterion.type == .weighted {
            let awarded = min(max(weightedById[criterion.id] ?? 0, 0), criterion.maxScore ?? .greatestFiniteMagnitude)
            let weight = criterion.weight ?? 1
            score += awarded * weight
            maxWeighted += (criterion.maxScore ?? 0) * weight
        }

        for criterion in criteria where criterion.type == .bonusPenalty && (toggledById[criterion.id] ?? false) {
            let delta = criterion.score ?? 0
            switch criterion.direction {
            case .add:
                score += delta
            case .subtract:
                score -= delta
            case .none:
                break
            }
        }

        for criterion in criteria where criterion.type == .quality && (toggledById[criterion.id] ?? false) {
            guard maxWeighted > 0 else { continue }
            let scoreRatio = score / maxWeighted
            let threshold = normalizedThreshold(criterion.threshold ?? 0)
            let delta = criterion.score ?? 0
            switch criterion.direction {
            case .add where scoreRatio > threshold:
                score += delta
            case .subtract where scoreRatio < threshold:
                score -= delta
            default:
                break
            }
        }

        for criterion in criteria where criterion.type == .blocking && (toggledById[criterion.id] ?? false) {
            if let maxAllowed = criterion.maxAllowedScore {
                score = min(score, maxAllowed)
            }
        }

        return max(0, score)
    }

    static func maxScore(criteria: [CriterionDto]) -> Double {
        let weighted = criteria
            .filter { $0.type == .weighted }
            .reduce(0) { $0 + (($1.maxScore ?? 0) * ($1.weight ?? 1)) }
        let bonuses = criteria
            .filter { $0.type == .bonusPenalty && $0.direction == .add }
            .reduce(0) { $0 + ($1.score ?? 0) }
        let qualityBonuses = criteria
            .filter { $0.type == .quality && $0.direction == .add }
            .reduce(0) { $0 + ($1.score ?? 0) }
        return weighted + bonuses + qualityBonuses
    }

    private static func normalizedThreshold(_ value: Double) -> Double {
        value > 1 ? value / 100 : value
    }
}

struct CreatePostRequest: Codable {
    let type: PostType
    let title: String
    let text: String?
    let deadline: Date?
    let maxScore: Int?
    let taskType: TaskType?
    let solvableAfterDeadline: Bool?
    let files: [UUID]?
    // Team task fields
    var minTeamSize: Int? = nil
    var maxTeamSize: Int? = nil
    var captainMode: CaptainSelectionMode? = nil
    var votingDurationHours: Int? = nil
    var predefinedTeamsCount: Int? = nil
    var allowJoinTeam: Bool? = nil
    var allowLeaveTeam: Bool? = nil
    var allowStudentTransferCaptain: Bool? = nil
    var failThreshold: Double? = nil
    var successThreshold: Double? = nil
    var studentScoreWeight: Double? = nil
    var penaltyPerDay: Double? = nil
    var maxDays: Int? = nil
    var criteria: [CriterionDefinitionDto]? = nil
}

struct PostDetailsDto: Codable {
    let id: UUID?
    let type: PostType
    let title: String
    let text: String
    let deadline: Date?
    let maxScore: Int?
    let taskType: TaskType?
    let solvableAfterDeadline: Bool?
    let files: [FileDto]?
    let userSolution: UserSolutionDto?
    var minTeamSize: Int? = nil
    var maxTeamSize: Int? = nil
    var captainMode: CaptainSelectionMode? = nil
    var votingDurationHours: Int? = nil
    var predefinedTeamsCount: Int? = nil
    var allowJoinTeam: Bool? = nil
    var allowLeaveTeam: Bool? = nil
    var allowStudentTransferCaptain: Bool? = nil
    var failThreshold: Double? = nil
    var successThreshold: Double? = nil
    var studentScoreWeight: Double? = nil
    var penaltyPerDay: Double? = nil
    var maxDays: Int? = nil
    var criteria: [CriterionDto]? = nil
}

struct UserSolutionDto: Codable {
    let id: UUID?
    let text: String
    let score: Int
    let status: SolutionStatus?
}

struct CourseFeedItemDto: Codable, Hashable {
    let id: UUID
    let type: PostType
    let title: String
    let createdDate: Date
}

struct FeedResponseDto: Codable {
    let records: [CourseFeedItemDto]?
    let totalRecords: Int
}

struct PostValidator {
    static func isValidTitle(_ title: String) -> Bool {
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func isValidText(_ text: String) -> Bool {
        return !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func isValidMaxScore(_ score: Int) -> Bool {
        return score > 0
    }

    static func isDeadlineValid(_ deadline: Date) -> Bool {
        return deadline > Date()
    }
}
