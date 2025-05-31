# SwiftDataDemo notes:

- Run the XCTest SwiftDataDemoTests.swift to get a demo 
- All demos output to console.log
- There are minimum OS requirements for SwiftData to work:

```
	platforms: [
        .macOS(.v14),     // macOS 14.0 - minimum for SwiftData
        .iOS(.v17),       // iOS 17 - minimum for SwiftData
        .tvOS(.v17),      // tvOS 17 - minimum for SwiftData
        .watchOS(.v10),   // watchOS 10 - minimum for SwiftData
        .visionOS(.v1)    // visionOS 1.0 - minimum for SwiftData
    ],
```

- Note the demos are simple, due to issues with SwiftData and Swift 6's stricter concurrency checking

---

## Create/Insert

✅ Created 5 expenses successfully

---

## Read

All expenses sorted by highest value

1. House: $120000.00
2. Car: $12000.00
3. Holiday: $8000.00
4. Laptop: $2500.00
5. Golf clubs: $500.00

---

## Update

Updating Car value to $15000.00

✅ Updated Car successfully

--------------------

## Delete

Removing Golf clubs

✅ Deleted Golf clubs successfully

--------------------

## Search

Expenses over $10000.00
• House: $120000.00
• Car: $15000.00
