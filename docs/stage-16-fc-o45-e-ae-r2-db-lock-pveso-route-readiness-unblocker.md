# Stage 16 FC-O45-E-AE-R2 — DB Lock + PVESO Route Readiness Unblocker

Date: 2026-06-24

Repo checkpoint before this phase:

- Expected HEAD/origin/main: `c078962`
- Prior tag: `controller-stage-16-fc-o45-e-ae-worker-model-readiness-preflight-2026-06-24`

## Why this phase exists

FC-O45-E-AE completed as a repo checkpoint but surfaced two readiness blockers:

1. CT203 SQLite read-only inventory returned `integrity_check=ok`, then later inventory queries hit `database is locked`.
2. The PPB laptop could not resolve hostname `pveso`, so PVESO/CT101 readiness was not proven from that route.

Because of those blockers, this phase does **not** proceed to the worker/model proof.

## Scope

Allowed:

- Read-only CT203 DB lock-holder and read-query posture inspection.
- Read-only controller/worker/timer service posture inspection.
- Read-only laptop/PVEW/PVESO route and hostname posture inspection.
- Read-only PVESO/CT101 status inspection if reachable through PVEW.
- Repo documentation, focused smoke, commit, tag, and push.

Explicitly not allowed and not performed:

- NO DB write.
- NO job mutation.
- NO result insert.
- NO backend/frontend deploy.
- NO service restart/reload/start/stop/enable/disable.
- NO scheduler/timer activation.
- NO persistent worker activation.
- NO worker/helper/model/Ollama API call.
- NO model generation.
- NO CT/VM restart.
- NO nginx/cloudflared/storage mutation.
- NO file deletion.

## Decision rule carried forward

Do not run `FC-O45-E-AF` model proof until the read-only output below shows:

- CT203 DB query posture is usable, or any lock holder is understood and safe.
- PVESO is reachable through a stable route, preferably PVEW-mediated if laptop DNS remains unreliable.
- Scheduler/timers/persistent workers are still disabled/inactive.
- The next command has explicit approval for exact one-job DB/job/model/runtime activity.

## Live read-only output

