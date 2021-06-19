//
//  ChatViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import MessageKit
import CoreLocation

class ChatViewController: MessagesViewController, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        messagesCollectionView.messagesDataSource = self
//        messagesCollectionView.messagesLayoutDelegate = self
//        messagesCollectionView.messagesDisplayDelegate = self
    }
}

//extension ChatViewController : MessagesDataSource{
//    func currentSender() -> SenderType {
//        <#code#>
//    }
//
//    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        <#code#>
//    }
//
//    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
//        <#code#>
//    }
//}
