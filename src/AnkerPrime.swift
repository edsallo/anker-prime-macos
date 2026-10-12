import Cocoa
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var web: WKWebView!
    var backend: Process?
    var inputPipe: Pipe?
    var outputPipe: Pipe?
    var buffer = Data()
    var origin: URL?
    var ready = false
    var quitting = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menu = NSMenu()
        let appItem = NSMenuItem(); menu.addItem(appItem)
        let appMenu = NSMenu(); appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Anker Prime", action: #selector(showAbout), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Anker Prime", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); menu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit"); editItem.submenu = editMenu
        for (title, action, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            editMenu.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        let viewItem = NSMenuItem(); menu.addItem(viewItem)
        let viewMenu = NSMenu(title: "View"); viewItem.submenu = viewMenu
        viewMenu.addItem(withTitle: "Reload", action: #selector(reload), keyEquivalent: "r")
        NSApp.mainMenu = menu
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.userContentController.add(self, name: "appearance")
        config.userContentController.add(self, name: "language")
        config.userContentController.addUserScript(appearanceScript())
        web = WKWebView(frame: .zero, configuration: config)
        web.navigationDelegate = self; web.uiDelegate = self
        web.setValue(false, forKey: "drawsBackground")
        window = NSWindow(contentRect: NSRect(x: 0,y: 0,width: 1160,height: 840),styleMask: [.titled,.closable,.miniaturizable,.resizable],backing: .buffered,defer: false)
        window.title = "Anker Prime"
        window.minSize = NSSize(width: 440,height: 600)
        window.contentView = web
        window.backgroundColor = NSColor(calibratedRed: 0.063,green: 0.086,blue: 0.098,alpha: 1)
        window.center(); window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        web.loadHTMLString("<html><body style='background:#101619;color:#b9f3c1;font:24px -apple-system;padding:60px'>Anker Prime<br><small style='color:#a1adb1'>\(localized("Запуск приложения…", "Starting app…"))</small></body></html>",baseURL: nil)
        launchBackend()
    }
    func localized(_ ru: String, _ en: String) -> String {
        let preference = UserDefaults.standard.string(forKey: "language") ?? "system"
        let language = preference == "system" ? (Locale.preferredLanguages.first ?? "en") : preference
        return language.hasPrefix("ru") ? ru : en
    }
    func appearanceScript() -> WKUserScript {
        let theme = UserDefaults.standard.string(forKey: "appearance") ?? "anker"
        let language = UserDefaults.standard.string(forKey: "language") ?? "system"
        let systemLanguage = (Locale.preferredLanguages.first ?? "en").hasPrefix("ru") ? "ru" : "en"
        return WKUserScript(source: "document.documentElement.dataset.theme='\(theme)';document.documentElement.dataset.language='\(language)';document.documentElement.dataset.systemLanguage='\(systemLanguage)';", injectionTime: .atDocumentStart, forMainFrameOnly: true)
    }
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "language", let value = message.body as? String, ["system","ru","en"].contains(value) {
            UserDefaults.standard.set(value, forKey: "language")
            userContentController.removeAllUserScripts(); userContentController.addUserScript(appearanceScript())
            web.reload()
            return
        }
        guard message.name == "appearance", let theme = message.body as? String, ["anker","mint","ocean","graphite","sand"].contains(theme) else { return }
        UserDefaults.standard.set(theme,forKey: "appearance")
        userContentController.removeAllUserScripts(); userContentController.addUserScript(appearanceScript())
    }
    func launchBackend() {
        do {
            let resources = Bundle.main.resourceURL!
            let directory = try FileManager.default.url(for: .applicationSupportDirectory,in: .userDomainMask,appropriateFor: nil,create: true).appendingPathComponent("Anker Prime",isDirectory: true)
            try FileManager.default.createDirectory(at: directory,withIntermediateDirectories: true,attributes: [.posixPermissions: 0o700])
            let process = Process(); backend = process
            process.executableURL = resources.appendingPathComponent("node")
            process.arguments = [resources.appendingPathComponent("backend/desktop-server.js").path]
            var env = ProcessInfo.processInfo.environment
            env["ANKER_DATA_DIR"] = directory.path; env["TZ"] = TimeZone.current.identifier
            process.environment = env; process.currentDirectoryURL = resources.appendingPathComponent("backend")
            let input = Pipe(), output = Pipe(); inputPipe = input; outputPipe = output
            process.standardInput = input; process.standardOutput = output; process.standardError = FileHandle.nullDevice
            output.fileHandleForReading.readabilityHandler = { [weak self] handle in
                let data = handle.availableData
                if data.isEmpty { handle.readabilityHandler = nil; return }
                DispatchQueue.main.async { self?.receive(data) }
            }
            process.terminationHandler = { [weak self] _ in DispatchQueue.main.async {
                guard let self = self else { return }
                if self.quitting { NSApp.reply(toApplicationShouldTerminate: true) }
                else { self.showFailure(self.localized("Локальная служба остановилась. Закройте приложение и откройте его снова.", "The local service stopped. Quit and reopen the app.")) }
            }}
            try process.run()
            DispatchQueue.main.asyncAfter(deadline: .now()+25) { [weak self] in
                guard let self = self, !self.ready, !self.quitting else { return }
                self.showFailure(self.localized("Не удалось запустить приложение. Закройте его и попробуйте снова.", "Unable to start the app. Quit and try again."))
            }
        } catch { showFailure(localized("Не удалось запустить локальную службу Anker.", "Unable to start the local Anker service.")) }
    }
    func receive(_ data: Data) {
        guard !ready else { return }
        buffer.append(data)
        guard let end = buffer.firstIndex(of: 10) else { return }
        guard let info = try? JSONSerialization.jsonObject(with: buffer.prefix(upTo: end)) as? [String: Any],
              let address = info["origin"] as? String, let token = info["token"] as? String,
              let url = URL(string: address),url.host == "127.0.0.1" else { return }
        ready = true; origin = url; buffer.removeAll()
        var request = URLRequest(url: url)
        request.setValue(token, forHTTPHeaderField: "X-Anker-Desktop-Key")
        web.load(request)
    }
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.scheme == "about" || (url.scheme == origin?.scheme && url.host == origin?.host && url.port == origin?.port) { decisionHandler(.allow) }
        else { if navigationAction.navigationType == .linkActivated && ["https","http"].contains(url.scheme ?? "") { NSWorkspace.shared.open(url) }; decisionHandler(.cancel) }
    }
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url, url.host == origin?.host, url.port == origin?.port { web.load(navigationAction.request) }; return nil
    }
    func showFailure(_ message: String) { let alert = NSAlert(); alert.messageText = "Anker Prime"; alert.informativeText = message; alert.addButton(withTitle: "OK"); alert.runModal() }
    @objc func reload() { if ready { web.reload() } }
    @objc func showAbout() { NSApp.orderFrontStandardAboutPanel(options: [.applicationName:"Anker Prime",.applicationVersion:"1.2.0",.credits:NSAttributedString(string:localized("Автономное управление Anker Prime A2345", "Standalone control for Anker Prime A2345") + "\nCloud • Ports • Timers • Energy • History")]) }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let p = backend,p.isRunning else { return .terminateNow }
        if quitting { return .terminateLater }; quitting = true
        inputPipe?.fileHandleForWriting.closeFile(); p.terminate()
        DispatchQueue.main.asyncAfter(deadline: .now()+8) { NSApp.reply(toApplicationShouldTerminate: true) }
        return .terminateLater
    }
}
let application = NSApplication.shared
let delegate = AppDelegate()
application.delegate = delegate
application.setActivationPolicy(.regular)
application.run()
