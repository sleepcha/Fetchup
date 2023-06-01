# Fetchup

A simple Swift REST API client with an option of aggressive manual caching using `URLCache`.

## Usage

Create your own client by conforming to `FetchupClientProtocol`:
```swift
class SomeAPIClient: FetchupClientProtocol {
    let configuration = FetchupClientConfiguration(
        baseURL: "https://someserver.com/rest",
        manualCaching: true
    )
    let session = URLSession.shared
}
```


Define a resource containing the endpoint and `Decodable` types for JSON response:
```swift
struct FindBooks: APIResource {
    typealias Response = BooksResponse
    let method: HTTPMethod = .get
    let endpoint: URL = "/library/books"
    let queryParameters: [String: String]
    
    init(writtenBy authorName: String) {
        queryParameters = ["author": authorName]
    }
}

struct BooksResponse: Decodable {
    let books: [Book]
}

struct Book: Decodable {
    let name: String
    let authorName: String
    let date: Date
}
```

Finally, fetch the resource and cache the response:
```swift
let client = SomeAPIClient()
let resource = FindBooks(writtenBy: "Stephen King")
let tomorrow = Date.now.addingTimeInterval(24*60*60)

client.fetchDataTask(resource, expiresOn: tomorrow) {
    switch $0 {
    case .success(let response):
        print(response.books)
    case .failure(let error):
        print(error.localizedDescription)
    }
}.resume()
```

If the response was successful and has not yet expired you can retrieve it from cache:
```swift
if let cachedBooks = client.cached(resource).books {
    print(books)
}
```
