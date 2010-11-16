-- Define table(s) used by the Credentials Service provider

-- -------------------------------
-- Address Set
-- -------------------------------

DROP TABLE IF EXISTS address_set CASCADE;

CREATE TABLE address_set (
    id INTEGER NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS addresses CASCADE;

CREATE TABLE addresses (
    fkAddressSetId INTEGER NOT NULL,
    value VARCHAR(255) NOT NULL,
    CONSTRAINT address_to_address_set_fk FOREIGN KEY (fkAddressSetId)
       REFERENCES address_set(id)
) ENGINE=InnoDB;

-- ----------------------------
-- Credentials
-- ----------------------------

DROP TABLE IF EXISTS cred_config CASCADE;

CREATE TABLE cred_config (
    id BIGINT NOT NULL,
    configName VARCHAR(255) NOT NULL,
    priority INTEGER NOT NULL,
    fkAddressSetIdCc INTEGER NOT NULL,
    network VARCHAR(255) NOT NULL,
    theDefault BIT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT credential_config_to_address_set_fk FOREIGN KEY (fkAddressSetIdCc)
       REFERENCES address_set(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS cred_set CASCADE;

CREATE TABLE cred_set (
    id BIGINT NOT NULL,
    credSetName VARCHAR(255) NOT NULL,
    priority INTEGER NOT NULL,
    fkCredentialConfigId BIGINT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT credential_set_to_credential_config_fk FOREIGN KEY (fkCredentialConfigId)
       REFERENCES cred_config(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS device_to_cred_set_mappings CASCADE;

CREATE TABLE device_to_cred_set_mappings (
    id BIGINT NOT NULL,
    device_id INTEGER NOT NULL,
    stale BIT NOT NULL,
    fkCredentialSetId BIGINT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT device_to_credential_set_fk FOREIGN KEY (fkCredentialSetId)
       REFERENCES cred_set(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS creds CASCADE;

CREATE TABLE creds (
    id BIGINT NOT NULL,
    credentialName VARCHAR(255) NOT NULL,
    credentialValue VARCHAR(255) NOT NULL,
    fkCredentialSetId BIGINT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT credential_to_credential_set_fk FOREIGN KEY (fkCredentialSetId)
       REFERENCES cred_set(id)
) ENGINE=InnoDB;
    
-- ----------------------------
-- Protocols
-- ----------------------------

DROP TABLE IF EXISTS protocol_config CASCADE;

CREATE TABLE protocol_config (
    id BIGINT NOT NULL,
    configName VARCHAR(255) NOT NULL,
    priority INTEGER NOT NULL,
    fkAddressSetIdPc INTEGER NOT NULL,
    network VARCHAR(255) NOT NULL,
    theDefault BIT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT protocol_config_to_address_set_fk FOREIGN KEY (fkAddressSetIdPc)
       REFERENCES address_set(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS protocols CASCADE;

CREATE TABLE protocols (
    id BIGINT NOT NULL,
    protocolName VARCHAR(255),
    priority INTEGER NOT NULL,	
    port INTEGER NOT NULL,
    TCP BIT NOT NULL,
    enabled BIT NOT NULL,
    fkProtocolConfigId BIGINT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT protocol_to_protocol_config_fk FOREIGN KEY (fkProtocolConfigId)
       REFERENCES protocol_config(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS protocol_props CASCADE;

CREATE TABLE protocol_props (
    id BIGINT NOT NULL,
    propValue VARCHAR(255) NOT NULL,
    propKey VARCHAR(255) NOT NULL,
    fkProtocolId BIGINT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT protocol_prop_to_protocol_fk FOREIGN KEY (fkProtocolId)
       REFERENCES protocols(id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS device_to_protocol_mappings CASCADE;

CREATE TABLE device_to_protocol_mappings (
    id BIGINT NOT NULL,
    version VARCHAR(255),
    device_id INTEGER NOT NULL,
    stale BIT NOT NULL,
    cipher VARCHAR(255),
    fkProtocolId BIGINT NOT NULL,
    dateCreated TIMESTAMP default CURRENT_TIMESTAMP,
    dateModified TIMESTAMP,
    primary key (id),
    CONSTRAINT device_to_protocol_fk FOREIGN KEY (fkProtocolId)
       REFERENCES protocols(id)
) ENGINE=InnoDB;
