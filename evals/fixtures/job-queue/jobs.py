"""The job queue. Times are seconds, passed in by the caller (the worker loop or the timer)."""

TIMEOUT = 30
MAX_ATTEMPTS = 3


class Job:
    def __init__(self, job_id):
        self.id = job_id
        self.state = "queued"  # queued, running, done, failed
        self.attempts = 0
        self.worker = None
        self.deadline = None


class JobQueue:
    def __init__(self):
        self.jobs = {}

    def submit(self, job_id):
        self.jobs[job_id] = Job(job_id)

    def claim(self, worker, now):
        """Give the worker the first queued job and return its id, or None."""
        for job in self.jobs.values():
            if job.state == "queued":
                job.state = "running"
                job.attempts += 1
                job.worker = worker
                job.deadline = now + TIMEOUT
                return job.id
        return None

    def heartbeat(self, job_id, worker, now):
        """The worker is still on the job: renew its claim."""
        job = self.jobs[job_id]
        job.deadline = now + TIMEOUT

    def complete(self, job_id, worker):
        job = self.jobs[job_id]
        job.state = "done"
        job.worker = None

    def release(self, job_id, worker):
        """The worker hit an error: put the job back for a retry."""
        job = self.jobs[job_id]
        job.state = "queued" if job.attempts < MAX_ATTEMPTS else "failed"
        job.worker = None

    def expire(self, now):
        """The timer: put back each running job whose claim ran out."""
        for job in self.jobs.values():
            if job.state == "running" and now >= job.deadline:
                job.state = "queued" if job.attempts < MAX_ATTEMPTS else "failed"
                job.worker = None
