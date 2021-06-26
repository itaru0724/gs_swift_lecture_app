//
//  ChatViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import MessageKit
import SDWebImage
import InputBarAccessoryView

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
    var messages = [Message]()
    var matchId: String!
    
    let currnetUser = Sender(senderId: UserDefaults.standard.value(forKey: "loggedInUserId") as! String, displayName: "Me")
    let dateFormatter:DateFormatter = DateFormatter()
        
    lazy var formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = likeUser.name
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
        
        let otherUser = Sender(senderId: likeUser.id, displayName: likeUser.name)
        
        messages.append(Message(sender: currnetUser,
                                messageId: "1",
                                sentDate: Date().addingTimeInterval(-86400),
                                kind: .text("Hello")))
        messages.append(Message(sender: otherUser,
                                messageId: "2",
                                sentDate: Date().addingTimeInterval(-86300),
                                kind: .text("Hello")))
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

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {return}
        DatabaseManager.shared.sendMessage(text: text, matchId: matchId, senderId: currnetUser.senderId) { success in
            let result = success ? "送信に成功" : "送信に失敗"
            print(result)
        }
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didChangeIntrinsicContentTo size: CGSize) {
        
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, textViewTextDidChangeTo text: String) {
        
    }
    
    func inputBar(_ inputBar: InputBarAccessoryView, didSwipeTextViewWith gesture: UISwipeGestureRecognizer) {
        
    }
    
}
