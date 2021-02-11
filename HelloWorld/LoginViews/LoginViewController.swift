//
//  ViewController.swift
//  HelloWorld
//
//  Created by egamiyuji on 2021/01/09.
//

import UIKit
import ProgressHUD

class LoginViewController: UIViewController {
    
    // MARK: - IBOutlets
    // Labels
    
    @IBOutlet weak var emailLabelOutlet: UILabel!
    @IBOutlet weak var passwordLabelOutlet: UILabel!
    @IBOutlet weak var repeatPasswordLabelOutlet: UILabel!
    @IBOutlet weak var signUpLabelOutlet: UILabel!
    
    // TextFields
    @IBOutlet weak var emailTextFieldOutlet: UITextField!
    @IBOutlet weak var passwordTextFieldOutlet: UITextField!
    @IBOutlet weak var repeatPasswordTextFieldOutlet: UITextField!
    
    // Buttons
    @IBOutlet weak var loginButtonOutlet: UIButton!
    @IBOutlet weak var signUpButtonOutlet: UIButton!
    @IBOutlet weak var resendEmailButtonOutlet: UIButton!
    
    
    // Views
    @IBOutlet weak var repeatPasswordLineViewOutlet: UIView!
    
    // MARK: - Vars
    var isLogin = true
    
    // MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUIFor(login: true)
        setupTextFieldDelegates()
        setupBackgroundTap()
    }
    
    private enum InputFieldType {
        enum Email: String {
            case type = "email"
            case title = "Email"
        }
        
        enum Password: String {
            case type = "password"
            case title = "Password"
        }
        
        enum RepeatPassword: String {
            case type = "repeatPassword"
            case title = "Repeat Password"
        }
    }
    
    private enum Login: String {
        case type = "login"
        case title = "Login"
        case buttonImageName = "loginBtn"
        case bottomLabelText = "Don't have an account?"
    }
    
    private enum Signup: String {
        case type = "signup"
        case title = "Signup"
        case buttonImageName = "registerBtn"
        case bottomLabelText = "Have an account?"
    }

    // MARK: - IBActions
    @IBAction func loginButtonPressed(_ sender: Any) {
        
        let type = isLogin ? Login.type.rawValue : Signup.type.rawValue
        
        if !isDataInputtedFor(type: type) {
            ProgressHUD.showFailed("All fields are required.")
            return
        }
        
        // login or register user
        isLogin ? loginUser() : registerUser()
    }
    
    @IBAction func forgotPasswordButtonPressed(_ sender: Any) {
        if !isDataInputtedFor(type: InputFieldType.Password.type.rawValue) {
            ProgressHUD.showFailed("Email is required.")
            return
        }

        resetPassword()
        print("reset password")
    }
    
    @IBAction func resendEmailButtonPressed(_ sender: Any) {
        if !isDataInputtedFor(type: InputFieldType.Password.type.rawValue) {
            ProgressHUD.showFailed("Email is required.")
            return
        }
        
        resendVerificationEmail()
        print("resend verification email")
    }
    
    @IBAction func signUpButtonPressed(_ sender: UIButton) {
        updateUIFor(login: sender.titleLabel?.text == Login.title.rawValue)
        isLogin.toggle()
    }
    
    
    // MARK: - Setup
    
    private func setupTextFieldDelegates() {
        emailTextFieldOutlet.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        passwordTextFieldOutlet.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        repeatPasswordTextFieldOutlet.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        updatePlaceholderLabels(textField: textField)
    }
    
    private func setupBackgroundTap() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTap))
        
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func backgroundTap() {
        view.endEditing(false)
    }
    
    // MARK: - Animations
    
    private func updateUIFor(login: Bool) {
        let uiImage = UIImage(named: login ? Login.buttonImageName.rawValue: Signup.buttonImageName.rawValue)
        loginButtonOutlet.setImage(uiImage, for: .normal)
        
        signUpButtonOutlet.setTitle(login ? Signup.title.rawValue : Login.title.rawValue, for: .normal)
        
        signUpLabelOutlet.text = login ? Login.bottomLabelText.rawValue : Signup.bottomLabelText.rawValue
        
        UIView.animate(withDuration: 0.5) {
            self.repeatPasswordLabelOutlet.isHidden = login
            self.repeatPasswordTextFieldOutlet.isHidden = login
            self.repeatPasswordLineViewOutlet.isHidden = login
        }
    }
    
    // TODO 修正する
    private func updatePlaceholderLabels(textField: UITextField) {
        switch textField {
        case emailTextFieldOutlet:
            emailLabelOutlet.text = textField.hasText ? InputFieldType.Email.title.rawValue : ""
            
        case passwordTextFieldOutlet:
            passwordLabelOutlet.text = textField.hasText ? InputFieldType.Password.title.rawValue : ""
            
        default:
            repeatPasswordLabelOutlet.text = textField.hasText ? InputFieldType.RepeatPassword.title.rawValue : ""
        }
    }
    
    // MARK: - Helpers
    private func isDataInputtedFor(type: String) -> Bool {
        
        let email = emailTextFieldOutlet.text
        let password = passwordTextFieldOutlet.text
        let repeatPassword = repeatPasswordTextFieldOutlet.text
        
        switch type {
        case Login.type.rawValue:
            return email != "" && password != ""
            
        case Signup.type.rawValue:
            return email != "" && password != "" && repeatPassword != ""

        default:
            return email != ""
        }
    }
    
    private func loginUser() {
        
        let email = emailTextFieldOutlet.text!
        let password = passwordTextFieldOutlet.text!
        
        FirebaseUserListener.shared.loginUserWithEmail(email: email, password: password) { [weak self] (error, isEmailVerified) in
            
            guard let strongSelf = self else { return }
            
            if error != nil {
                ProgressHUD.showFailed(error?.localizedDescription)
                return
            }
            
            if !isEmailVerified {
                strongSelf.resendEmailButtonOutlet.isHidden = false
                ProgressHUD.showFailed("Please verify email.")
                return
            }
            
            strongSelf.goToApp()
        }
    }
    
    private func resetPassword() {
        FirebaseUserListener.shared.resetPasswordFor(email: emailTextFieldOutlet.text!) { error in
            
            if error != nil {
                ProgressHUD.showFailed(error?.localizedDescription)
                return
            }
            
            ProgressHUD.showSuccess("Reset link has been sent.")
        }
    }
    
    private func resendVerificationEmail() {
        FirebaseUserListener.shared.resendVerificationEmail(email: emailTextFieldOutlet.text!) { error in
            
            if error != nil {
                ProgressHUD.showFailed(error?.localizedDescription)
                return
            }
            
            ProgressHUD.showSuccess("New verification email has been sent.")
        }
    }
    
    // MARK: - Navigation
    private func goToApp() {
        
        let mainView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(identifier: "MainView") as! UITabBarController
        
        mainView.modalPresentationStyle = .fullScreen
        present(mainView, animated: true)
    }
    
    private func registerUser() {
        
        let email = emailTextFieldOutlet.text!
        let password = passwordTextFieldOutlet.text!
        let repeatPassword = repeatPasswordTextFieldOutlet.text!
        
        if password != repeatPassword {
            ProgressHUD.showFailed("The passwords don't match.")
            return
        }
        
        FirebaseUserListener.shared.registerUserWith(email: email, password: password) { [weak self] error in
            
            if error != nil {
                ProgressHUD.showFailed(error?.localizedDescription)
                return
            }
            
            ProgressHUD.showSuccess("Verification email has been sent.")
            self?.resendEmailButtonOutlet.isHidden = false
            
        }
    }
    
    
}

