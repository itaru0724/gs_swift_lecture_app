//
//  ChatViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import MessageKit
import SDWebImage

struct Sender: SenderType {
    var senderId: String
    var displayName: String
}

struct Message : MessageType {
    var sender: SenderType
    var messageId: String
    var sentDate: Date
    var kind: MessageKind
}

class ChatViewController: MessagesViewController, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    var likeUser: User!
    
    let currnetUser = Sender(senderId: UserDefaults.standard.value(forKey: "loggedInUserId") as! String, displayName: "Me")
    let otherUser = Sender(senderId: "2", displayName: "Yurina Hirate")
    
    var messages = [Message]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = likeUser.name
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        messages.append(Message(sender: currnetUser,
                                messageId: "1",
                                sentDate: Date().addingTimeInterval(-86400),
                                kind: .text("Hello")))
        messages.append(Message(sender: otherUser,
                                messageId: "2",
                                sentDate: Date().addingTimeInterval(-70000),
                                kind: .text("How are you")))
        messages.append(Message(sender: currnetUser,
                                messageId: "3",
                                sentDate: Date().addingTimeInterval(-60000),
                                kind: .text("Good, you?")))
        messages.append(Message(sender: otherUser,
                                messageId: "4",
                                sentDate: Date().addingTimeInterval(-50000),
                                kind: .text("its hot")))
        messages.append(Message(sender: currnetUser,
                                messageId: "5",
                                sentDate: Date().addingTimeInterval(-30000),
                                kind: .text("last message")))
    }
}

extension ChatViewController : MessagesDataSource{
    func currentSender() -> SenderType {
        return currnetUser
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        messages[indexPath.section]
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}
