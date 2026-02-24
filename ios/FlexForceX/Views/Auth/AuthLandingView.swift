import AuthenticationServices
import SwiftUI

struct AuthLandingView: View {
  @StateObject private var viewModel: AuthViewModel
  @State private var currentNonce: String?

  init(viewModel: AuthViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
          Text("Flex Force X")
            .font(.largeTitle.weight(.bold))
          Text("Performance and recovery insights for your daily training.")
            .foregroundStyle(.secondary)
        }

        SignInWithAppleButton(.signIn) { request in
          let nonce = AppleNonce.random()
          currentNonce = nonce
          request.requestedScopes = [.fullName, .email]
          request.nonce = AppleNonce.sha256(nonce)
        } onCompletion: { result in
          handleAppleSignIn(result)
        }
        .frame(height: 50)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        .disabled(viewModel.isLoading)

        Text("or")
          .font(.footnote.weight(.semibold))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)

        EmailAuthView(viewModel: viewModel)

        if let errorMessage = viewModel.errorMessage {
          Text(errorMessage)
            .font(.footnote)
            .foregroundStyle(Theme.ColorPalette.danger)
        }
      }
      .padding(Theme.Spacing.lg)
    }
  }

  private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
    switch result {
    case .success(let authorization):
      guard
        let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
        let nonce = currentNonce,
        let tokenData = credential.identityToken,
        let tokenString = String(data: tokenData, encoding: .utf8)
      else {
        viewModel.errorMessage = "Apple Sign In returned invalid credentials."
        return
      }

      let name = [credential.fullName?.givenName, credential.fullName?.familyName]
        .compactMap { $0 }
        .joined(separator: " ")

      viewModel.signInWithApple(
        idToken: tokenString,
        nonce: nonce,
        suggestedName: name.isEmpty ? nil : name
      )

    case .failure(let error):
      viewModel.errorMessage = error.localizedDescription
    }
  }
}
