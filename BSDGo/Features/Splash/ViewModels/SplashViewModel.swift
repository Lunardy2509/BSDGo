//
//  SplashViewModel.swift
//  BSDGo
//
//  Created by Ferdinand Lunardy on 21/01/2026.
//

import Foundation
import Combine
import FirebaseAuth

final class SplashViewModel: ObservableObject {
    @Published var isActive: Bool = false
    @Published var errorMessage: String?
    
    private let minimumSplashTime: TimeInterval = 1.5
    
    func checkAuthentication() {
        let startTime = Date()
        
        if Auth.auth().currentUser != nil {
            proceedAfterDelay(startTime: startTime)
        } else {
            Auth.auth().signInAnonymously { [weak self] _, error in
                if let error = error {
                    print("Authentication Failed: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                } else {
                    self?.proceedAfterDelay(startTime: startTime)
                }
            }
        }
    }
    
    private func proceedAfterDelay(startTime: Date) {
        let elapsedTime = Date().timeIntervalSince(startTime)
        let remaining = max(minimumSplashTime - elapsedTime, 0)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + remaining) {
            self.isActive = true
        }
    }
}
