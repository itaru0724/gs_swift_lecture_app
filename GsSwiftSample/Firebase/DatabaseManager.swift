//
//  AuthManager.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class DatabaseManager {
    static let shared = DatabaseManager()
    private init() {}
    let db = Firestore.firestore()
    
    public func registerUser(name: String, email: String, password: String, photo: UIImage?, completion: @escaping (Result<Bool, Error>) -> Void){
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard authResult != nil, error == nil else {
                print("Error creating user")
                UserDefaults.standard.setValue(false, forKey: "isLogin")
                completion(.failure(RegisterError.AuthError))
                return
            }
            UserDefaults.standard.setValue("\(email)", forKey: "logged_user_email")
            
            let user = [
                "name" : name,
                "email" : email
            ]
            
            var ref: DocumentReference? = nil
            ref = self?.db.collection("users").addDocument(data: user) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                    completion(.failure(RegisterError.FirestoreError))
                } else {
                    print("Document added with ID: \(ref!.documentID)")
                    self?.db.collection("users").document(ref!.documentID).updateData([
                        "firestoreId" : ref!.documentID
                    ])
                    
                    guard let image = photo, let data = image.pngData() else {
                        completion(.success(true))
                        UserDefaults.standard.setValue(email, forKey: "logged_user_email")
                        return
                    }
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: "\(ref!.documentID)_profile_picture.png") { result in
                        switch result {
                        case .success(let url):
                            self?.db.collection("users").document(ref!.documentID).updateData([
                                "photoURL" : url
                            ])
                            completion(.success(true))
                            UserDefaults.standard.setValue(email, forKey: "logged_user_email")
                        case .failure(_):
                            print("Couldn't get profile url")
                            completion(.failure(RegisterError.StorageError))
                        }
                    }
                }
            }
        }
    }
    
    public func fetchUser(completion: @escaping (Result<[User], Error>) -> Void){
        var usersArray = [User]()
        guard let loggedInUserEmail = UserDefaults.standard.value(forKey: "logged_user_email") else {
            return completion(.failure(FetchUserError.NoEmailRegistered))
        }
        
        //マッチしたユーザーも除く
        db.collection("users").whereField("email", isNotEqualTo: loggedInUserEmail).getDocuments { querySnapshot, error in
            guard let querySnapshot = querySnapshot, error == nil else {
                return completion(.failure(FetchUserError.FailedToFetchUser))
            }
            for document in querySnapshot.documents {
                let data = document.data()
                print(data)
                guard let name = data["name"] as? String,
                      let id = data["firestoreId"] as? String,
                      let photoURL = data["photoURL"] as? String else {
                    return completion(.failure(FetchUserError.FailedToParse))
                }
                let user = User(id: id, name: name, photoURL: photoURL)
                print(user)
                usersArray.append(user)
            }
            completion(.success(usersArray))
        }
    }
    
}

enum RegisterError : Error {
    case AuthError
    case FirestoreError
    case StorageError
}

enum FetchUserError : Error {
    case NoEmailRegistered
    case FailedToFetchUser
    case FailedToParse
}

