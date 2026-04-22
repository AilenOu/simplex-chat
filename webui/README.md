# SimpleX Chat WebUI (Docker mode)

This WebUI runs in front of the `simplex-chat` WebSocket API inside one container.

## What it provides

- Browser UI served by Nginx on port `8080`.
- WebSocket proxy at `/ws` to internal `simplex-chat -p 5225`.
- Persistent chat DB files via Docker volume.
- Profile creation, contact list, direct messages, connect-via-link, and contact request actions.

## Notes

- Address sharing works via QR code and the Copy button.
- QR generation is local (`webui/qrcode.min.js`), no external API call is required.

## Quick start

```bash
docker compose -f docker-compose.webui.yml up --build
```

Open:

- `http://localhost:8080`

On first start, create a profile in the WebUI setup screen.

## Data persistence

Data is stored in Docker volume `simplex-webui-data` (mounted at `/var/lib/simplex`).

## Stop

```bash
docker compose -f docker-compose.webui.yml down
```

## Rebuild after changes

```bash
docker compose -f docker-compose.webui.yml up --build --force-recreate
```
