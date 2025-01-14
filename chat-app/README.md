[noats.nz](https://noats.nz)
# Build release
```
export MIX_ENV=prod
mix deps.get
mix compile
mix assets.deploy
mix release
```
# Install
Copy `_build/prod/rel/chat_app` to `/opt/chat-app`.
Generate a SECRET_KEY_BASE.
Create `/etc/systemd/system/chat-app.service` with the contents:
```
[Unit]
Description=Chat App

[Service]
Environment="SECRET_KEY_BASE=snip"
Environment="DATABASE_URL=ecto://postgres@localhost/chat_app_prod"
Environment="NOATS_SSL_KEY_PATH=/etc/letsencrypt/live/noats.nz/privkey.pem"
Environment="NOATS_SSL_CERT_PATH=/etc/letsencrypt/live/noats.nz/fullchain.pem"
ExecStart=/opt/chat-app/bin/server

[Install]
WantedBy=multi-user.target
```
Run:
```
sudo systemctl daemon-reload
sudo systemctl start chat-app
sudo systemctl enable chat-app
```
