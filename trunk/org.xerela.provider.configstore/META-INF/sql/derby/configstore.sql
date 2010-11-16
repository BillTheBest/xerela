-- Define the table(s) for the Config Provider
--

--##############################################################
--#                    Config Tables/Indexes
--##############################################################

CREATE TABLE revisions (
    association_id INTEGER NOT NULL,
    revision BLOB,
    revision_time TIMESTAMP NOT NULL,
    prev_revision_time TIMESTAMP,
    type VARCHAR(1) NOT NULL,
    head SMALLINT NOT NULL DEFAULT 0,
    path VARCHAR(1024) NOT NULL,
    author VARCHAR(60) NOT NULL,
    mime_type VARCHAR(60) NOT NULL DEFAULT 'plain/text',
    size INTEGER NOT NULL,
    crc32 BIGINT NOT NULL,
    CONSTRAINT revisions_pk PRIMARY KEY (association_id, revision_time, path)
);

CREATE INDEX revision_ndx ON revisions (association_id, head, path);
CREATE INDEX prev_revision_ndx ON revisions (association_id, prev_revision_time, path);
