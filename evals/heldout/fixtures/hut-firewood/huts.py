"""Firewood planning for backcountry huts."""

BUNDLES_PER_PERSON_NIGHT = 0.5


def bundles_needed(people, nights):
    """Firewood bundles to stage at a hut for a party."""
    return round(people * nights * BUNDLES_PER_PERSON_NIGHT)


def stage_plan(parties):
    """parties: list of (hut, people, nights). Returns {hut: bundles}."""
    plan = {}
    for hut, people, nights in parties:
        plan[hut] = plan.get(hut, 0) + bundles_needed(people, nights)
    return plan


if __name__ == "__main__":
    import sys
    people, nights = int(sys.argv[1]), int(sys.argv[2])
    print(bundles_needed(people, nights))
