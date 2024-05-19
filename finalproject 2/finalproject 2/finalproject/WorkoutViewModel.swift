import Foundation
import CoreData

class WorkoutViewModel: ObservableObject {
    @Published var workouts: [Entity] = []
    var workoutsGroupedByDate: [Date: [Entity]] = [:]

    
    func addWorkout(type: String, sets: Int16, reps: Int16, date: Date, notes: String) {
        let newWorkout = Entity(context: CoreDataStack.shared.managedObjectContext)
        newWorkout.workoutType = type
        newWorkout.workoutSets = sets
        newWorkout.workoutReps = reps
        newWorkout.workoutDate = date
        newWorkout.workoutNotes = notes
        
        do {
            try CoreDataStack.shared.managedObjectContext.save()
            print("Workout saved successfully")
        } catch {
            print("Failed to save workout: \(error)")
        }
    }
    
    func deleteWorkout(at offsets: IndexSet) {
        for index in offsets {
            let workout = workouts[index]
            CoreDataStack.shared.managedObjectContext.delete(workout)
        }
        do {
            try CoreDataStack.shared.managedObjectContext.save()
            print("Workout deleted successfully")
        } catch {
            print("Failed to delete workout: \(error)")
        }
    }

    
    func getWorkouts() {
            let fetchRequest: NSFetchRequest<Entity> = Entity.fetchRequest()
            
            do {
                let results = try CoreDataStack.shared.managedObjectContext.fetch(fetchRequest)
                workouts = results
                
                // Group workouts by date
                workoutsGroupedByDate = Dictionary(grouping: results) { workout in
                    guard let date = workout.workoutDate else {
                        return Date() // Return a default date if workout date is nil
                    }
                    return Calendar.current.startOfDay(for: date)
                }
                
                // Remove duplicate dates
                workoutsGroupedByDate = workoutsGroupedByDate.mapValues { Array(Set($0)) }
            } catch {
                print("Failed to fetch workouts: \(error)")
            }
        }
    }


