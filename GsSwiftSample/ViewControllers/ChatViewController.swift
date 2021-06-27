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
    let loggedInUserId = UserDefaults.standard.value(forKey: "loggedInUserId") as! String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = likeUser.name
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messageInputBar.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        
        DatabaseManager.shared.realtimeUpdatedMessages(matchId: matchId, loggedInUserId: loggedInUserId) { [weak self] message in
            self?.messages.append(message)
            self?.messagesCollectionView.reloadData()
            self?.messagesCollectionView.scrollToLastItem()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        DatabaseManager.shared.detachListener(matchId: matchId)
        messageInputBar.isHidden = true
        messages = [Message]()
    }
}

extension ChatViewController : MessagesDataSource{
    func currentSender() -> SenderType {
        return Sender(senderId: loggedInUserId, displayName: "Me")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty else {return}
        DatabaseManager.shared.sendMessage(text: text, matchId: matchId, senderId: loggedInUserId)
    }
}
