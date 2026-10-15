-- Additive, repeatable migration for mutual report claims and message unsend.
-- Run after schema.sql and migrations/001_multi_user_interaction.sql.

SET @has_claimant_email = (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'reports'
    AND column_name = 'claimant_email'
);
SET @add_claimant_email = IF(
  @has_claimant_email = 0,
  'ALTER TABLE reports ADD COLUMN claimant_email VARCHAR(120) NULL AFTER user_email',
  'SELECT 1'
);
PREPARE add_claimant_email_statement FROM @add_claimant_email;
EXECUTE add_claimant_email_statement;
DEALLOCATE PREPARE add_claimant_email_statement;

SET @has_claimant_fk = (
  SELECT COUNT(*) FROM information_schema.table_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'reports'
    AND constraint_name = 'fk_reports_claimant'
);
SET @add_claimant_fk = IF(
  @has_claimant_fk = 0,
  'ALTER TABLE reports ADD CONSTRAINT fk_reports_claimant FOREIGN KEY (claimant_email) REFERENCES users(email) ON DELETE SET NULL ON UPDATE CASCADE',
  'SELECT 1'
);
PREPARE add_claimant_fk_statement FROM @add_claimant_fk;
EXECUTE add_claimant_fk_statement;
DEALLOCATE PREPARE add_claimant_fk_statement;

SET @has_message_id = (
  SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'notifications'
    AND column_name = 'message_id'
);
SET @add_message_id = IF(
  @has_message_id = 0,
  'ALTER TABLE notifications ADD COLUMN message_id BIGINT UNSIGNED NULL AFTER chat_id',
  'SELECT 1'
);
PREPARE add_message_id_statement FROM @add_message_id;
EXECUTE add_message_id_statement;
DEALLOCATE PREPARE add_message_id_statement;

SET @has_message_id_index = (
  SELECT COUNT(*) FROM information_schema.statistics
  WHERE table_schema = DATABASE()
    AND table_name = 'notifications'
    AND index_name = 'idx_notifications_message_id'
);
SET @add_message_id_index = IF(
  @has_message_id_index = 0,
  'ALTER TABLE notifications ADD INDEX idx_notifications_message_id (message_id)',
  'SELECT 1'
);
PREPARE add_message_id_index_statement FROM @add_message_id_index;
EXECUTE add_message_id_index_statement;
DEALLOCATE PREPARE add_message_id_index_statement;

SET @has_message_fk = (
  SELECT COUNT(*) FROM information_schema.table_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'notifications'
    AND constraint_name = 'fk_notifications_message'
);
SET @add_message_fk = IF(
  @has_message_fk = 0,
  'ALTER TABLE notifications ADD CONSTRAINT fk_notifications_message FOREIGN KEY (message_id) REFERENCES messages(id) ON DELETE CASCADE ON UPDATE CASCADE',
  'SELECT 1'
);
PREPARE add_message_fk_statement FROM @add_message_fk;
EXECUTE add_message_fk_statement;
DEALLOCATE PREPARE add_message_fk_statement;
