import Foundation

struct Workout: Identifiable { // Conform to Identifiable
    var id = UUID() // Unique identifier
    var type: String
    var sets: Int
    var reps: Int
    var date: Date
    var notes: String
}
