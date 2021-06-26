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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DatabaseManager.shared.fetchUser { [weak self] result in
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        users = [User]()
        tableView.reloadData()
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
        DatabaseManager.shared.likeAlready(likeUserId: user.id) { liked in
            cell.backgroundColor = liked ? .systemYellow : .systemBackground
            tableView.reloadData()
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let likeUserId = users[indexPath.row].id
        DatabaseManager.shared.sendLikeOrCancelLike(likeUserId: likeUserId) { [weak self] result in
            switch result {
            case .success(let title):
                let alert = UIAlertController(title: title, message: "\(title)しました。", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true)
                
                if title == "マッチ" {
                    DatabaseManager.shared.fetchUser { result in
                        switch result {
                        case .success(let users):
                            self?.users = users
                            tableView.reloadData()
                        case .failure(_):
                            print("マッチした後のエラーだよ")
                        }
                    }
                }
            case .failure(let error):
                print(error)
            }
           
        }
    }
}
