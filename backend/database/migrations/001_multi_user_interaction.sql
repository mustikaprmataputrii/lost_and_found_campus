USE lost_and_found_campus;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'messages'
    AND column_name = 'pengirim_email'
);
SET @alter_messages = IF(
  @column_exists = 0,
  'ALTER TABLE messages ADD COLUMN pengirim_email VARCHAR(120) NULL AFTER pengirim',
  'SELECT 1'
);
PREPARE alter_messages_statement FROM @alter_messages;
EXECUTE alter_messages_statement;
DEALLOCATE PREPARE alter_messages_statement;

CREATE TABLE IF NOT EXISTS chat_members (
  chat_id VARCHAR(120) NOT NULL,
  email VARCHAR(120) NOT NULL,
  last_read_at DATETIME NULL,
  joined_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (chat_id, email),
  INDEX idx_chat_members_email (email),
  CONSTRAINT fk_chat_members_chat
    FOREIGN KEY (chat_id) REFERENCES chats(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_chat_members_user
    FOREIGN KEY (email) REFERENCES users(email)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS user_presence (
  email VARCHAR(120) PRIMARY KEY,
  is_online TINYINT(1) NOT NULL DEFAULT 0,
  last_seen DATETIME NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_presence_user
    FOREIGN KEY (email) REFERENCES users(email)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

INSERT IGNORE INTO chat_members (chat_id, email)
SELECT id, owner_email FROM chats WHERE owner_email IS NOT NULL;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'chat_members'
    AND column_name = 'last_read_at'
);
SET @alter_chat_members = IF(
  @column_exists = 0,
  'ALTER TABLE chat_members ADD COLUMN last_read_at DATETIME NULL AFTER email',
  'SELECT 1'
);
PREPARE alter_chat_members_statement FROM @alter_chat_members;
EXECUTE alter_chat_members_statement;
DEALLOCATE PREPARE alter_chat_members_statement;

ALTER TABLE chat_members MODIFY last_read_at DATETIME(6) NULL;
ALTER TABLE messages MODIFY waktu DATETIME(6) NOT NULL;

SET @column_exists = (
  SELECT COUNT(*)
  FROM information_schema.columns
  WHERE table_schema = DATABASE()
    AND table_name = 'notifications'
    AND column_name = 'chat_id'
);
SET @alter_notifications = IF(
  @column_exists = 0,
  'ALTER TABLE notifications ADD COLUMN chat_id VARCHAR(120) NULL AFTER email',
  'SELECT 1'
);
PREPARE alter_notifications_statement FROM @alter_notifications;
EXECUTE alter_notifications_statement;
DEALLOCATE PREPARE alter_notifications_statement;

SET @constraint_exists = (
  SELECT COUNT(*)
  FROM information_schema.table_constraints
  WHERE constraint_schema = DATABASE()
    AND table_name = 'notifications'
    AND constraint_name = 'fk_notifications_chat'
);
SET @add_notification_chat_fk = IF(
  @constraint_exists = 0,
  'ALTER TABLE notifications ADD CONSTRAINT fk_notifications_chat FOREIGN KEY (chat_id) REFERENCES chats(id) ON DELETE CASCADE ON UPDATE CASCADE',
  'SELECT 1'
);
PREPARE notification_chat_fk_statement FROM @add_notification_chat_fk;
EXECUTE notification_chat_fk_statement;
DEALLOCATE PREPARE notification_chat_fk_statement;

ALTER TABLE notifications MODIFY waktu DATETIME(6) NOT NULL;
