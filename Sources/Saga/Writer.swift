import PathKit
import Foundation

public struct Writer {
  var write: ([Page], (Path, [String : Any], Path) throws -> Void, Path, Path, ((Page) -> Bool)) throws -> Void
}

public extension Writer {
  static func section(folder: Path, filter: @escaping ((Page) -> Bool) = { _ in true }, writers:[Writer]) -> Self {
    return Self { fileWrappers, environment, output, _, _ in
      for writer in writers {
        try writer.write(fileWrappers, environment, output, folder, filter)
      }
    }
  }

  // Write a single Page to disk, using Page.destination as the destination path
  static func pageWriter(template: Path, filter: @escaping ((Page) -> Bool) = { _ in true }) -> Self {
    return Self { allPages, render, outputRoot, outputSubpath, firstFilter in
      let pages = allPages.filter(firstFilter).filter(filter).filter { $0.written == false }

      for page in pages {
        let context = [
          "page": page,
          "allPages": allPages,
        ] as [String : Any]

        // Call out to the render function
        try render(template, context, outputRoot + page.relativeDestination)

        // Mark the pages as written so that a different (less specifically constrained)
        // pageWriter isn't going to handle it again
        page.written = true
      }
    }
  }

  // Writes an array of Pages into a single output file.
  // As such, it needs an output path, for example "articles/index.html".
  static func listWriter(template: Path, output: Path = "index.html", filter: @escaping ((Page) -> Bool) = { _ in true }) -> Self {
    return Self { allPages, render, outputRoot, outputSubpath, firstFilter in
      let pages = allPages.filter(firstFilter).filter(filter)

      let context = [
        "pages": pages,
        "allPages": allPages,
      ] as [String : Any]

      // Call out to the render function
      try render(template, context, outputRoot + outputSubpath + output)
    }
  }

  // Writes an array of pages into multiple output files.
  // The output path is a template where [year] will be replaced with the year of the Page.
  // Example: "articles/[year]/index.html"
  static func yearWriter(template: Path, output: Path = "[year]/index.html", filter: @escaping ((Page) -> Bool) = { _ in true }) -> Self {
    return Self { allPages, render, outputRoot, outputSubpath, firstFilter in
      let pages = allPages.filter(firstFilter).filter(filter)

      // Find all the years and their pages
      var pagesPerYear = [Int: [Page]]()

      for page in pages {
        let year = page.date.year
        if var pagesArray = pagesPerYear[year] {
          pagesArray.append(page)
          pagesPerYear[year] = pagesArray
        } else {
          pagesPerYear[year] = [page]
        }
      }

      for (year, pagesInYear) in pagesPerYear {
        let context = [
          "year": year,
          "pages": pagesInYear,
          "allPages": allPages,
        ] as [String : Any]

        // Call out to the render function
        let yearOutput = output.string.replacingOccurrences(of: "[year]", with: "\(year)")
        try render(template, context, outputRoot + outputSubpath + yearOutput)
      }
    }
  }

  // Writes an array of pages into multiple output files.
  // The output path is a template where [tag] will be replaced with the slugified tag.
  // Example: "articles/[tag]/index.html"
  static func tagWriter(template: Path, output: Path = "[tag]/index.html", tags: @escaping (Page) -> [String], filter: @escaping ((Page) -> Bool) = { _ in true }) -> Self {
    return Self { allPages, render, outputRoot, outputSubpath, firstFilter in
      let pages = allPages.filter(firstFilter).filter(filter)

      // Find all the tags and their pages
      var pagesPerTag = [String: [Page]]()

      for page in pages {
        for tag in tags(page) {
          if var pagesArray = pagesPerTag[tag] {
            pagesArray.append(page)
            pagesPerTag[tag] = pagesArray
          } else {
            pagesPerTag[tag] = [page]
          }
        }
      }

      for (tag, pagesInTag) in pagesPerTag {
        let context = [
          "tag": tag,
          "pages": pagesInTag,
          "allPages": allPages,
        ] as [String : Any]

        // Call out to the render function
        let yearOutput = output.string.replacingOccurrences(of: "[tag]", with: tag)
        try render(template, context, outputRoot + outputSubpath + yearOutput)
      }
    }
  }
}

private extension Date {
  var year: Int {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy"
    return Int(formatter.string(from: self))!
  }
}
