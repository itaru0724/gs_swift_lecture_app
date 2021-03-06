//
//  LoginViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var emalTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emalTextField.delegate = self
        passwordTextField.delegate = self
        
        if UserDefaults.standard.value(forKey: "loggedInUserId") != nil {
            let tabVC = storyboard?.instantiateViewController(identifier: "tabVC") as! TabBarViewController
            tabVC.modalPresentationStyle = .fullScreen
            present(tabVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func didTapLogin(_ sender: Any) {
        guard let email = emalTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] _, error in
            guard error == nil else {return}
            DatabaseManager.shared.getLoggedInUserId(loggedInUserEmail: email) { _ in
                let tabVC = self?.storyboard?.instantiateViewController(identifier: "tabVC") as! TabBarViewController
                tabVC.modalPresentationStyle = .fullScreen
                self?.present(tabVC, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func moveToRegister(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "RegisterVC") as! RegisterViewController
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

extension LoginViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
