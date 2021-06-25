//
//  HomeViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import SDWebImage

class HomeViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()
        DatabaseManager.shared.fetchUser { [weak self] result in
//            print(result)
            switch result{
            case .success(let users):
                DispatchQueue.main.async {
                    self?.users = users
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}

extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        cell.imageView?.sd_setImage(with: URL(string: user.photoURL!), completed: { (_, error, _, _) in
          if error == nil {
            cell.setNeedsLayout()//これがないと普通のcellで画像が一発で表示されない
          }
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let likeUserId = users[indexPath.row].id
        DatabaseManager.shared.sendLikeOrCancelLike(likeUserId: likeUserId) { [weak self] result in
            let title = result ? "いいね" : "いいねをキャンセル"
            let alert = UIAlertController(title: title, message: "\(title)しました。", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self?.present(alert, animated: true)
        }
    }
}
