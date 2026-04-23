import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        let productVC = ProductViewController()
        let nav = UINavigationController(rootViewController: productVC)
        window.rootViewController = nav
        self.window = window
        window.makeKeyAndVisible()
    }
}
