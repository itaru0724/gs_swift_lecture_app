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
                completion(.failure(RegisterError.AuthError))
                return
            }
            
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
                        self?.getLoggedInUserId(loggedInUserEmail: email) { id in
                            UserDefaults.standard.setValue(id, forKey: "loggedInUserId")
                        }
                        return
                    }
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: "\(ref!.documentID)_profile_picture.png") { result in
                        switch result {
                        case .success(let url):
                            self?.db.collection("users").document(ref!.documentID).updateData([
                                "photoURL" : url
                            ])
                            completion(.success(true))
                            self?.getLoggedInUserId(loggedInUserEmail: email) { id in
                                UserDefaults.standard.setValue(id, forKey: "loggedInUserId")
                            }
                        case .failure(_):
                            print("Couldn't get profile url")
                            completion(.failure(RegisterError.StorageError))
                        }
                    }
                }
            }
        }
    }
    
    public func getLoggedInUserId(loggedInUserEmail: String, completion: @escaping (String)->Void){
        db.collection("users").whereField("email", isEqualTo: loggedInUserEmail)
            .getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        guard let id = document.data()["firestoreId"] as? String else {return}
                        UserDefaults.standard.setValue(id, forKey: "loggedInUserId")
                        completion(id)
                    }
                }
        }
    }
    
    public func fetchUser(completion: @escaping (Result<[User], Error>) -> Void){
        var matchUserArray = [User]()
        var usersArray = [User]()
        fetchMatchUser { [weak self] result in
            switch result {
            case .success(let users):
                matchUserArray = users //([User])ってなに [User]との違い
                
                guard let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") else {
                    return completion(.failure(FetchUserError.FailedToGetId))
                }
                
                self?.db.collection("users").whereField("firestoreId", isNotEqualTo: loggedInUserId).getDocuments { querySnapshot, error in
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
//                    completion(.success(matchUserArray))
                    if matchUserArray.count == 0 {
                        completion(.success(usersArray))
                    } else {
                        let notMatchedUsers: [User] = usersArray.compactMap{ user in
                            if (matchUserArray.filter{ $0 == user}).count == 0 {
                                return user
                            } else {
                                return nil
                            }
                        }
                        completion(.success(notMatchedUsers))
                    }
                    
                }
                
            case .failure(_):
                print(FetchUserError.FailedToFetchUser)
            }
        }
    }
    
    public func sendLikeOrCancelLike(likeUserId: String, completion: @escaping (Result<String, Error>) -> Void){
        guard let myUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as? String else {
            return completion(.failure(LikeError.FailedToGetMyId))
        }
        //マッチチェック
        db.collection("likes").whereField("myUserId", isEqualTo: likeUserId).whereField("likeUserId", isEqualTo: myUserId)
            .getDocuments { [weak self](querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    completion(.failure(LikeError.FailedToCheckMatch))
                } else if querySnapshot?.documents.isEmpty == true {
                    //いいねかいいねキャンセルか出しわけ
                    self?.db.collection("likes").whereField("myUserId", isEqualTo: myUserId).whereField("likeUserId", isEqualTo: likeUserId)
                        
                        .getDocuments() { [weak self](querySnapshot, err) in
                            if let err = err {
                                print("Error getting documents: \(err)")
                            } else if querySnapshot?.documents.isEmpty == true {
                                self?.db.collection("likes").addDocument(data: [
                                    "myUserId": myUserId,
                                    "likeUserId": likeUserId
                                ]) { err in
                                    if let err = err {
                                        print("Error adding document: \(err)")
                                        completion(.failure(LikeError.FailedToLike))
                                    } else {
                                        completion(.success("いいね"))
                                    }
                                }
                            } else {
                                for document in querySnapshot!.documents {
                                    print("\(document.documentID) => \(document.data())")
                                    self?.db.collection("likes").document(document.documentID).delete()
                                    completion(.success("いいねキャンセル"))
                                    return
                                }
                            }
                    }
                } else {
                    //マッチ
                    let match = [
                        "users" : [myUserId,likeUserId]
                    ]
                    
                    var ref: DocumentReference? = nil
                    ref = self?.db.collection("matches").addDocument(data: match) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            print("Document added with ID: \(ref!.documentID)")
                            completion(.success("マッチ"))
                        }
                    }
                }
            }
    }
    
    public func fetchMatchUser(completion: @escaping (Result<[User], Error>) -> Void){
        var matchUsers = [User]()
        guard let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as? String else {
            return completion(.failure(FetchUserError.FailedToGetId))
        }
        
        db.collection("matches").whereField("users", arrayContains: loggedInUserId).getDocuments { [weak self] querySnapshot, error in
            guard let querySnapshot = querySnapshot, error == nil else {
                return completion(.failure(FetchUserError.FailedToFetchUser))
            }
            
            if querySnapshot.documents.isEmpty {
                completion(.success([User]()))
            } else {
                for document in querySnapshot.documents {
                    let data = document.data()
                    
                    guard let users = data["users"] as? [String] else {
                        return completion(.failure(FetchUserError.FailedToParse))
                    }
                    let matchUserId = users.filter{ $0 != loggedInUserId }
                    self?.db.collection("users").whereField("firestoreId", isEqualTo: matchUserId[0])
                        .getDocuments { querySnapshot, error in
                            guard error == nil else {return}
                            for document in querySnapshot!.documents { //修正したい1件だけ取得の形
                                let data = document.data()
                                guard let id = data["firestoreId"] as? String,
                                      let name = data["name"] as? String,
                                      let photoURL = data["photoURL"] as? String
                                else { return }
                                let user = User(id: id, name: name, photoURL: photoURL)
                                matchUsers.append(user)
                            }
                            //print("matchUsers: \(matchUsers)")
                            completion(.success(matchUsers))
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

enum FetchUserError : Error {
    case FailedToGetId
    case FailedToFetchUser
    case FailedToParse
}

enum LikeError : Error {
    case FailedToGetMyId
    case FailedToLike
    case FailedToCheckMatch
}
