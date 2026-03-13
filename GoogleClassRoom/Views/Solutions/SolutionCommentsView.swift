import SwiftUI

struct SolutionCommentsView: View {
    @StateObject private var vm: SolutionCommentsViewModel
    @State private var commentText = ""
    @FocusState private var focused: Bool

    init(solutionId: UUID) {
        _vm = StateObject(wrappedValue: SolutionCommentsViewModel(solutionId: solutionId))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(.purple)
                    .font(.caption)
                Text("Приватные комментарии")
                    .font(.headline)
                if vm.isLoading {
                    ProgressView().scaleEffect(0.7)
                }
            }
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)

            if vm.comments.isEmpty && !vm.isLoading {
                Text("Нет комментариев")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.bottom, 8)
            } else {
                ForEach(vm.comments, id: \.id) { comment in
                    PrivateCommentRowView(comment: comment) {
                        Task { await vm.deleteComment(comment.id) }
                    }
                }
            }

            if let error = vm.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal)
            }

            HStack(spacing: 8) {
                TextField("Личный комментарий…", text: $commentText, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .focused($focused)

                Button {
                    let text = commentText
                    commentText = ""
                    focused = false
                    Task { await vm.addComment(text: text) }
                } label: {
                    if vm.isSending {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundStyle(.purple)
                    }
                }
                .disabled(commentText.trimmingCharacters(in: .whitespaces).isEmpty || vm.isSending)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemPurple).opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
        .task { await vm.load() }
    }
}

private struct PrivateCommentRowView: View {
    let comment: CommentDto
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(comment.author.credentials)
                    .font(.caption.bold())
                    .foregroundStyle(.purple)
                Spacer()
                if !comment.isDeleted {
                    Button(role: .destructive) { onDelete() } label: {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            Text(comment.isDeleted ? "Комментарий удалён" : comment.text)
                .font(.subheadline)
                .foregroundStyle(comment.isDeleted ? .secondary : .primary)
                .italic(comment.isDeleted)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}
