//
//  ProfileViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import FirebaseAuth

class ProfileViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.popViewController(animated: false)//Home VCに戻す
    }
    
    @IBAction func didTapLogout(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            try firebaseAuth.signOut()
            UserDefaults.standard.setValue(false, forKey: "isLoggedIn")
            let rootVC = storyboard?.instantiateViewController(identifier: "LoginVC") as! LoginViewController
            let navVC = UINavigationController(rootViewController: rootVC)
            navVC.modalPresentationStyle = .fullScreen
            present(navVC, animated: true, completion: nil)
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
}
