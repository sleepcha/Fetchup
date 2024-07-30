public enum HTTPMethod {
    case get, post, put, patch, delete, head, options, trace, connect
    case custom(String)

    var rawValue: String {
        switch self {
        case .get: "GET"
        case .post: "POST"
        case .put: "PUT"
        case .patch: "PATCH"
        case .delete: "DELETE"
        case .head: "HEAD"
        case .options: "OPTIONS"
        case .trace: "TRACE"
        case .connect: "CONNECT"
        case .custom(let method): method
        }
    }
}
