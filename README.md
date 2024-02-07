# Fetchup

A simple Swift REST API client with an option of aggressive manual caching using `URLCache`.

## Usage

Create your own client by conforming to `FetchupClientProtocol`:
```swift
class SomeAPIClient: FetchupClientProtocol {
    let configuration = FetchupClientConfiguration(baseURL: "https://someserver.com/rest")
    let session = URLSession.shared
}
```


Define a resource describing the endpoint and `Decodable` type for JSON response:
```swift
struct FindBooks: APIResource {
    typealias Response = [Book]
    let method: HTTPMethod = .get
    let endpoint: URL = "/library/books"
    let queryParameters: [String: String]
    
    init(writtenBy authorName: String) {
        queryParameters = ["author": authorName]
    }
}

struct Book: Decodable {
    let name: String
    let authorName: String
    let date: Date
}
```

Finally, fetch the resource while caching the response (use `CacheMode.disabled` to prevent all caching):
```swift
let client = SomeAPIClient()
let resource = FindBooks(writtenBy: "Stephen King")

client.fetchDataTask(resource, cacheMode: .manual) {
    switch $0 {
    case .success(let books):
        print(books)
    case .failure(let error):
        print(error.localizedDescription)
    }
}.resume()
```

If the response was successful and has not yet expired you can retrieve it from cache:
```swift
let cachedVersion = client.cached(resource) { creationDate in
    let expirationDate = creationDate.addingTimeInterval(24 * 60 * 60)
    return Date.now < expirationDate
}

if case let .success(cachedBooks) = cachedVersion {
    print(cachedBooks)
}
```
