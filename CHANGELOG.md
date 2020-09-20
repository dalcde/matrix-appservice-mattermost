# Unreleased

Bug fixes:

- Don't use username in mattermost email template, since usernames are not
  immutable. Use a random string instead.
- Fix error formatting when failing to connect to mattermost.
- Fix errors when trailing slashes are included in domain names.
- Ensure the randomly generated passwords meet password requirements.
- Use \_ instead of . in random emails, because emails don't allow trailing dots
  are repeated dots.
- Prevent race condition where we try to remove a member from a channel after
  they left the team.
- Mitigate Mattermost bug where joining a channel twice (indirectly triggered
  by default channel joins) returns an error.
- Fix overzealous registration namespace. Restrict to local server only
- Fix a deadlock that prevents the bridge from exiting if there are no channels
  bridged
- Puppets now leave default mattermost channels if they are not in the
  corresponding matrix room.

New features:

- New admin endpoint for user to interact with the bridge. Migrate rename
  script to the admin endpoint
- Add an option to abort bridge if any channel sync fails.
- The bridge notifies systemd when it is initialized
- The dummy -u cli parameter is no longer needed.
- Additional appservice.bind parameter to specify the host the appservice
  binds to
- Add minimal config hot reloading support. Currently only supports reloading
  log levels and some templates

Breaking changes:

- Rename script no longer present

Others:

- Prettify mattermost error messages
- Avoid accessing "private" properties of objects from `matrix-js-sdk`
  libraries in anticipation of typescript port.
- Add integration tests
- Remove `matrix-appservice-bridge` dependency. Use `matrix-js-sdk` directly.
- Automatically generate config file schema from typescript interface
- Log echoed matrix events
- Don't throw errors when mattermost websocket message contains invalid UTF-8

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
