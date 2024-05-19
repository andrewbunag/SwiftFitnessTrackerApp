import SwiftUI
import MapKit
import WebKit
struct ContentView: View {
    @StateObject var viewModel = CredentialViewModel()
    @StateObject var workoutviewModel = WorkoutViewModel()
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoggedIn {
                    MainNavigationView(viewModel: workoutviewModel )
                } else {
                    LoginView(viewModel: viewModel)
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: CredentialViewModel
    @StateObject var workoutviewModel = WorkoutViewModel()

    
    var body: some View {
        VStack {
            Spacer()
            
            // Username TextField
            TextField("Username", text: $viewModel.userCredential.username)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Password SecureField
            SecureField("Password", text: $viewModel.userCredential.password)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
            
            // Login Button
            Button(action: {
                viewModel.login()
            }) {
                Text("Login")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            
            Spacer()
        }
        .fullScreenCover(isPresented: $viewModel.isLoggedIn) {
            MainNavigationView(viewModel: workoutviewModel)
        }
    }
}

struct WorkoutRow: View {
    var workout: Entity

    var body: some View {
        VStack(alignment: .leading) {
            Text("Type: \(workout.workoutType ?? "Unknown Type")")
            Text("Sets: \(workout.workoutSets)")
            Text("Reps: \(workout.workoutReps)")
            Text("Date: \(formattedDate)")
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal)
    }

    private var formattedDate: String {
              guard let workoutDate = workout.workoutDate else {
                  return ""
              }
              let formatter = DateFormatter()
              formatter.dateStyle = .short
              formatter.timeStyle = .short
              return formatter.string(from: workoutDate)
          }
      }

struct LoggedWorkoutsView: View {
    @ObservedObject var viewModel: WorkoutViewModel

    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }

    var body: some View {
        List {
            ForEach(viewModel.workoutsGroupedByDate.keys.sorted(by:>), id: \.self) { date in
                Section(header: Text(dateFormatter.string(from: date))) {
                    ForEach(viewModel.workoutsGroupedByDate[date]!, id: \.self) { workout in
                        WorkoutRow(workout: workout)
                    }
                    .onDelete { indexSet in
                        viewModel.deleteWorkout(at: indexSet)
                    }
                }
            }
        }
        .onAppear {
            viewModel.getWorkouts()
        }
        
    }
}


struct DataEntryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    // State variables to hold the user input for new workout data
    @State private var workoutType = ""
    @State private var sets = ""
    @State private var reps = ""
    @State private var notes = ""
    @State private var selectedDate = Date()

    
    var body: some View {
        Form {
            Section(header: Text("Workout Details")) {
                TextField("Workout Type", text: $workoutType)
                TextField("Sets", text: $sets)
                    .keyboardType(.numberPad)
                TextField("Reps", text: $reps)
                    .keyboardType(.numberPad)
                TextField("Notes", text: $notes)
                DatePicker("Date", selection: $selectedDate, displayedComponents: .date) // DatePicker for selecting date

            }
            
            Section {
                Button(action: addWorkout) {
                    Text("Add Workout")
                }
            }
        }
        .navigationTitle("Add New Workout")
    }
    
    // Function to add new workout to the list
    func addWorkout() {
        // Validate input
        guard let sets = Int(sets), let reps = Int(reps) else {
            // Handle invalid input
            return
        }
        
        // Create a new Workout object
        viewModel.addWorkout(type: workoutType, sets: Int16(sets), reps: Int16(reps), date: selectedDate, notes: notes)
        
       
        
        // Reset input fields
        workoutType = ""
       
        notes = ""
    }
}



struct ExerciseTutorialView: View {
    // State variables to hold user input and nearby places
    @State private var locationName = ""
    @State private var nearbyPlaces: [MKMapItem] = []
    @State private var searchQuery = ""
    @State private var videos: [Video] = []
    @State private var selectedVideoId: String?


