-- Enforce address ownership per network segment. The previous
-- UNIQUE(interface_id, address) shape only prevented the same interface
-- from storing the same address twice.
--
-- IPv6 SLAAC observation persists server-computed addresses into
-- machine_interface_addresses, so the database must enforce "one address
-- owner per segment" as a last-resort invariant instead of relying only on
-- handler logic. Segment-scoped uniqueness also keeps overlapping address
-- spaces legal across different segments, which a global UNIQUE(address)
-- would not.
ALTER TABLE machine_interface_addresses
    ADD COLUMN segment_id uuid;

UPDATE machine_interface_addresses mia
   SET segment_id = mi.segment_id
  FROM machine_interfaces mi
 WHERE mia.interface_id = mi.id;

ALTER TABLE machine_interface_addresses
    ALTER COLUMN segment_id SET NOT NULL;

ALTER TABLE machine_interface_addresses
    ADD CONSTRAINT machine_interface_addresses_segment_id_fkey
    FOREIGN KEY (segment_id) REFERENCES network_segments(id);

ALTER TABLE machine_interface_addresses
    ADD CONSTRAINT machine_interface_addresses_segment_id_address_key
    UNIQUE (segment_id, address);
