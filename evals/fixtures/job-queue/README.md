# Job queue

Workers take jobs from `JobQueue` in `jobs.py` and run them. A job runs on one worker at a time.

- A worker's claim on a job lasts `TIMEOUT` seconds. `heartbeat` renews it.
- A timer calls `expire` every few seconds. A job whose claim ran out goes back in the queue, so
  that another worker can retry it. After `MAX_ATTEMPTS` attempts it fails.
- A worker that hits an error calls `release`, and the job goes back in the queue for a retry.
- `worker.py` is the loop that each worker runs.
