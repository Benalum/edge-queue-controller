# Edge Queue Controller

Always-on laptop/Raspberry Pi controller for the AI Platform.
This is like a main node and ai-platform is a worker node.

Current responsibilities:

- Accept jobs into a durable local SQLite queue
- Route jobs by `job_type`
- Check target health
- Forward jobs into the AI Platform protected edge ingest endpoint
- Start target workers over SSH
- Prepare for Wake-on-LAN and Proxmox CT/VM startup

## Local setup

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
cp edge_inventory.example.json edge_inventory.json

Fill in real local values in .env and edge_inventory.json.

Do not commit .env, edge_inventory.json, SQLite databases, or SSH keys.

Run
source .venv/bin/activate
uvicorn edge_controller:app --host 0.0.0.0 --port 7070
Useful endpoints
GET  /health
GET  /routes
GET  /inventory
POST /jobs
GET  /jobs
GET  /queue/summary
POST /tick
POST /wake-test
