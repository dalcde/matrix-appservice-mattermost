# Unreleased

Bug fixes:

- Don't use username in mattermost email template, since usernames are not
  immutable. Use a random string instead.

New features:

- New admin endpoint for user to interact with the bridge. Migrate rename
  script to the admin endpoint
- The bridge notifies systemd when it is initialized

Breaking changes:

- Rename script no longer present

# 0.1.2 (2020-08-25)

Bug fixes:

- Return correct error code when killed
- Don't allow bridging the same channel or room twice

New features:

- Improve error logging by printing stack trace
- Mattermost bot should reject direct messages too
- Leave channels when removed from bridge

Others:

- Code cleanup and use eslint

# 0.1.1 (2020-08-16)

Bug fixes:

- Fix bug where default values of config options are not used; the values are
  left undefined if they are not set

New features:

- Improve configurability of username and display names
- Add script to change mattermost usernames of puppets
- Improve mattermost username sanitization algorithm

# 0.1.0 (2020-08-15)

Initial release. Basic features are present and usable, but not necessarily
stable.
