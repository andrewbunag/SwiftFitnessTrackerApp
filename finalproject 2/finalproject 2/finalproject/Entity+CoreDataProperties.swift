

import Foundation
import CoreData


extension Entity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Entity> {
        return NSFetchRequest<Entity>(entityName: "Entity")
    }

    @NSManaged public var workoutType: String?
    @NSManaged public var workoutSets: Int16
    @NSManaged public var workoutReps: Int16
    @NSManaged public var workoutDate: Date?
    @NSManaged public var workoutNotes: String?

}

extension Entity : Identifiable {

}
