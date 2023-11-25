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

Finally, fetch the resource while caching the response (use `.disabled` to prevent caching):
```swift
let client = SomeAPIClient()
let resource = FindBooks(writtenBy: "Stephen King")
let tomorrow = Date.now.addingTimeInterval(24*60*60)

client.fetchDataTask(resource, cacheMode: .expires(tomorrow)) {
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
if case .success(let cachedBooks) = client.cached(resource) {
    print(cachedBooks)
}
```
