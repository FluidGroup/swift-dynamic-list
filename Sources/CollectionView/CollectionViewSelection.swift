
public enum SelectAction {
  case selected
  case deselected
}

public protocol CollectionViewSelection<Item> {
  
  associatedtype Item: Identifiable
  
  /// Returns whether the item is selected or not
  func isSelected(for id: Item.ID) -> Bool
  
  /// Returns whether the item is enabled to be selected or not
  func isEnabled(for id: Item.ID) -> Bool
  
  /// Update the selection state
  func update(isSelected: Bool, for item: Item)
}

extension CollectionViewSelection {
  
  public static func single<Item: Identifiable>(
    selected: Item.ID?,
    onChange: @escaping (_ selected: Item?) -> Void
  ) -> Self where Self == CollectionViewSelectionModes.Single<Item> {
    .init(
      selected: selected,
      onChange: onChange
    )
  }
  
  public static func multiple<Item: Identifiable>(
    selected: Set<Item.ID>,
    canMoreSelect: Bool,
    onChange: @escaping (_ selected: Item, _ selection: SelectAction) -> Void
  ) -> Self where Self == CollectionViewSelectionModes.Multiple<Item> {
    .init(
      selected: selected,
      canMoreSelect: canMoreSelect,
      onChange: onChange
    )
  }
    
}

public enum CollectionViewSelectionModes {
  
  public struct None<Item: Identifiable>: CollectionViewSelection {
    
    public init() {
      
    }
    
    public func isSelected(for id: Item.ID) -> Bool {
      false
    }
    
    public func isEnabled(for id: Item.ID) -> Bool {
      true
    }    
    
    public func update(isSelected: Bool, for item: Item) {
      
    }
  }
  
  public struct Single<Item: Identifiable>: CollectionViewSelection {
    
    private let selected: Item.ID?
    private let onChange: (_ selected: Item?) -> Void
    
    public init(
      selected: Item.ID?,
      onChange: @escaping (_ selected: Item?) -> Void      
    ) {
      self.selected = selected
      self.onChange = onChange
    }
    
    public func isSelected(for id: Item.ID) -> Bool {
      self.selected == id
    }
    
    public func isEnabled(for id: Item.ID) -> Bool {
      return true
    }
    
    public func update(isSelected: Bool, for item: Item) {
      if isSelected {
        onChange(item)
      } else {
        onChange(nil)
      }
    }
    
  }
  
  public struct Multiple<Item: Identifiable>: CollectionViewSelection {
    
    private let selected: Set<Item.ID>
    private let canMoreSelect: Bool
    private let onChange: (_ selected: Item, _ action: SelectAction) -> Void
    
    public init(
      selected: Set<Item.ID>,
      canMoreSelect: Bool,
      onChange: @escaping (_ selected: Item, _ action: SelectAction) -> Void      
    ) {
      self.selected = selected
      self.canMoreSelect = canMoreSelect
      self.onChange = onChange                  
    }
    
    public func isSelected(for id: Item.ID) -> Bool {
      self.selected.contains(id)
    }
    
    public func isEnabled(for id: Item.ID) -> Bool {
      if isSelected(for: id) {
        return true
      }
      return canMoreSelect
    }
    
    public func update(isSelected: Bool, for item: Item) {
      if isSelected {
        onChange(item, .selected)
      } else {
        onChange(item, .deselected)
      }
    }
  }
  
}
