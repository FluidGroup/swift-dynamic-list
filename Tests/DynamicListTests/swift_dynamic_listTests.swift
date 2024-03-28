import XCTest

@testable import DynamicList

final class swift_dynamic_listTests: XCTestCase {
  func testDiffable_append_duplicated() throws {

    var snapshot = NSDiffableDataSourceSnapshot<String, Int>()
    snapshot.appendSections(["A"])

    do {
      try snapshot.safeAppendItems([0, 0])
      XCTFail()
    } catch {

    }
  }

  func testDiffable_append_duplicated_2() throws {

    var snapshot = NSDiffableDataSourceSnapshot<String, Int>()
    snapshot.appendSections(["A"])
    snapshot.appendItems([0])

    do {
      try snapshot.safeAppendItems([0])
      XCTFail()
    } catch {

    }
  }

  func testIntersect() throws {

    XCTAssertEqual(Set([1,2]).intersection([3,4]).isEmpty, true)

  }
}
