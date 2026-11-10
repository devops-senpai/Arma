---
title: Turn Arma Passwords on or off per Space
description: Control Arma-owned password suggestions, generation, and save prompts independently for every Space.
slug: /crest-passwords-per-space
sidebar_label: Arma Passwords
sidebar_position: 6
keywords: [Arma Passwords, password settings, Space, Keychain, turn off]
---

# Turn Arma Passwords on or off per Space

Arma Passwords are private to the Space that owns them. You can stop using Arma-owned suggestions, generation, and save prompts in one Space without deleting its saved passwords or changing another Space. The Spaces of a [Sub-Space](./sub-spaces.md) group share one set of passwords and these settings.

## Change the setting

On Mac:

1. Open **Arma Settings** and select the Space in the sidebar.
2. Select **Passwords**.
3. Turn **Use Arma Passwords** on or off.

On iPhone and iPad:

1. Open **Settings → Passwords**.
2. Choose the Space you want to change from the **Space** menu.
3. Turn **Use Arma Passwords** on or off.

When Arma Passwords is off, saved passwords remain in that Space until you delete them. Turning the setting back on makes them available to matching sites again.

## Related controls

The same page lists the Space’s saved passwords, with **Import Passwords…** and **Export Passwords…**. When Arma Passwords is on, supported Mac builds can also show:

- **Sync with iCloud Keychain**, which updates whether existing and future Arma credentials in that Space synchronize through the system Keychain.
- **Offer a copy to Passwords**, which lets the system Passwords app ask separately for a copy after Arma saves in the Space.

## Saved passwords, notes and categories

**Add Password…** keeps a password for a website, and selecting a saved password edits it, after you authenticate:

- **Include subdomains** lets the password fill every address under its site, such as `mail.example.com` under `example.com`. Arma never includes the subdomains of a public suffix such as `github.io`, whose subdomains belong to different people.
- **Category** files the password under a name you choose, or **New Category…**. Search finds passwords by category or email, and in the command palette `@passwords` and a category name finds that category's logins.
- **Email** and up to 2 KB of **Notes**, such as recovery codes, are kept in the Keychain with the password and sync with iCloud Keychain when the password does.

In a page's site controls, **Manage Passwords** opens the Space's saved passwords for the site, or a new password for it when there is none. **Pause Passwords on This Tab** stops Arma's suggestions and save prompt on that tab, for when another password manager should have it: until you resume them, or for 1, 2, 5, 10 or 30 minutes, 1 hour or 24 hours, and you can resume them sooner. A new tab offers them again. Closing a suggestion or the save prompt keeps them away for 3 seconds and asks, at the top right, whether to pause them on the tab. In the command palette, `@passwords` pauses or resumes them on the tab on screen.

The suggestions appear under the field you click, the username or email field as well as the password field.

**Never Save Passwords On**, at the bottom of the page, lists the websites the Save password? prompt never appears on, each with **Include subdomains**; saved passwords still fill there.

**Generate**, when you add or edit a password, makes one 16 characters long from every kind of character, or to the length and kinds you choose, hidden until you reveal or copy it. On a sign-up page, the password field offers a strong password instead of saved ones; its **Options** change the length and kinds of character for that password. **Suggest passwords in private windows** lets private windows offer this Space's passwords; private windows never save one.

## When Arma offers to save

The password bubble under a login field appears only when the Space has a password for the site. After you sign in, the Save password? prompt appears at the top right of the page: correct the username or password, add an email, category or notes, keep or clear **Include subdomains**, then choose **Save** or **Never for This Site**. Once you start typing in it, it waits for you. A sign-in that asks for the username first and the password on a later page, even on another subdomain of the same site, is saved as one account.

## From the terminal

Turn on **Allow command-line access** under **Arma Passwords** on the Space's Passwords page; Arma asks you to authenticate first. Then `arma passwords unlock --space <name>` asks for Touch ID or your Mac password and opens that Space for an hour at most (`--minutes` for less). Run it as `eval "$(arma passwords unlock --space Work)"` to keep the session in `ARMA_SESSION`. The session ends with `arma passwords lock`, when Arma quits, or when the Mac sleeps or locks, and the page lists open sessions under it with **End**. With a session you can `list`, `get`, `create`, `edit` and `delete` passwords; a password is read from standard input with `--password-stdin` or made with `--generate`, never typed on the command line. `arma passwords generate` needs no session. Run `arma passwords help` for every option.

System Passwords and passkeys are provider-managed and may appear in any Space for a matching site. They are separate from Arma Passwords’ Space-local records. On Mac, check Arma’s access to system passkeys in **Settings → Privacy → System permissions → Passkeys**.

:::info What turning it off does not do
It does not delete saved passwords, export them, move them to another Space, or place password values in CloudKit session data.
:::

Private Spaces must be unlocked before Arma reveals account and site metadata or changes their password settings.
