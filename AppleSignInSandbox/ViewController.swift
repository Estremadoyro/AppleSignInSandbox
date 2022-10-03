//
//  ViewController.swift
//  AppleSignInSandbox
//
//  Created by Leonardo  on 2/10/22.
//

import UIKit
import AuthenticationServices

class ViewController: UIViewController {
    private lazy var credentialsStackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 10
        stack.addArrangedSubview(userIdLabel)
        stack.addArrangedSubview(userNameLabel)
        stack.addArrangedSubview(userEmailLabel)
        view.addSubview(stack)
        return stack
    }()

    private lazy var userIdLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()

    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()

    private lazy var userEmailLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 14)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.addArrangedSubview(facebookSignInButton)
        stack.addArrangedSubview(appleSignInButton)
        stack.spacing = 10
        view.addSubview(stack)
        return stack
    }()

    private lazy var facebookSignInButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.systemBlue
        button.setTitle("Sign in with Facebook", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 18
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2
        return button
    }()

    private lazy var appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(appleLogIn), for: .touchUpInside)
        button.layer.cornerRadius = 18
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.borderWidth = 2
        button.layer.masksToBounds = true
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        let userId: String? = try? loadFromKeyChain(tag: "net.estremadoyro.keys.userId") as? String
        print("senku [DEBUG] \(String(describing: type(of: self))) - userId found in Keychain: \(userId ?? "ERROR-NOTHING-FOUND")")
    }
}

extension ViewController {
    func setupUI() {
        view.backgroundColor = .systemGray
        navigationItem.title = "Apple Sign-in"

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.heightAnchor.constraint(equalToConstant: 100),
            stackView.widthAnchor.constraint(equalToConstant: 220),

            // Credentialls stack
            credentialsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            credentialsStackView.heightAnchor.constraint(equalToConstant: 100),
            credentialsStackView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }

    @objc
    func appleLogIn() {
        // Create a request
        let appleAuthorizationProvider = ASAuthorizationAppleIDProvider()
        let request = appleAuthorizationProvider.createRequest()
        // Request for user name, email
        request.requestedScopes = [.fullName, .email]
        // Check if is signed in with Apple, if not sends an alert asking the user to sign in with their Apple Id

        // Add ASAuthorizationPasswordProvider in Authorization requests to check if there are credentials already (User already has account), otherwise the didCompleteWithAuthorization delegate will never reach the ASPasswordCredential flow
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
        
        // TODO: Add modal for logging in and main screen for logged users
        // TODO: Can also check at start of the app (didFinishLaunchingWithOptions delegate)
        // TODO: If the keychain reference is there (UserId) then user can still log in
    }
}

extension ViewController: ASAuthorizationControllerDelegate {
    // - Save data to keychain when user logs in
    // - Delete data from keychain when user logs out (todo)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        print("senku [DEBUG] \(String(describing: type(of: self))) - User authenticated successfully")
        // Handle the user credentials
        switch authorization.credential {
            case let appleIdCredential as ASAuthorizationAppleIDCredential:
                // Create account in system
                let userId: String? = appleIdCredential.user
                let name: String?   = appleIdCredential.fullName?.familyName
                let email: String?  = appleIdCredential.email

                // Storing in keychain (For example purposes only)
                try? saveToKeyChain(secret: userId)

                // Show info in view (For example purposes only)
                DispatchQueue.main.async { [weak self] in
                    guard let strongSelf = self else { return }
                    strongSelf.userIdLabel.text = "Id: \(userId ?? "") -"
                    strongSelf.userNameLabel.text = "Name: \(name ?? "") -"
                    strongSelf.userEmailLabel.text = "Email: \(email ?? "") -"
                }

            case let passwordCredential as ASPasswordCredential:
                // Sign in using an existing iCloud keychain credential
                let username = passwordCredential.user
                let password = passwordCredential.password
                let alert = UIAlertController(title: "Log-in (iCloud) ", message: "Signed in with iCloud | username: \(username) | password: \(password)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel))
                alert.present(self, animated: true)

            default: break
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("senku [DEBUG] \(String(describing: type(of: self))) - Error authenticating: \(error)")
    }
}

extension ViewController: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
}

// MARK: - Keychain storage
extension ViewController {
    func saveToKeyChain(secret: String?) throws {
        // kSec = Keychain Secret
        guard let key = secret else { throw KeyChainError.errorNoSecretProvided }
        let tag: Data = "net.estremadoyro.keys.userId".data(using: .utf8)!
        let addQuery: [String: Any] = [kSecClass as String: kSecClassKey,     /// kSec class is ClassKey -> Indicates a Key item (Instead of certificate, identity or pass.)
                                       kSecAttrApplicationTag as String: tag, /// kSec tag -> Distinguish among others
                                       kSecValueRef as String: key]           /// kSec the actual secret/value
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeyChainError.errorAddingItem }
        print("senku [DEBUG] \(String(describing: type(of: self))) - Success saving element into keychain")
    }

    func loadFromKeyChain(tag: String) throws -> SecKey?  {
        let getQuery: [String: Any] = [kSecClass as String: kSecClassKey,              /// The type, Key item
                                       kSecAttrApplicationTag as String: tag,          /// Used to find the key reference
                                       kSecAttrKeyType as String: kSecAttrKeyTypeRSA, /// The key should be of type RSA alg.
                                       kSecValueRef as String: true]                   /// It should return a key reference rather than the key's data itself

        // Returns the key reference by assigning it to our reference (That doesn't point to anything yet)
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        guard status == errSecSuccess else { throw KeyChainError.errorRetrivingKeyReference }

        // Send key reference
        let key = item as! SecKey // You can use it for Cryptographic operations.
        return key
    }
}

enum KeyChainError: String, Error {
    case errorAddingItem = "Error adding the item"
    case errorRetrivingKeyReference = "Error retriving the Key's reference"
    case errorNoSecretProvided = "Error no secret was provided to save"
}
