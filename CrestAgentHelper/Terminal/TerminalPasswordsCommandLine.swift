import Foundation

/// `arma passwords`.
enum TerminalPasswordsCommandLine: TerminalSection {
    static let name = "passwords"
    static let summary = "Unlock a Space's saved passwords for an hour, then list, read, add, change or delete them"
    static let switches: Set<String> = [
        "all", "raw", "generate", "password-stdin", "subdomains", "no-subdomains", "no-lowercase", "no-uppercase",
        "no-numbers", "no-symbols",
    ]
    static let usage = """
        usage: arma passwords <action> [options]

          unlock [--space <s>] [--minutes <n>] [--raw]
                                   unlock a Space's passwords for the terminal, with Touch ID
                                   or your Mac password, for an hour (or fewer minutes); prints
                                   export ARMA_SESSION="...", or the key alone with --raw
          lock [--all]             end this session, or every session
          status                   which Spaces allow the terminal, and this session
          list [--search <q>] [--site <host>] [--category <c>]
                                   the session's passwords, without their secrets
          get password|username|email|notes|item <site|id> [--username <u>]
                                   one field of a saved password, or all of it with item
          create <site> --username <u> (--password-stdin | --generate)
                 [--email <e>] [--category <c>] [--subdomains] [--notes-file <path>]
                                   save a new password
          edit <site|id> [--username <u>] [--new-username <u>] [--email <e>] [--category <c>]
               [--subdomains | --no-subdomains] [--password-stdin | --generate] [--notes-file <path>]
                                   change a saved password
          delete <site|id> [--username <u>]
                                   delete a saved password
          generate [--length <n>] [--no-lowercase] [--no-uppercase] [--no-numbers] [--no-symbols]
                                   make a password with the Space's generator; no session needed

        Every action but unlock, status and generate needs a session: run
        eval "$(arma passwords unlock --space Work)" and the key is kept in
        ARMA_SESSION for this shell, or pass --session <key>. A session reaches one
        Space and lasts an hour at most; it ends sooner with lock, when Arma quits,
        or when the Mac sleeps or locks. The Space must allow it: Settings › Space ›
        Passwords › Allow command-line access.

        A password is read from standard input with --password-stdin, never from the
        command's words, so it stays out of your shell's history.

        """

    static func command(action: String, _ arguments: inout TerminalArguments) throws(TerminalArguments.Problem)
        -> TerminalCommand
    {
        let session = arguments.option("session") ?? ProcessInfo.processInfo.environment["ARMA_SESSION"]
        switch action {
        case "unlock", "login":
            let minutes = try arguments.number("minutes").map { Int($0) }
            return .passwords(.unlock(space: arguments.option("space"), minutes: minutes, raw: arguments.has("raw")))
        case "lock", "logout":
            return .passwords(.lock(session: session, all: arguments.has("all")))
        case "status":
            return .passwords(.status(session: session))
        case "list", "ls":
            return .passwords(
                .list(
                    session: session, search: arguments.option("search"), site: arguments.option("site"),
                    category: arguments.option("category")))
        case "get":
            let field = try TerminalArguments.choice(
                try arguments.take("password, username, email, notes or item"), as: TerminalPasswordField.self,
                for: "The field")
            return .passwords(
                .get(
                    session: session, field: field, item: try arguments.take("a site or id"),
                    username: arguments.option("username")))
        case "create", "add":
            var account = try changes(&arguments, newUsername: "username")
            account.site = try arguments.take("a site")
            guard account.username != nil else { throw TerminalArguments.Problem(message: "Give --username.") }
            guard account.password != nil else {
                throw TerminalArguments.Problem(message: "Give --password-stdin or --generate.")
            }
            return .passwords(.create(session: session, account: account))
        case "edit":
            let item = try arguments.take("a site or id")
            return .passwords(
                .edit(
                    session: session, item: item, username: arguments.option("username"),
                    changes: try changes(&arguments, newUsername: "new-username")))
        case "delete", "rm":
            return .passwords(
                .delete(
                    session: session, item: try arguments.take("a site or id"), username: arguments.option("username")))
        case "generate":
            return .passwords(.generate(generation: try generation(arguments)))
        default:
            throw TerminalArguments.Problem(message: "arma passwords has no action '\(action)'.")
        }
    }

    // MARK: - Actions - Reading

    /// What `create` saves or `edit` changes, from the options; the
    /// password from standard input or the generator, and the notes from a
    /// file.
    private static func changes(_ arguments: inout TerminalArguments, newUsername: String) throws(TerminalArguments
        .Problem) -> TerminalPasswordAccount
    {
        var account = TerminalPasswordAccount()
        account.username = arguments.option(newUsername)
        account.email = arguments.option("email")
        account.category = arguments.option("category")
        if arguments.has("subdomains") { account.includesSubdomains = true }
        if arguments.has("no-subdomains") { account.includesSubdomains = false }
        if arguments.has("password-stdin") {
            account.password = .given(try readPassword())
        } else if arguments.has("generate") {
            account.password = .generated(try generation(arguments))
        }
        if let path = arguments.option("notes-file") {
            guard let notes = try? String(contentsOfFile: (path as NSString).expandingTildeInPath, encoding: .utf8)
            else { throw TerminalArguments.Problem(message: "Can't read the notes file '\(path)'.") }
            account.notes = notes
        }
        return account
    }

    private static func generation(_ arguments: TerminalArguments) throws(TerminalArguments.Problem)
        -> TerminalPasswordGeneration
    {
        var generation = TerminalPasswordGeneration()
        generation.length = try arguments.number("length").map { Int($0) }
        if arguments.has("no-lowercase") { generation.lowercase = false }
        if arguments.has("no-uppercase") { generation.uppercase = false }
        if arguments.has("no-numbers") { generation.numbers = false }
        if arguments.has("no-symbols") { generation.symbols = false }
        return generation
    }

    /// The password on standard input, without the newline that ends it.
    private static func readPassword() throws(TerminalArguments.Problem) -> String {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard var password = String(data: data, encoding: .utf8) else {
            throw TerminalArguments.Problem(message: "The password on standard input isn't text.")
        }
        while password.hasSuffix("\n") || password.hasSuffix("\r") { password.removeLast() }
        guard !password.isEmpty else { throw TerminalArguments.Problem(message: "Standard input held no password.") }
        return password
    }
}
