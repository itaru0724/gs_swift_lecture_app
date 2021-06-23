//
//  MatchListViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/23.
//

import UIKit

class MatchListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

extension MatchListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MatchListCell", for: indexPath)
        cell.textLabel?.text = "Sara Minami"
        return cell
    }
}
