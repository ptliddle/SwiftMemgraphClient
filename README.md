
## NOTE

### August 2024 - This is an early implementation, not all features have been implemented. Documentation is also not complete. If you find a problem please raise an issue or submit a PR 

# SwiftMemgraphClient - Swift Memgraph Client

`SwiftMemgraphClient` is a [Memgraph](https://memgraph.com/) database adapter for the Swift programming language.
It is implemented as a wrapper around [mgclient](https://github.com/memgraph/mgclient), the official Memgraph C/C++
client library.

## Installation

### Swift Package Manager
Add the following to your dependencies array in Package.swift:
```swift
.package(url: "https://github.com/ptliddle/SwiftMemgraphClient.git", .branch("master"))
```

### Prerequisites

- TBD

## Code Sample 

Below is a simple example that connects to a local memgraph instance and creates and then retrieves a simple graph.
See [Getting started with Memgraph](https://memgraph.com/docs/getting-started) on how to get this running. 

```swift
 // Connect to the local memgraph instance
let connectParams = ConnectParams(host: "localhost", lazy: false)
let connection = try Connection.connect(params: connectParams)

// Create simple graph.
try connection.executeWithoutResults(query: """
                                            CREATE (p1:Person {name: 'Alice'})-[l1:Likes]->(m:Software {name: 'Memgraph'})
                                            CREATE (p2:Person {name: 'John'})-[l2:Likes]->(m)
                                            CREATE (p3:Person {name: 'Peter'})-[l3:Likes]->(x:Software {name: 'Neo4j'});
                                            """
)

// Fetch the graph.
let columns = try connection.execute(query: "MATCH (n)-[r]->(m) RETURN n, r, m;", params: nil)
print("Columns: \(columns.joined(separator: ", "))")

for record in try connection.fetchall() {
    for value in record.values {
        switch value {
        case .node(let node):
            print("\(node)")
        case .relationship(let edge):
            print("-\(edge)-")
        default:
            print("\(value)")
        }
    }
}
```