import unittest

from jobs import MAX_ATTEMPTS, TIMEOUT, JobQueue
from worker import run_once


class JobQueueTest(unittest.TestCase):
    def test_claim_and_complete(self):
        q = JobQueue()
        q.submit("j1")
        self.assertEqual(q.claim("w1", 0), "j1")
        self.assertIsNone(q.claim("w2", 1))
        q.complete("j1", "w1")
        self.assertEqual(q.jobs["j1"].state, "done")

    def test_timeout_retries_then_fails(self):
        q = JobQueue()
        q.submit("j1")
        now = 0
        for _ in range(MAX_ATTEMPTS):
            self.assertEqual(q.claim("w1", now), "j1")
            now += TIMEOUT
            q.expire(now)
        self.assertEqual(q.jobs["j1"].state, "failed")

    def test_worker_error_releases_job(self):
        q = JobQueue()
        q.submit("j1")

        def boom():
            raise RuntimeError("disk full")

        run_once(q, "w1", {"j1": [boom]}, clock=lambda: 0)
        self.assertEqual(q.jobs["j1"].state, "queued")
        run_once(q, "w2", {"j1": [lambda: None]}, clock=lambda: 5)
        self.assertEqual(q.jobs["j1"].state, "done")


if __name__ == "__main__":
    unittest.main()
