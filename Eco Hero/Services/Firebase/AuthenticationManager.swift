//
//  AuthenticationManager.swift
//  Eco Hero
//
//  Created by Rishabh Bansal on 11/15/25.
//

import Foundation
import SwiftUI
import FirebaseAuth

/// Manages user authentication state using Firebase Auth
@Observable
class AuthenticationManager {
    var isAuthenticated: Bool = false
    var currentUserEmail: String?
    var currentUserID: String?
    var errorMessage: String?

    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var hasSetupListener = false

    init() {
        // Listener setup will happen lazily when setupAuthListener() is called
    }

    func setupAuthListener() {
        guard !hasSetupListener else {
            print("⚠️ AuthManager: Listener already setup, skipping")
            return
        }
        hasSetupListener = true

        print("🔄 AuthManager: Setting up auth listener...")

        do {
            // Listen for authentication state changes
            authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
                print("🔔 AuthManager: Auth state changed")
                self?.isAuthenticated = user != nil
                self?.currentUserEmail = user?.email
                self?.currentUserID = user?.uid

                if let user = user {
                    print("✅ AuthManager: User signed in: \(user.uid)")
                } else {
                    print("ℹ️ AuthManager: No user signed in")
                }
            }

            // Check current auth state
            if let user = Auth.auth().currentUser {
                print("✅ AuthManager: Current user found: \(user.uid)")
                self.isAuthenticated = true
                self.currentUserEmail = user.email
                self.currentUserID = user.uid
            } else {
                print("ℹ️ AuthManager: No current user")
            }

            print("✅ AuthManager: Auth listener setup complete")
        } catch {
            print("❌ AuthManager: Error setting up auth listener: \(error)")
            print("❌ AuthManager: Error details: \(error.localizedDescription)")
        }
    }

    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }

    func signIn(email: String, password: String) async throws {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.isAuthenticated = true
            self.currentUserEmail = result.user.email
            self.currentUserID = result.user.uid
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }

    func signUp(email: String, password: String, displayName: String) async throws {
        do {
            // Create user with Firebase
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()

            self.isAuthenticated = true
            self.currentUserEmail = result.user.email
            self.currentUserID = result.user.uid
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }

    func signOut() throws {
        do {
            try Auth.auth().signOut()
            self.isAuthenticated = false
            self.currentUserEmail = nil
            self.currentUserID = nil
        } catch {
            throw AuthError.unknown
        }
    }

    func resetPassword(email: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch let error as NSError {
            throw AuthError.from(error)
        }
    }
}

enum AuthError: LocalizedError {
    case invalidCredentials
    case invalidEmail
    case emailAlreadyInUse
    case weakPassword
    case networkError
    case userNotFound
    case unknown

    static func from(_ error: NSError) -> AuthError {
        guard let errorCode = AuthErrorCode(rawValue: error.code) else {
            return .unknown
        }

        switch errorCode {
        case .invalidEmail:
            return .invalidEmail
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .weakPassword:
            return .weakPassword
        case .wrongPassword, .invalidCredential:
            return .invalidCredentials
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkError
        default:
            return .unknown
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .networkError:
            return "Network connection error. Please check your internet."
        case .userNotFound:
            return "No account found with this email"
        case .unknown:
            return "An error occurred. Please try again."
        }
    }
}
