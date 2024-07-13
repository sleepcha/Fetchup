# Fetchup

A simple Swift REST API client with an option of manual caching using `URLCache` (handy for servers offering no caching policy implementation).

## Usage

Create your own client by conforming to `FetchupClient`:
```swift
import Fetchup

class SomeAPIClient: FetchupClient {
    static let baseURL = URL(string: "https://someserver.com/rest")!
    let configuration = FetchupClientConfiguration(baseURL: baseURL)
    let session = URLSession.shared
}
```


Define a resource describing the endpoint and `Decodable` type for JSON response:
```swift
struct FindBooks: APIResource {
    typealias Response = [Book]
    let method: HTTPMethod = .get
    let path: URL = URL(string: "/library/books")!
    let queryParameters: [String: String]
    
    init(writtenBy authorName: String) {
        queryParameters = ["author": authorName]
    }
    
    func decode(_ data: Data) -> Result<Response, Error> {
        Result { try JSONDecoder().decode(Response.self, from: data) }
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

If the response was successful you can retrieve it from cache validating its freshness:
```swift
let noOlderThanYesterday = { (creationDate: Date) in
    let yesterday = Date().addingTimeInterval(-24 * 60 * 60)
    return creationDate > yesterday
}

if case .success(let cachedBooks) = client.cached(resource, isValid: noOlderThanYesterday) {
    print(cachedBooks)
}
```
