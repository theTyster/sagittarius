"""The loop that each worker runs."""

import time


def run_once(queue, worker, handlers, clock=time.monotonic):
    """Claim one job and run its steps. Return the job id, or None if the queue is empty."""
    job_id = queue.claim(worker, clock())
    if job_id is None:
        return None
    try:
        for step in handlers[job_id]:
            step()
            queue.heartbeat(job_id, worker, clock())
    except Exception:
        queue.release(job_id, worker)
        return job_id
    queue.complete(job_id, worker)
    return job_id
