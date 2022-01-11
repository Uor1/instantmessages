//
//  LoginViewController.swift
//  messengerT
//
//  Created by Ulises Ortega on 30/12/21.
//

import UIKit
import FirebaseAuth
import Firebase
import GoogleSignIn

class LoginViewController: UIViewController {
    
    
    private let scrollView : UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        
        return scrollView
        
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Correo electrónico"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .systemBackground
        
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Contraseña"
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .systemBackground
        field.isSecureTextEntry = true
        
        return field
    }()
    
    private let loginButton : UIButton = {
        let button = UIButton()
        button.setTitle("Iniciar sesión", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        
        return button
    }()
    
    private let googleSignInButton : GIDSignInButton = {
        
        let button = GIDSignInButton()
        button.style = .wide
        button.layer.cornerRadius = 12
        
        
        return button
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "paperplane.fill")?.withTintColor(.link)
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Iniciar sesión"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Registrar",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        googleSignInButton.addTarget(self,
                                     action: #selector(googleSignInButtonTapped),
                                     for: .touchUpInside)
        emailField.delegate = self
        passwordField.delegate = self
        
        
        //Subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(googleSignInButton)

    }
    

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        scrollView.frame = view.bounds
        
        let size = scrollView.width/3
        
        
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                 y: imageView.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        passwordField.frame = CGRect(x: 30,
                                 y: emailField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        loginButton.frame = CGRect(x: 30,
                                 y: passwordField.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
        googleSignInButton.frame = CGRect(x: 30,
                                 y: loginButton.bottom + 10,
                                 width: scrollView.width - 60,
                                 height: 52)
    }
    
    @objc private func googleSignInButtonTapped(){
        print("Boton de google apretado")
        guard let clientID = FirebaseApp.app()?.options.clientID else{return}
        
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            
            if let error = error {
                print("Error al iniciar sesión con google: \(error.localizedDescription)" )
                return
            }
            
            print("Se inició sesión con google: \(user)")
            
            guard let email = user?.profile?.email,
                  let firstName = user?.profile?.givenName,
                  let lastName = user?.profile?.familyName else{
                      return
                  }
            
            DatabaseManager.shared.userExists(with: email, completion: {exists in
                if !exists{
                    //Insert to database
                    DatabaseManager.shared.insertUser(with: ChatAppUser(firstName: firstName,
                                                                        lastName: lastName,
                                                                        emailAdress: email))
                }
            })
            
            guard
                let authentication = user?.authentication,
                let idToken = authentication.idToken
            else {
                print("Error al recibir autenticación o token id de google")
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            
            FirebaseAuth.Auth.auth().signIn(with: credential, completion: {authResult, error in
                guard authResult != nil, error == nil else{
                    print("Error al iniciar sesión con credencial de google")
                    return
                }
                print("Se inició sesión correctamente con credencial de google")
                self.navigationController?.dismiss(animated: true, completion: nil)
            })
            //THIS IS TEST
            
//            Auth.auth().signIn(with: credential) { authResult, error in
//                if let error = error {
//                    let authError = error as NSError
//                    if isMFAEnabled, authError.code == AuthErrorCode.secondFactorRequired.rawValue {
//                        // The user is a multi-factor user. Second factor challenge is required.
//                        let resolver = authError
//                            .userInfo[AuthErrorUserInfoMultiFactorResolverKey] as! MultiFactorResolver
//                        var displayNameString = ""
//                        for tmpFactorInfo in resolver.hints {
//                            displayNameString += tmpFactorInfo.displayName ?? ""
//                            displayNameString += " "
//                        }
//                        self.showTextInputPrompt(
//                            withMessage: "Select factor to sign in\n\(displayNameString)",
//                            completionBlock: { userPressedOK, displayName in
//                                var selectedHint: PhoneMultiFactorInfo?
//                                for tmpFactorInfo in resolver.hints {
//                                    if displayName == tmpFactorInfo.displayName {
//                                        selectedHint = tmpFactorInfo as? PhoneMultiFactorInfo
//                                    }
//                                }
//                                PhoneAuthProvider.provider()
//                                    .verifyPhoneNumber(with: selectedHint!, uiDelegate: nil,
//                                                       multiFactorSession: resolver
//                                                        .session) { verificationID, error in
//                                        if error != nil {
//                                            print(
//                                                "Multi factor start sign in failed. Error: \(error.debugDescription)"
//                                            )
//                                        } else {
//                                            self.showTextInputPrompt(
//                                                withMessage: "Verification code for \(selectedHint?.displayName ?? "")",
//                                                completionBlock: { userPressedOK, verificationCode in
//                                                    let credential: PhoneAuthCredential? = PhoneAuthProvider.provider()
//                                                        .credential(withVerificationID: verificationID!,
//                                                                    verificationCode: verificationCode!)
//                                                    let assertion: MultiFactorAssertion? = PhoneMultiFactorGenerator
//                                                        .assertion(with: credential!)
//                                                    resolver.resolveSignIn(with: assertion!) { authResult, error in
//                                                        if error != nil {
//                                                            print(
//                                                                "Multi factor finanlize sign in failed. Error: \(error.debugDescription)"
//                                                            )
//                                                        } else {
//                                                            self.navigationController?.popViewController(animated: true)
//                                                        }
//                                                    }
//                                                }
//                                            )
//                                        }
//                                    }
//                            }
//                        )
//                    } else {
//                        self.showMessagePrompt(error.localizedDescription)
//                        return
//                    }
//                    // ...
//                    return
//                }
//                // User is signed in
//                // ...
        }
        
        //GIDSignIn.
    }
    
    @objc private func loginButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text, !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        //Firebase Login
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult,error in
            guard let strongSelf = self else{
                return
            }
            guard let result = authResult, error == nil else{
                print("Error al iniciar sesión usuario con correo: \(email)")
                return
            }
            
            let user = result.user
            print("Sesión iniciada, usuario: \(user)")
            
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        })
    }
    
    func alertUserLoginError(){
        let alert = UIAlertController(title: "Error",
                                      message: "Por favor ingresa todos los datos necesarios",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok",
                                      style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc private func didTapRegister(){
        let vc = RegisterViewController()
        vc.title = "Crear cuenta"

        navigationController?.pushViewController(vc, animated: true)
//
        
    }
}

extension LoginViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }else if textField == passwordField {
            loginButtonTapped()
        }
        return true
    }
}

