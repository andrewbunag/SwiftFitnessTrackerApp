import Foundation
import SwiftUI

class CredentialViewModel: ObservableObject {
    @Published var userCredential = UserCredential(username: "", password: "")
    @Published var isLoggedIn = false
    
    func login() {
        
        if userCredential.username == "Username" && userCredential.password == "Password" {
            isLoggedIn = true
        }
    }
}
