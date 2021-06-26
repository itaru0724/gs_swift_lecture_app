//
//  MatchListViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/23.
//

import UIKit

class MatchListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    var users = [User]()
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DatabaseManager.shared.fetchMatchUser { [weak self] result in
            switch result {
            case .success(let users):
                self?.users = users
                self?.tableView.reloadData()
            case .failure(_):
                print("MatchListVCerror")
            }
        }
    }
    
}

extension MatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = users[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchListCell", for: indexPath)
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
        let likeUser = users[indexPath.row]
        let vc = storyboard?.instantiateViewController(withIdentifier: "ChatVC") as! ChatViewController
        vc.likeUser = likeUser
        DatabaseManager.shared.getMatchId(likeUserId: likeUser.id) { id in
            vc.matchId = id
            self.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
}
