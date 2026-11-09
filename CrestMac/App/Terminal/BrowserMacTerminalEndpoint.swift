import AppKit
import os

/// The commands socket's end in the app: hears each `arma <section> <action>`
/// the helper sends from a person's own terminal and answers it. The socket
/// exists while Crest runs and admits only this Crest's helper running as
/// this user, so a person's own command never needs agents turned on or an
/// agent's approval. Each connection carries one request and gets one answer,
/// which `BrowserMacTerminal` works out.
@MainActor
final class BrowserMacTerminalEndpoint {
    // MARK: - Static Variables

    static let maximumConnections = 8

    private static let otherBuild = "This helper is from another build. Run the one inside the Arma that is open."

    private static let logger = Logger(subsystem: "com.senpaimedia.arma", category: "Terminal")

    // MARK: - Variables

    unowned let application: BrowserMacApplication
    /// Runs `arma <section> <action>`.
    private let terminal: BrowserMacTerminal
    /// Where the helper connects, or nil when this launch offers no socket.
    let path: String?
    /// What a helper must be to be heard: this Crest's own.
    private let helper: BrowserAgentHelperRequirement?
    private var listener: BrowserAgentListener?
    private var connections: [ObjectIdentifier: BrowserAgentConnection] = [:]

    // MARK: - Initializers

    init(application: BrowserMacApplication, windows: BrowserMacWindows) {
        self.application = application
        terminal = BrowserMacTerminal(application: application, windows: windows)
        helper = BrowserAgentHelperRequirement(bundle: .main)
        path =
            helper == nil
            ? nil : Bundle.main.bundleIdentifier.flatMap { AgentSocketLocation.path(forApp: $0, lane: .commands) }
    }

    // MARK: - Actions - Lifecycle

    /// Opens the socket for as long as Crest runs.
    func start() {
        guard listener == nil, let path, let helper else { return }
        let listener = BrowserAgentListener(path: path, helper: helper) { [weak self] connection in
            DispatchQueue.main.async { MainActor.assumeIsolated { self?.admit(connection) } }
        }
        do {
            try listener.start()
            self.listener = listener
        } catch {
            Self.logger.error("The commands socket could not open: \(String(describing: error), privacy: .public)")
        }
    }

    /// Removes the socket and ends every connection, as the app quits.
    func stop() {
        if let listener, !listener.stop() {
            Self.logger.error("The commands socket did not close in time.")
        }
        listener = nil
        for connection in connections.values { connection.close() }
        connections = [:]
    }

    // MARK: - Actions - Connections

    private func admit(_ connection: BrowserAgentConnection) {
        guard listener != nil, connections.count < Self.maximumConnections else {
            connection.close()
            return
        }
        let key = ObjectIdentifier(connection)
        connections[key] = connection
        connection.open { [weak self] line in
            DispatchQueue.main.async { MainActor.assumeIsolated { self?.receive(line, on: key) } }
        } ended: { [weak self] in
            DispatchQueue.main.async { MainActor.assumeIsolated { self?.connections[key] = nil } }
        }
    }

    private func receive(_ line: Data, on key: ObjectIdentifier) {
        guard let connection = connections[key] else { return }
        guard let request = try? JSONDecoder().decode(CommandLinkRequest.self, from: line) else {
            connection.close()
            return
        }
        Task { @MainActor in
            let response: CommandLinkResponse
            switch request {
            case .terminal(let version, let command):
                if version != CommandLinkRequest.version {
                    response = .refused(message: Self.otherBuild)
                } else {
                    do throws(BrowserMacTerminal.Refusal) {
                        response = .output(try await terminal.run(command))
                    } catch {
                        response = .refused(message: error.message)
                    }
                }
            }
            if let answer = try? JSONEncoder().encode(response) { connection.send(answer) }
            connection.close()
        }
    }
}