    var body: some View {
        VStack {
            // Text field for user input
            TextField("Enter city or location", text: $locationName)
                .padding()
            
            // Button to search for nearby places
            Button("Search Gyms") {
                fetchNearbyPlaces()
            }
            .padding()
            
            // List to display nearby places
            List(nearbyPlaces, id: \.self) { place in
                VStack(alignment: .leading) {
                    Text(place.name ?? "Unknown")
                        .font(.headline)
                    Text(place.placemark.title ?? "")
                        .font(.subheadline)
                }
                .padding()
                .onTapGesture {
                    openInMaps(place: place)
                }
            }
            Divider()
            
            // Text field and search button for YouTube videos
            HStack {
                TextField("Search workout tutorials", text: $searchQuery)
                    .padding()
                Button("Search Videos") {
                    searchYouTubeVideos(query: searchQuery) { result in
                        switch result {
                        case .success(let items):
                            self.videos = items.map { Video(videoId: $0.id.videoId, title: $0.snippet.title, description: $0.snippet.description) }
                        case .failure(let error):
                            print("Error searching videos:", error.localizedDescription)
                        }
                    }
                }
                .padding()
            }
            
           
            List(videos, id: \.id) { video in
                NavigationLink(destination: WebView(url: "https://www.youtube.com/watch?v=\(video.id)")) {
                    VStack(alignment: .leading) {
                        Text(video.title)
                            .font(.headline)
                        Text(video.description)
                            .font(.subheadline)
                    }
                    .padding()
                }
            }}}
    
    
    // Function to fetch nearby places based on user input
    func fetchNearbyPlaces() {
        // Create a geocoder
        let geocoder = CLGeocoder()
        
        // Perform geocoding to convert location name to coordinates
        geocoder.geocodeAddressString(locationName) { placemarks, error in
            guard let placemark = placemarks?.first, error == nil else {
                print("Error geocoding location: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            // Extract coordinates from the placemark
            let coordinate = placemark.location?.coordinate
            
            guard let latitude = coordinate?.latitude, let longitude = coordinate?.longitude else {
                print("Failed to extract coordinates from placemark.")
                return
            }
            
            // Create a search request for nearby gyms
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = "Gym"
            request.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), latitudinalMeters: 1000, longitudinalMeters: 1000)
            
            // Perform the search
            let search = MKLocalSearch(request: request)
            search.start { response, error in
                guard let response = response, error == nil else {
                    print("Error searching for places: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                self.nearbyPlaces = response.mapItems
            }
        }
    }
    
    // Function to open the Maps app with the selected gym's location
    func openInMaps(place: MKMapItem) {
        let mapItem = place
        mapItem.openInMaps()
    }
}

struct Video: Identifiable {
    var id = UUID()
    var videoId: String
    var title: String
    var description: String
}


struct Response: Codable {
    var items: [Item]

    struct Item: Codable {
        var id: Id
        var snippet: Snippet

        struct Id: Codable {
            var videoId: String
        }

        struct Snippet: Codable {
            var title: String
            var description: String
        }
    }
}


func searchYouTubeVideos(query: String, completion: @escaping (Result<[Response.Item], Error>) -> Void) {
    guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid query"])))
        return
    }
    
    let apiKey = "AIzaSyCzh9hrpHkUOMdBYO6n7lOqD-wU3-UDoJY"
    let urlString = "https://www.googleapis.com/youtube/v3/search?key=\(apiKey)&part=snippet&q=\(encodedQuery)"
    
    guard let url = URL(string: urlString) else {
        completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
        return
    }
    
    URLSession.shared.dataTask(with: url) { data, response, error in
        guard let data = data, error == nil else {
            completion(.failure(error ?? NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown error"])))
            return
        }
        if let dataString = String(data: data, encoding: .utf8) {
            print("Received data:", dataString)
        }
        

        
        do {
            let response = try JSONDecoder().decode(Response.self, from: data)
            completion(.success(response.items))
        } catch {
            completion(.failure(error))
        }
    }.resume()
}

struct WebView: UIViewRepresentable {
    let url: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        if let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}
}

struct MainNavigationView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Welcome to FitTracker!")
                    .font(.title)
                    .padding()
                
                NavigationLink(destination: LoggedWorkoutsView(viewModel: viewModel)) {
                    Text("View Logged Workouts")
                        .foregroundColor(.blue)
                        .padding()
                }
                
                NavigationLink(destination: DataEntryView(viewModel: viewModel)) {
                    Text("Add New Workout")
                        .foregroundColor(.blue)
                        .padding()
                }
                NavigationLink(destination: ExerciseTutorialView()) {
                    Text("Exercise Tutorials & Local Gyms")
                        .foregroundColor(.blue)
                        .padding()
                }
            }
        }
    }
}
