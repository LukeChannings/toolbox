import Foundation
import ArgumentParser

struct Path: ExpressibleByArgument {
    var url: NSURL
    
    init?(argument path: String) {
        self.url = NSURL(fileURLWithPath: path)
    }
}

@main
struct mkalias: ParsableCommand {
    
    @Argument var source: Path
    @Argument var destination: Path
    
    mutating func run() throws {
        
        let bookmark = try source.url.bookmarkData(
            options: .suitableForBookmarkFile,
            includingResourceValuesForKeys: [],
            relativeTo: nil
        )

        try NSURL.writeBookmarkData(bookmark, to: destination.url as URL, options: 0)
        
        print("Created an alias for \(source.url.absoluteString!) at \(destination.url.absoluteString!)")
    }
}
