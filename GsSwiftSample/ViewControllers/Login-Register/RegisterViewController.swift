//
//  RegisterViewController.swift
//  GsSwiftSample
//
//  Created by Yuki Shinohara on 2021/06/19.
//

import UIKit
import Photos

class RegisterViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.layer.cornerRadius = 33
        nameTextField.delegate = self
        emailTextField.delegate = self
        passwordTextField.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(imageTapped(_:)))
        profileImageView.addGestureRecognizer(tap)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapRegister(_ sender: Any) {
        guard let name = nameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        else { return }
        DatabaseManager.shared.registerUser(name: name, email: email, password: password, photo: profileImageView.image, completion: { [weak self] result in
            switch result{
            case .success(_):
                DatabaseManager.shared.getLoggedInUserId(loggedInUserEmail: email) { id in
                    UserDefaults.standard.setValue(id, forKey: "loggedInUserId")
                    let tabVC = self?.storyboard?.instantiateViewController(identifier: "tabVC") as! TabBarViewController
                    tabVC.modalPresentationStyle = .fullScreen
                    self?.present(tabVC, animated: true, completion: nil)
                }
            case .failure(let error):
                let alert = UIAlertController(title: "エラー", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    @IBAction func moveToLogin(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func imageTapped(_ gesture: UITapGestureRecognizer){
        if PHPhotoLibrary.authorizationStatus() != .authorized {
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized {
                    self?.chooseProfilePic()
                } else if status == .denied {
                    let alert = UIAlertController(title: "タイトル", message: "メッセージ", preferredStyle: .alert)
                    let settingsAction = UIAlertAction(title: "設定", style: .default, handler: { (_) -> Void in
                        guard let settingsURL = URL(string: UIApplication.openSettingsURLString ) else {
                            return
                        }
                        UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                    })
                    let closeAction: UIAlertAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
                    alert.addAction(settingsAction)
                    alert.addAction(closeAction)
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        } else {
            chooseProfilePic()
        }
    }
    
    func chooseProfilePic(){
        DispatchQueue.main.async {
            let vc = UIImagePickerController()
            vc.sourceType = .photoLibrary
            vc.delegate = self
            vc.allowsEditing = true
            self.present(vc, animated: true)
        }
    }
}

extension RegisterViewController {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {return}
        profileImageView.image = selectedImage
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension RegisterViewController: UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
