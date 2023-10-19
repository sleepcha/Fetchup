import Foundation

public enum CacheMode {
    /// Use the default caching mechanism with the policy set in `URLSessionConfiguration`
    case policy
    /// Use a manual caching mode where all successful responses are cached (even those without cache-related headers). `Date` property specifies the expiration date.
    case expires(Date)
    /// Prevent caching altogether.
    case disabled
}
