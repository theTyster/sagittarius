"""How long the nightly cleanup keeps each kind of stored file, in days."""

RETENTION_DAYS = {
    "thumbnails": 7,
    "exports": 7,
    "invoices": 3650,
}


def days_to_keep(kind):
    return RETENTION_DAYS[kind]