```
=== Stage 16 FC-O45-E-AE-R2 DB lock + PVESO route readiness unblocker ===
MUTATION_SCOPE=read_only_lock_route_inventory_plus_repo_doc_smoke_commit_tag_push
NO DB write
NO job mutation
NO result insert
NO backend/frontend deploy
NO service restart/reload/start/stop/enable/disable
NO scheduler/timer activation
NO persistent worker activation
NO worker/helper/model/Ollama API call
NO model generation
NO CT/VM restart
NO nginx/cloudflared/storage mutation
NO file deletion

=== git preflight ===
From https://github.com/Benalum/edge-queue-controller
 * branch            main       -> FETCH_HEAD
expected_head=c078962
head_now=c078962
origin_main_now=c078962
git_preflight=PASS

=== local PVESO name-resolution hints, read-only ===
alex-Latitude-3540
<redacted-tailscale-ip>   llms                alexhartel179@  linux  -                       
<redacted-tailscale-ip>   pveso               alexhartel179@  linux  -                       
<redacted-tailscale-ip>   pvew                alexhartel179@  linux  idle, tx 11076 rx 9452  

=== PVEW-mediated CT203 DB lock/readiness diagnosis, read-only ===
--- pvew basic posture ---
pvew
2026-06-24T22:49:49Z
status: running
status: stopped
status: running

--- pvew route/name hints for pveso, read-only ---
<redacted-tailscale-ip>   pveso.tail40a52f.ts.net
<redacted-tailscale-ip>   pvew                alexhartel179@  linux  -                                                      
<redacted-tailscale-ip>   llms                alexhartel179@  linux  -                                                      
<redacted-tailscale-ip>   pveso               alexhartel179@  linux  -                                                      

--- pvew to pveso ssh posture, read-only, no service changes ---
pveso_ssh=PASS
pveso
2026-06-24T22:49:51Z
 13:49:51 up 4 days,  6:55,  1 user,  load average: 0.00, 0.00, 0.00

ollama service/socket posture only; no Ollama API
active
enabled
State  Recv-Q Send-Q               Local Address:Port  Peer Address:PortProcess                                                                                                                                           
LISTEN 0      4096                     127.0.0.1:11434      0.0.0.0:*    users:(("ollama",pid=339134,fd=3))                                                                                                               

ct101 status/config only
status: running
cores: 20
features: keyctl=1,nesting=1
memory: 31943
onboot: 0
ostype: ubuntu
swap: 2048

worker/docker unit posture only
dev-mqueue.mount                             static          -
mnt-ollama\x2dstorage.mount                  generated       -
ollama.service                               enabled         enabled
  ollama.service                                                                            loaded    active   running Ollama Service
  systemd-fsck@dev-data\x2d2tb-ollama\x2dlv.service                                         loaded    active   exited  File System Check on /dev/data-2tb/ollama-lv
pvew_to_pveso_read_only_ssh=PASS

--- ct203 DB lock holder and query posture, read-only ---
hostname=edge-controller-pvew
date_utc=2026-06-24T22:49:53Z
db_path=/var/lib/edge-queue-controller/edge_queue.sqlite3
-rw------- 1 root root 42M Jun 24 22:49 /var/lib/edge-queue-controller/edge_queue.sqlite3

controller process posture
  13158       1 Ssl     01:11:54 /opt/edge-queue-controller/venv/bin/python -m uvicorn edge_controller:app --host 0.0.0.0 --port 7070 --log-level info

db fd holders via fuser/lsof/find-proc-fd, read-only
COMMAND   PID USER  FD   TYPE DEVICE SIZE/OFF NODE NAME
python  13158 root  13u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  16u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  17u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  18u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  19u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  20u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  21u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  22u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  23u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  24u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  25u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  26u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  27u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  28u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  29u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  30u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  31u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  32u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  33u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  34u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  35u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  36u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  37u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  38u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  39u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  40u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  41u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  42u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  43u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  44u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  45u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  46u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  47u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  48u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  49u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  50u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  51u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  52u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  53u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  54u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  55u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  56u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  57u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  58u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  59u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  60u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  61u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  62u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  63u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  64u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  66u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  67u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  68u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root  69u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 104u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 143u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 144u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 146u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 147u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 148u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 149u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 151u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 152u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 153u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 155u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 157u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 158u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 159u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 160u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 161u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 162u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 163u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 164u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 165u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 166u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 167u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 169u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 170u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 171u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 172u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 173u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 174u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 175u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 176u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 177u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 178u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 179u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 180u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 181u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 182u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 183u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 184u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 185u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 186u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 187u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 188u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 189u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 190u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 191u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 192u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 193u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 194u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 195u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 196u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 197u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 198u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 199u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 200u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 201u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 202u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 203u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 205u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 206u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 207u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
python  13158 root 208u   REG  252,7 43876352 6797 /var/lib/edge-queue-controller/edge_queue.sqlite3
proc_fd_holder_pid=13158 cmd=/opt/edge-queue-controller/venv/bin/python -m uvicorn edge_controller:app --host 0.0.0.0 --port 7070 --log-level info 

systemd queue/controller/timer posture only
  edge-queue-controller.service                loaded    active   running AI Platform Control CT203 Edge Queue Controller
Thu 2026-06-25 00:00:00 UTC 1h 10min Wed 2026-06-24 00:00:26 UTC      22h ago dpkg-db-backup.timer         dpkg-db-backup.service
Thu 2026-06-25 00:45:56 UTC 1h 56min Wed 2026-06-24 00:40:26 UTC      22h ago logrotate.timer              logrotate.service
Thu 2026-06-25 01:15:34 UTC 2h 25min Wed 2026-06-24 11:05:26 UTC      11h ago man-db.timer                 man-db.service
Thu 2026-06-25 01:30:32 UTC 2h 40min Wed 2026-06-24 06:53:26 UTC      15h ago apt-daily.timer              apt-daily.service
Thu 2026-06-25 06:53:32 UTC       8h Wed 2026-06-24 06:34:26 UTC      16h ago apt-daily-upgrade.timer      apt-daily-upgrade.service
Thu 2026-06-25 20:03:39 UTC      21h Wed 2026-06-24 20:03:39 UTC 2h 46min ago systemd-tmpfiles-clean.timer systemd-tmpfiles-clean.service
Sun 2026-06-28 03:10:29 UTC   3 days Sun 2026-06-21 03:11:26 UTC   3 days ago e2scrub_all.timer            e2scrub_all.service
Wed 2026-07-01 00:02:33 UTC   6 days Thu 2026-06-18 16:55:24 UTC            - wtmpdb-rotate.timer          wtmpdb-rotate.service
-                                  - -                                      - fstrim.timer                 fstrim.service
9 timers listed.

sqlite read-only retry with busy timeout
integrity_check
---------------
ok             
section         status     count
--------------  ---------  -----
jobs_by_status  completed  64   
jobs_by_status  failed     3    
jobs_by_status  forwarded  18   
jobs_by_status  queued     26   
jobs_by_status  running    10   
section                id   user_id  status     job_type        requested_model  attempts  created_at                        updated_at                      
---------------------  ---  -------  ---------  --------------  ---------------  --------  --------------------------------  --------------------------------
recent_companion_jobs  126  16       completed  companion.chat  mock/no-model    0         2026-06-24T22:31:58.445392+00:00  2026-06-24T22:34:56Z            
recent_companion_jobs  125  16       completed  companion.chat  mock/no-model    0         2026-06-24T22:00:53.760211+00:00  2026-06-24T22:04:39Z            
recent_companion_jobs  124  16       completed  companion.chat  mock/no-model    0         2026-06-24T18:19:19.431330+00:00  2026-06-24T18:35:54.132393+00:00
recent_companion_jobs  123  16       failed     companion.chat  mock/no-model    0         2026-06-24T16:05:04.713762+00:00  2026-06-24T18:14:29.053942+00:00
recent_companion_jobs  24   16       queued     companion.chat  mock/no-model    0         2026-06-20T05:02:17.068028+00:00  2026-06-20T05:02:17.068028+00:00
section                         job_id  status     requested_model  result_rows
------------------------------  ------  ---------  ---------------  -----------
recent_companion_result_counts  126     completed  mock/no-model    1          
recent_companion_result_counts  125     completed  mock/no-model    1          
recent_companion_result_counts  124     completed  mock/no-model    1          
recent_companion_result_counts  123     failed     mock/no-model    0          
recent_companion_result_counts  24      queued     mock/no-model    0          
section             id   user_id  status     job_type        requested_model  attempts  result_rows
------------------  ---  -------  ---------  --------------  ---------------  --------  -----------
job126_final_check  126  16       completed  companion.chat  mock/no-model    0         1          
sqlite_readonly_retry_exit_code=0
pvew_mediated_read_only_diagnosis=PASS

=== AE-R2 conclusion ===
This phase only diagnoses the blockers from AE.
Proceed to model proof only if:
1. CT203 read-only DB queries succeed or lock holders are clearly benign/idle.
2. PVESO is reachable through a known-safe route.
3. Scheduler/timers/persistent workers remain inactive.
4. The next phase has explicit approval for the exact DB/job/model/runtime mutations.
```
