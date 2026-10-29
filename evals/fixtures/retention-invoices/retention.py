"""How long the nightly cleanup keeps each kind of stored file, in days."""

RETENTION_DAYS = {
    "thumbnails": 90,
    "exports": 90,
    "invoices": 3650,
}


def days_to_keep(kind):
    return RETENTION_DAYS[kind]
