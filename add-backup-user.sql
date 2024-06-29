DROP USER IF EXISTS 'backup_user'@'localhost';

-- Create a new user for backups
CREATE USER 'backup_user'@'localhost' IDENTIFIED BY 'secret';

-- Grant necessary privileges to the backup user
GRANT SELECT, LOCK TABLES, SHOW VIEW, EVENT ON *.* TO 'backup_user'@'localhost';

-- Ensure privileges take effect
FLUSH PRIVILEGES;

