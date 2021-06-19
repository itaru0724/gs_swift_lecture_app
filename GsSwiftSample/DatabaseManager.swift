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
    
    public func registerUser(user: User, photo: UIImage?, completion: @escaping (Result<Bool, Error>) -> Void){
        Auth.auth().createUser(withEmail: user.email, password: user.password) { [weak self] authResult, error in
            guard authResult != nil, error == nil else {
                print("Error creating user")
                UserDefaults.standard.setValue(false, forKey: "isLogin")
                completion(.failure(RegisterError.AuthError))
                return
            }
            UserDefaults.standard.setValue("\(user.name)", forKey: "login_user_name")
            
            let user = [
                "name" : user.name,
                "email" : user.email
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
                        UserDefaults.standard.setValue(true, forKey: "isLogin")
                        return
                    }
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: "\(ref!.documentID)_profile_picture.png") { result in
                        switch result {
                        case .success(let url):
                            self?.db.collection("users").document(ref!.documentID).updateData([
                                "photoURL" : url
                            ])
                            completion(.success(true))
                            UserDefaults.standard.setValue(true, forKey: "isLogin")
                        case .failure(_):
                            print("Couldn't get profile url")
                            completion(.failure(RegisterError.StorageError))
                        }
                    }
                }
            }
        }
    }
    
}

enum RegisterError : Error {
    case AuthError
    case FirestoreError
    case StorageError
}
