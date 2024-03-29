
import UIKit

public enum DiffableDataSourceError: Error {
  case duplicatedSectionIdentifiers(Set<AnyHashable>)
  case duplicatedItemIdentifiers(Set<AnyHashable>)
}

extension NSDiffableDataSourceSnapshot {

  public mutating func safeAppendSections(
    _ sections: [SectionIdentifierType]
  ) throws {

    var sectionSet: Set<SectionIdentifierType> = []

    for section in sections {
      let (inserted, _) = sectionSet.insert(section)
      guard inserted else {
        throw DiffableDataSourceError.duplicatedSectionIdentifiers([section])
      }
    }


    var set = Set(sectionIdentifiers)
    set.formIntersection(sections)

    if set.isEmpty {
      appendSections(sections)
    } else {
      throw DiffableDataSourceError.duplicatedSectionIdentifiers(set)
    }

  }

  public mutating func safeAppendItems(
    _ items: [ItemIdentifierType],
    intoSection sectionIdentifier: SectionIdentifierType? = nil
  ) throws {

    var itemSet: Set<ItemIdentifierType> = []

    for item in items {
      let (inserted, _) = itemSet.insert(item)
      guard inserted else {
        throw DiffableDataSourceError.duplicatedItemIdentifiers([item])
      }
    }

    var set = Set(itemIdentifiers)
    set.formIntersection(items)

    if set.isEmpty {
      appendItems(items, toSection: sectionIdentifier)
    } else {
      throw DiffableDataSourceError.duplicatedItemIdentifiers(set)
    }

  }

}
