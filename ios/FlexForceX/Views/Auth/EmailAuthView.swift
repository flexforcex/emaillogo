import SwiftUI

struct EmailAuthView: View {
  @ObservedObject var viewModel: AuthViewModel

  var body: some View {
    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
      Toggle(isOn: $viewModel.isCreatingAccount) {
        Text(viewModel.isCreatingAccount ? "Create account" : "I have an account")
          .font(.subheadline.weight(.semibold))
      }

      if viewModel.isCreatingAccount {
        TextField("Full name", text: $viewModel.fullName)
          .textInputAutocapitalization(.words)
          .autocorrectionDisabled()
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
      }

      TextField("Email", text: $viewModel.email)
        .textInputAutocapitalization(.never)
        .keyboardType(.emailAddress)
        .autocorrectionDisabled()
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))

      SecureField("Password", text: $viewModel.password)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))

      Button {
        viewModel.submitEmailAuth()
      } label: {
        if viewModel.isLoading {
          ProgressView()
            .frame(maxWidth: .infinity)
        } else {
          Text(viewModel.isCreatingAccount ? "Create account" : "Sign in")
            .frame(maxWidth: .infinity)
        }
      }
      .buttonStyle(.borderedProminent)
      .disabled(viewModel.email.isEmpty || viewModel.password.count < 8 || viewModel.isLoading)
    }
  }
}
