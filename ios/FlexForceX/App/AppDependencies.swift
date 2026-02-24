import Foundation

final class AppDependencies {
  let authClient: SupabaseAuthClient
  let databaseClient: SupabaseDatabaseClient
  let edgeFunctionsClient: EdgeFunctionsClient
  let sessionStore: SessionStore
  let consentStore: ConsentStore
  let issueReporter: IssueReporter

  init(config: AppConfig) {
    let transport = HTTPTransport(config: config)
    self.authClient = SupabaseAuthClient(transport: transport)
    self.databaseClient = SupabaseDatabaseClient(transport: transport)
    self.edgeFunctionsClient = EdgeFunctionsClient(transport: transport)
    self.sessionStore = SessionStore(keychain: KeychainStore(service: "com.flexforcex.app.auth"))
    self.consentStore = ConsentStore()
    self.issueReporter = IssueReporter(databaseClient: databaseClient)
  }
}
