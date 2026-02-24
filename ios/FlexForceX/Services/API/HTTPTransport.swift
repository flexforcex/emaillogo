import Foundation

final class HTTPTransport {
  private let config: AppConfig
  private let session: URLSession

  init(config: AppConfig, session: URLSession = .shared) {
    self.config = config
    self.session = session
  }

  func authRequest(
    path: String,
    method: String,
    query: [URLQueryItem] = [],
    body: [String: Any]? = nil,
    accessToken: String? = nil
  ) async throws -> Data {
    let url = try makeURL(path: "/auth/v1\(path)", query: query)
    return try await request(
      url: url,
      method: method,
      body: body,
      headers: [
        "apikey": config.supabaseAnonKey,
        "Authorization": accessToken.map { "Bearer \($0)" } ?? "Bearer \(config.supabaseAnonKey)"
      ]
    )
  }

  func restRequest(
    path: String,
    method: String,
    accessToken: String,
    query: [URLQueryItem] = [],
    body: [String: Any]? = nil,
    prefer: String? = nil
  ) async throws -> Data {
    let url = try makeURL(path: "/rest/v1\(path)", query: query)
    var headers: [String: String] = [
      "apikey": config.supabaseAnonKey,
      "Authorization": "Bearer \(accessToken)",
      "Accept-Profile": "public",
      "Content-Profile": "public"
    ]
    if let prefer {
      headers["Prefer"] = prefer
    }
    return try await request(url: url, method: method, body: body, headers: headers)
  }

  func functionRequest(
    name: String,
    method: String,
    accessToken: String,
    query: [URLQueryItem] = [],
    body: [String: Any]? = nil
  ) async throws -> Data {
    let url = try makeURL(path: "/functions/v1/\(name)", query: query)
    return try await request(
      url: url,
      method: method,
      body: body,
      headers: [
        "Authorization": "Bearer \(accessToken)",
        "apikey": config.supabaseAnonKey
      ]
    )
  }

  private func makeURL(path: String, query: [URLQueryItem]) throws -> URL {
    guard var components = URLComponents(url: config.supabaseURL, resolvingAgainstBaseURL: false) else {
      throw AppError.configuration("Invalid SUPABASE_URL")
    }
    components.path = path
    if !query.isEmpty {
      components.queryItems = query
    }
    guard let url = components.url else {
      throw AppError.configuration("Could not build request URL")
    }
    return url
  }

  private func request(
    url: URL,
    method: String,
    body: [String: Any]?,
    headers: [String: String]
  ) async throws -> Data {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.timeoutInterval = 20
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    headers.forEach { request.setValue($1, forHTTPHeaderField: $0) }

    if let body {
      request.httpBody = try JSONSerialization.data(withJSONObject: body)
    }

    let (data, response) = try await session.data(for: request)
    guard let http = response as? HTTPURLResponse else {
      throw AppError.network("Server response was invalid.")
    }

    guard (200..<300).contains(http.statusCode) else {
      let serverMessage = parseServerError(data: data) ?? "HTTP \(http.statusCode)"
      if http.statusCode == 401 {
        throw AppError.authentication(serverMessage)
      }
      throw AppError.network(serverMessage)
    }

    return data
  }

  private func parseServerError(data: Data) -> String? {
    guard
      let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
      return nil
    }
    return (object["error"] as? String) ?? (object["message"] as? String)
  }
}
