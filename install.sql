-- For ESX Framework
CREATE TABLE IF NOT EXISTS `user_licenses` (
    `type` varchar(60) NOT NULL,
    `owner` varchar(60) NOT NULL,
    PRIMARY KEY (`type`, `owner`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- For ESX with custom license items (optional)
CREATE TABLE IF NOT EXISTS `user_licenses_items` (
    `identifier` varchar(60) NOT NULL,
    `item_name` varchar(50) NOT NULL,
    `metadata` longtext,
    PRIMARY KEY (`identifier`, `item_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;