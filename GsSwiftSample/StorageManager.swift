//
//  StorageManager.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/20.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    private init() {}
    private let storage = Storage.storage().reference()
    
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping (Result<String, Error>) -> Void){
        
        storage.child("images/\(fileName)").putData(data, metadata: nil) { [weak self](metaData, error) in
            guard error == nil else {
                print("Failed to upload pic to firebase storage")
                completion(.failure(StorageError.failedToUpload)) //typealiasで記述したResult型のError.を下でenumを使って作った
                return
            }
            
            self?.storage.child("images/\(fileName)").downloadURL { (url, error) in
                guard let url = url else {
                    print("Failed to get download url from firebase storage")
                    completion(.failure(StorageError.failedToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
                
            }
        }
    }
}

private enum StorageError: Error {
    case failedToUpload
    case failedToGetDownloadUrl
}
