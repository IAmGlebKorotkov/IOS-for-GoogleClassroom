import Foundation
import Combine

@MainActor
final class TeamTaskViewModel: ObservableObject {

    @Published var teams: [TeamDto] = []
    @Published var myTeam: TeamDto?
    @Published var isCaptain = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let assignmentId: UUID
    let role: UserRoleType

    private let teamService: TeamServiceProtocol
    private let teamTaskService: TeamTaskServiceProtocol

    init(
        assignmentId: UUID,
        role: UserRoleType,
        teamService: TeamServiceProtocol? = nil,
        teamTaskService: TeamTaskServiceProtocol? = nil
    ) {
        self.assignmentId = assignmentId
        self.role = role
        self.teamService = teamService ?? ServiceLocator.shared.teamService
        self.teamTaskService = teamTaskService ?? ServiceLocator.shared.teamTaskService
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if role == .teacher {
                let resp = try await teamTaskService.getTeamsForTeacher(assignmentId: assignmentId)
                teams = resp.data ?? []
            } else {
                async let allTeamsTask = teamTaskService.getTeams(assignmentId: assignmentId)
                async let myTeamTask = teamTaskService.getMyTeam(assignmentId: assignmentId)
                let allTeamsResp = try await allTeamsTask
                teams = allTeamsResp.data ?? []
                if let myTeamResp = try? await myTeamTask {
                    myTeam = myTeamResp.data
                    if let teamId = myTeam?.id {
                        isCaptain = (try? await teamService.isCaptain(teamId: teamId)) ?? false
                    }
                }
            }
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinTeam(_ teamId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.joinTeam(teamId: teamId)
            successMessage = "Вы вступили в команду"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveTeam() async {
        guard let teamId = myTeam?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.leaveTeam(teamId: teamId)
            successMessage = "Вы вышли из команды"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func transferCaptain(toUserId: UUID) async {
        guard let teamId = myTeam?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.transferCaptain(teamId: teamId, toUserId: toUserId)
            successMessage = "Капитан изменён"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startVoting() async {
        guard let teamId = myTeam?.id else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.startVoting(teamId: teamId)
            successMessage = "Голосование началось"
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func renameTeam(teamId: UUID, newName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.renameTeam(teamId: teamId, newName: newName)
            successMessage = "Команда переименована"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setFixedCaptain(teamId: UUID, userId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.setFixedCaptain(teamId: teamId, userId: userId)
            successMessage = "Капитан назначен"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func removeStudent(teamId: UUID, studentId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            _ = try await teamService.removeStudent(teamId: teamId, studentId: studentId)
            successMessage = "Студент удалён из команды"
            await load()
        } catch let e as APIError {
            errorMessage = e.localizedDescription
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
