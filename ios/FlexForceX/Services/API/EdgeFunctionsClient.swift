import Foundation

final class EdgeFunctionsClient {
  private let transport: HTTPTransport

  init(transport: HTTPTransport) {
    self.transport = transport
  }

  func startTerraConnect(accessToken: String, forceReconnect: Bool = false) async throws
    -> TerraConnectResponse
  {
    let data = try await transport.functionRequest(
      name: "terra-connect",
      method: "POST",
      accessToken: accessToken,
      body: ["force_reconnect": forceReconnect]
    )
    do {
      return try JSONDecoder().decode(TerraConnectResponse.self, from: data)
    } catch {
      throw AppError.decoding("Could not parse Terra connect response.")
    }
  }

  func getTerraStatus(accessToken: String) async throws -> TerraConnection {
    let data = try await transport.functionRequest(
      name: "terra-status",
      method: "GET",
      accessToken: accessToken
    )
    do {
      return try JSONDecoder().decode(TerraConnection.self, from: data)
    } catch {
      throw AppError.decoding("Could not parse Terra status response.")
    }
  }
}
