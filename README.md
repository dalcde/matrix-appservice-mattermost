# Matrix ↔ Mattermost bridge

This is a bridge between Matrix and Mattermost using the Application Services
API. This bridge creates a Matrix user for each Mattermost user, and a
Mattermost _user_ for each Matrix user. It uses an actual user instead of a bot
to provide a superior user experience (e.g. consecutive bot messages aren't
grouped).

## Requirements

- Mattermost **5.26.0** and above.

  - This uses the `POST /users/{user_id}/email/verify/member` endpoint to
    verify the emails of puppet users.

- Node **10.16.0**

  - The transitive dependency `matrix-appservice-bridge -> matrix-js-sdk` uses
    `EventEmitter.once`, which was introduced in 10.16.0.

- Matrix
  - A matrix server supporting the Application Services API is needed. No
    attempt has been made to track the minimum supported API version, but it
    should work with any reasonably modern server. It is assumed to be synapse
    in this document.

## Set up

### Installation

1. Clone this repository to a directory.
   ```
   git clone https://github.com/dalcde/matrix-appservice-mattermost
   ```
2. Install dependencies and build
   ```
   npm ci
   npm run build
   ```
3. Copy `config.sample.yaml` to `config.yaml` and edit accordingly
4. Generate registration file

   ```
   node build/index.js -c config.yaml -f registration.yaml -r -u dummy
   ```

   Note that the last argument `dummy` can be arbitrary; The
   `matrix-appservice-bridge` library requires this argument to be supplied, but
   it is not used. The relevant arguments are specified in the config file.

   You should regenerate the registration file every time you update the
   bridge or change your configuration file.

5. Add the path to the registration file to the `app_service_config_files`
   variable in the synapse configuration file. Then restart synapse.
6. Start the bridge by
   ```
   node build/index.js -c config.yaml -f registration.yaml
   ```

## Supported features

- Mattermost -> Matrix:

  - [x] Markdown -> HTML
  - [x] Join/leave
  - [x] Attachments
  - [x] Username Substitutions
  - [x] /me
  - [x] Edits
  - [x] Replies
  - [x] Redaction
  - [ ] Room substitutions (#9)
  - [ ] PMs (#1)
  - [ ] Presence (#8)
  - [ ] Attachment thumbnails (#10)
  - [ ] Correctly indicate remover when removing from channel (#7)
  - [x] Typing notification

- Matrix -> Mattermost:
  - [x] HTML -> Markdown
  - [x] Join/leave
  - [x] Attachments
  - [x] Username Substitutions
  - [x] /me
  - [x] Edits
  - [x] Replies
  - [x] Redaction
  - [ ] Room substitutions (#9)
  - [ ] PMs (#1)
  - [ ] Presence (#8)
  - [ ] Correctly indicate remover when removing from channel (#7)
  - [ ] Customize bridged username (#12)
  - [ ] Typing notification (#11)

## Common errors

- `M_UNKNOWN_TOKEN: Invalid macaroon passed`: Service not registered with
  matrix. Make sure you followed the last three steps of the set up
  instructions carefully. In particular, remember to restart synapse.

## Remarks

### Town Square

By design, every user in a team must join the Town Square room. If a matrix
user joins a matrix room bridged to a mattermost channel, the puppet user would
automatically join Town Square of the corresponding team.

When the user leaves all channels of a team (i.e. all matrix rooms bridged to
such channels), the puppet user would leave the team, hence leave Town Square.

### Post deletion

Mattermost and matrix "group" posts in different ways. For example, when
deleting the root post of a thread in Mattermost, the entire thread is deleted.
Similarly, attachments in Mattermost are part of a text message, whereas in
Matrix they are separate events.

Our implementation is based on the following two principles:

1.  From the point of view of a single platform, the presence of a bridge
    should not affect what happens when a post is deleted.

2.  When a post is deleted on a platform, the contents must not be visible on
    the other platform.

In practice, this means if we delete a message on Matrix, there might be more
posts deleted on Mattermost. These Mattermost deletions will not be reflected
on the matrix side, so there will be more messages on Matrix than on
Mattermost.

Also, Mattermost does not remember who performed the deletion. Thus, on the
matrix side, it is always displayed as the bot user deleting the message.
