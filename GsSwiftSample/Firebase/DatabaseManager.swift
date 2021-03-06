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
    
    public func registerUser(name: String, email: String, password: String, photo: UIImage?, completion: @escaping (Bool) -> Void){
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard authResult != nil, error == nil else {
                print("Error creating user")
                return completion(false)
            }
            
            let user = [
                "name" : name,
                "email" : email
            ]
            
            var ref: DocumentReference? = nil
            ref = self?.db.collection("users").addDocument(data: user) { err in
                if let err = err {
                    print("Error adding document: \(err)")
                    completion(false)
                    return
                } else {
                    print("Document added with ID: \(ref!.documentID)")
                    self?.db.collection("users").document(ref!.documentID).updateData([
                        "firestoreId" : ref!.documentID
                    ])
                    
                    guard let image = photo, let data = image.pngData() else {
                        self?.getLoggedInUserId(loggedInUserEmail: email) { _ in
                            completion(true)
                        }
                        return
                    }
                    StorageManager.shared.uploadProfilePicture(with: data, fileName: "\(ref!.documentID)_profile_picture.png") { result in
                        switch result {
                        case .success(let url):
                            self?.db.collection("users").document(ref!.documentID).updateData([
                                "photoURL" : url
                            ])
                            self?.getLoggedInUserId(loggedInUserEmail: email) { _ in
                                completion(true)
                            }
                            return
                        case .failure(_):
                            print("Couldn't get profile url")
                            completion(false)
                            return
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
                    let document = querySnapshot?.documents.first
                    guard let id = document?.data()["firestoreId"] as? String else {return}
                    UserDefaults.standard.setValue(id, forKey: "loggedInUserId")
                    completion(id)
                }
            }
    }
    
    //MARK: - ??????????????????
    public func fetchUser(completion: @escaping ([User]) -> Void){
        var matchUserArray = [User]()
        var usersArray = [User]()
        guard let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") else {
            print("login??????user???id?????????????????????@fetchUser")
            return completion([User]())
        }
        fetchMatchUser { [weak self] users in
            if !users.isEmpty {
                matchUserArray = users //([User])???????????? [User]????????????
                
                self?.db.collection("users").whereField("firestoreId", isNotEqualTo: loggedInUserId).getDocuments { querySnapshot, error in
                    guard let querySnapshot = querySnapshot, error == nil else {
                        return completion([User]())
                    }
                    for document in querySnapshot.documents {
                        let data = document.data()
                        guard let name = data["name"] as? String,
                              let id = data["firestoreId"] as? String,
                              let photoURL = data["photoURL"] as? String else {
                            return completion([User]())
                        }
                        let user = User(id: id, name: name, photoURL: photoURL)
                        usersArray.append(user)
                    }
                    if matchUserArray.count == 0 {
                        completion(usersArray)
                        return
                    } else {
                        let notMatchedUsers: [User] = usersArray.compactMap{ user in
                            if (matchUserArray.filter{ $0 == user}).count == 0 {
                                return user
                            } else {
                                return nil
                            }
                        }
                        completion(notMatchedUsers)
                    }
                }
            } else {
                self?.db.collection("users").whereField("firestoreId", isNotEqualTo: loggedInUserId)
                    .getDocuments { querySnapshot, error in
                        guard let querySnapshot = querySnapshot, error == nil else {
                            return completion([User]())
                        }
                        for document in querySnapshot.documents {
                            let data = document.data()
                            guard let name = data["name"] as? String,
                                  let id = data["firestoreId"] as? String,
                                  let photoURL = data["photoURL"] as? String else {
                                return completion([User]())
                            }
                            let user = User(id: id, name: name, photoURL: photoURL)
                            usersArray.append(user)
                        }
                        completion(usersArray)
                    }
            }
        }
    }
    
    public func fetchMatchUser(completion: @escaping ([User]) -> Void){
        var matchUsers = [User]()
        guard let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as? String else {
            print("login??????user???id?????????????????????@fetchMatchUser")
            return
        }
        
        db.collection("matches").whereField("users", arrayContains: loggedInUserId).getDocuments { [weak self] querySnapshot, error in
            guard let querySnapshot = querySnapshot, error == nil else {
                return
            }
            
            if querySnapshot.documents.isEmpty {
                completion([User]())
            } else {
                for document in querySnapshot.documents {
                    let data = document.data()
                    
                    guard let users = data["users"] as? [String] else {
                        return
                    }
                    let matchUserId = users.filter{ $0 != loggedInUserId }
                    self?.db.collection("users").whereField("firestoreId", isEqualTo: matchUserId[0])
                        .getDocuments { querySnapshot, error in
                            guard error == nil else {return}
                            for document in querySnapshot!.documents { //???????????????1?????????????????????
                                let data = document.data()
                                guard let id = data["firestoreId"] as? String,
                                      let name = data["name"] as? String,
                                      let photoURL = data["photoURL"] as? String
                                else { return }
                                let user = User(id: id, name: name, photoURL: photoURL)
                                matchUsers.append(user)
                            }
                            //print("matchUsers: \(matchUsers)")
                            completion(matchUsers)
                        }
                    
                }
            }
            
            
        }
    }
    //MARK: - ???????????????
    public func sendLikeOrCancelLike(likeUserId: String, completion: @escaping (String) -> Void){
        guard let myUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as? String else {
            return
        }
        //?????????????????????
        db.collection("likes").whereField("myUserId", isEqualTo: likeUserId).whereField("likeUserId", isEqualTo: myUserId)
            .getDocuments { [weak self](querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    return
                } else if querySnapshot?.documents.isEmpty == true {
                    //???????????????????????????????????????????????????
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
                                        return
                                    } else {
                                        completion("?????????")
                                    }
                                }
                            } else {
                                for document in querySnapshot!.documents {
                                    print("\(document.documentID) => \(document.data())")
                                    self?.db.collection("likes").document(document.documentID).delete()
                                    completion("????????????????????????")
                                    return
                                }
                            }
                        }
                } else {
                    //?????????
                    let match = [
                        "users" : [myUserId,likeUserId]
                    ]
                    
                    var ref: DocumentReference? = nil
                    ref = self?.db.collection("matches").addDocument(data: match) { err in
                        if let err = err {
                            print("Error adding document: \(err)")
                        } else {
                            print("Document added with ID: \(ref!.documentID)")
                            completion("?????????")
                        }
                    }
                }
            }
    }
    
    func likeAlready(likeUserId: String, completion: @escaping (Bool) -> Void ) {
        guard let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") else { return }
        db.collection("likes")
            .whereField("myUserId", isEqualTo: loggedInUserId)
            .whereField("likeUserId", isEqualTo: likeUserId)
            .limit(to: 1).getDocuments {(querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                } else if querySnapshot?.documents.count == 0{
                    completion(false)
                } else {
                    completion(true)
                }
            }
    }
    //MARK: - ?????????????????????
    func sendMessage(text: String, matchId: String, senderId: String){
        let message = [
            "text" : text,
            "messageId" : UUID().uuidString,
            "senderId": senderId,
            "sentDate" : Date()
        ] as [String : Any]
        
        db.collection("messages").document(matchId).collection("message").addDocument(data: message){ err in
            if let err = err {
                print("Error writing document: \(err)")
            } else {
                print("Document successfully written!")
            }
        }
    }
    
    func getMatchId(likeUserId: String, completion: @escaping (String) -> Void){
        guard let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") else { return }
        db.collection("matches").whereField("users", arrayContainsAny: [loggedInUserId, likeUserId]).limit(to: 1)
            .getDocuments { querySnapshot, error in
                if let err = error  {
                    print("Error getting documents: \(err)")
                } else {
                    for document in querySnapshot!.documents {
                        print("\(document.documentID) => \(document.data())")
                        completion(document.documentID)
                    }
                }
            }
    }
    
    func getAllMessages(matchId: String, loggedInUserId: String, completion: @escaping ([Message]) -> Void){
        var messages = [Message]()
        db.collection("messages").document(matchId).collection("message").order(by: "sentDate").getDocuments { querySnapshot, error in
            guard let querySnapshot = querySnapshot, error == nil else {
                return
            }
            for document in querySnapshot.documents {
                let data = document.data()
                guard let text = data["text"] as? String,
                      let id = data["messageId"] as? String,
                      let senderId = data["senderId"] as? String,
                      let sentDate = data["sentDate"] as? Timestamp,
                      let date = sentDate.dateValue() as? Date else {
                    return
                }
                if senderId == loggedInUserId {
                    let sender = Sender(senderId: loggedInUserId, displayName: "Me")
                    let message = Message(sender: sender, messageId: id, sentDate: date, kind: .text(text))
                    messages.append(message)
                } else {
                    let sender = Sender(senderId: senderId, displayName: "?????????")
                    let message = Message(sender: sender, messageId: id, sentDate: date, kind: .text(text))
                    messages.append(message)
                }
                completion(messages)
            }
        }
    }
    
    func realtimeUpdatedMessages(matchId: String, loggedInUserId: String, completion: @escaping (Message) -> Void){
        db.collection("messages").document(matchId).collection("message").order(by: "sentDate")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot, error == nil else {
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added) {
                        let data = diff.document.data()
                        guard let text = data["text"] as? String,
                              let id = data["messageId"] as? String,
                              let senderId = data["senderId"] as? String,
                              let sentDate = data["sentDate"] as? Timestamp,
                              let date = sentDate.dateValue() as? Date else {
                            return
                        }
                        if senderId == loggedInUserId {
                            let sender = Sender(senderId: loggedInUserId, displayName: "Me")
                            let message = Message(sender: sender, messageId: id, sentDate: date, kind: .text(text))
                            completion(message)
                        } else {
                            let sender = Sender(senderId: senderId, displayName: "?????????")
                            let message = Message(sender: sender, messageId: id, sentDate: date, kind: .text(text))
                            completion(message)
                        }
                    }
                }
            }
    }
    
    func detachListener(matchId: String){
        let listener = db.collection("messages").document(matchId).collection("message").order(by: "sentDate")
            .addSnapshotListener { _, _ in }
        listener.remove()
    }
}
