import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
  @Published var email = ""
  @Published var password = ""
  @Published var fullName = ""
  @Published var isCreatingAccount = false
  @Published var isLoading = false
  @Published var errorMessage: String?

  private unowned let appViewModel: AppViewModel
  private let authClient: SupabaseAuthClient

  init(appViewModel: AppViewModel, authClient: SupabaseAuthClient) {
    self.appViewModel = appViewModel
    self.authClient = authClient
  }

  func submitEmailAuth() {
    errorMessage = nil
    isLoading = true

    Task {
      defer { isLoading = false }
      do {
        if isCreatingAccount {
          let session = try await authClient.signUp(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password,
            name: fullName.isEmpty ? inferredName : fullName
          )
          await appViewModel.handleSuccessfulSignIn(session: session, userName: fullNameOrInferred)
        } else {
          let session = try await authClient.signIn(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
          )
          await appViewModel.handleSuccessfulSignIn(session: session, userName: fullNameOrInferred)
        }
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Unable to sign in. Please retry."
      }
    }
  }

  func signInWithApple(idToken: String, nonce: String, suggestedName: String?) {
    errorMessage = nil
    isLoading = true

    Task {
      defer { isLoading = false }
      do {
        let session = try await authClient.signInWithApple(idToken: idToken, nonce: nonce)
        let finalName = suggestedName?.trimmingCharacters(in: .whitespacesAndNewlines)
        await appViewModel.handleSuccessfulSignIn(
          session: session,
          userName: finalName?.isEmpty == false ? finalName! : fullNameOrInferred
        )
      } catch let error as AppError {
        errorMessage = error.userSafeMessage
      } catch {
        errorMessage = "Apple sign in failed. Please retry."
      }
    }
  }

  private var inferredName: String {
    email.split(separator: "@").first.map(String.init) ?? "Flex Force User"
  }

  private var fullNameOrInferred: String {
    let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? inferredName : trimmed
  }
}
