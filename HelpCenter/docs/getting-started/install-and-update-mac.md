---
title: Install and update Arma for Mac
description: Build Arma from source, install it in Applications, and understand automatic updates.
slug: /install-and-update-mac
keywords: [download, install, update, macOS, GitHub Releases, Sparkle]
---

# Install and update Arma for Mac

Arma for Mac requires Apple silicon and macOS 15.2 or later. It runs Chromium and WebKit; see [Chromium and WebKit on Mac](../browsing/engines.md). Arma is a fork of Crest and is not affiliated with Crest or Paul Davis.

## Install the latest Mac release

Download the latest **Installer** disk image from
[Releases](https://github.com/devops-senpai/Arma/releases/latest), open it, and drag
Arma onto **Applications**. Arma for Mac needs Apple silicon and macOS 15.2 or
later.

Arma is signed with a Developer ID and notarized by Apple, so it opens
like any other Mac app.

You can also build it from source as the [repository README](https://github.com/devops-senpai/Arma#build-arma) describes, then move the built app into **Applications**.

Keeping the app in Applications gives macOS and the updater one stable installed location.

## Automatic updates

Arma checks for signed, notarized updates from this repository's GitHub Releases on its own, about once an hour. Everything it learns, an update, none, or an error, shows in the update card at the bottom of the sidebar; choosing **Check for Updates…** while the sidebar is hidden rolls the sidebar out over the page until you click elsewhere. When an update is available, review it, install it, and let Arma relaunch. Your Spaces and browsing data remain in their normal app storage rather than inside the application bundle.

Turn automatic checks and installs on or off in **Settings → About**, which also has **Check for Updates…**. You can also open the app menu and choose **Check for Updates…**, or type `@update` in the command palette. A manual check uses the same signed update channel as the automatic check.

## Update channels

Use **Settings → About** to choose the update channel:

- **Stable** is the normal public release cadence.
- **Nightly** receives newer builds sooner and can change more frequently.
- **Development** follows the latest signed public `main` build and can change several times a day.

Changing channels changes which future update is offered; it does not move or duplicate your profile.

## Updating from an older Arma

The same installer updates older WebKit-only versions and versions that already include Chromium. Your Spaces and browser records stay in place. Chromium and WebKit keep separate website sign-ins, and older WebKit extension installations do not carry over. See [Upgrading from a WebKit-only Arma](../browsing/engines.md#after-updating-from-a-webkit-only-crest) before switching engines.

Arma checks pages for unsaved work before an update restart. Choose **Stay on Page** to keep working, then retry the restart when ready. Updates are offered only when your Mac meets the whole app's macOS requirement.

## iPhone and iPad

_Placeholder: Arma has no iPhone or iPad builds yet._ The shared code compiles for both, so builds can be made from source with Xcode.
