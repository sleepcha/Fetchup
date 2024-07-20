public enum CacheMode {
    /// Use the default caching mechanism with the policy set in `URLSessionConfiguration`
    case policy
    /// Use a manual caching mode to cache every successful response (even those without cache-related headers).
    case manual
    /// Prevent caching altogether.
    case disabled
}
