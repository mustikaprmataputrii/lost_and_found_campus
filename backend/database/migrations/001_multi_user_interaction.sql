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
