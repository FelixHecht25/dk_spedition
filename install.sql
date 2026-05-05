SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";
SET NAMES utf8mb4;

-- ---------------------------------------------------------
-- Tabelle: dk_spedition_profiles
-- Speichert Fahrerprofil, Level, XP, Lizenzen und Statistik.
-- ---------------------------------------------------------

CREATE TABLE `dk_spedition_profiles` (
  `citizenid` varchar(50) NOT NULL,

  `xp` int(11) NOT NULL DEFAULT 0,
  `level` int(11) NOT NULL DEFAULT 1,

  `completed_jobs` int(11) NOT NULL DEFAULT 0,
  `failed_jobs` int(11) NOT NULL DEFAULT 0,

  `adr_license` tinyint(1) NOT NULL DEFAULT 0,
  `heavy_license` tinyint(1) NOT NULL DEFAULT 0,
  `coolchain_license` tinyint(1) NOT NULL DEFAULT 0,

  `adr_exam_attempts` int(11) NOT NULL DEFAULT 0,
  `adr_exam_passed_at` timestamp NULL DEFAULT NULL,
  `adr_exam_failed_at` timestamp NULL DEFAULT NULL,

  `hazmat_completed` int(11) NOT NULL DEFAULT 0,
  `total_distance` int(11) NOT NULL DEFAULT 0,

  `last_job_at` timestamp NULL DEFAULT NULL,

  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Tabelle: dk_spedition_offer_cache
-- Speichert temporär die aktuell angebotenen Aufträge pro Spieler.
-- Dadurch kann der Spieler nur Aufträge annehmen, die ihm wirklich angezeigt wurden.
-- ---------------------------------------------------------

CREATE TABLE `dk_spedition_offer_cache` (
  `citizenid` varchar(50) NOT NULL,
  `offers` longtext NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),

  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Tabelle: dk_spedition_runs
-- Speichert alle aktiven, abgeschlossenen, abgebrochenen und fehlgeschlagenen Aufträge.
-- Enthält Fahrzeugdaten, Fracht, Route, Plombe, Auszahlung und Status.
-- ---------------------------------------------------------

CREATE TABLE `dk_spedition_runs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,

  `template_id` varchar(80) NOT NULL,
  `state` varchar(40) NOT NULL DEFAULT 'CREATED',

  `truck_model` varchar(50) DEFAULT NULL,
  `trailer_model` varchar(50) DEFAULT NULL,

  `truck_plate` varchar(20) DEFAULT NULL,
  `trailer_plate` varchar(20) DEFAULT NULL,

  `truck_net_id` int(11) DEFAULT NULL,
  `trailer_net_id` int(11) DEFAULT NULL,

  `cargo_inventory_id` varchar(120) NOT NULL,
  `cargo_id` varchar(80) NOT NULL,
  `cargo_item` varchar(80) NOT NULL,
  `cargo_label` varchar(120) NOT NULL,
  `cargo_amount` int(11) NOT NULL DEFAULT 1,

  `origin_label` varchar(120) NOT NULL,
  `destination_label` varchar(120) NOT NULL,

  `pickup_id` varchar(80) NOT NULL DEFAULT 'unknown',
  `receiver_id` varchar(80) NOT NULL,

  `seal_number` varchar(80) DEFAULT NULL,
  `seal_broken` tinyint(1) NOT NULL DEFAULT 0,

  `documents_collected` tinyint(1) NOT NULL DEFAULT 0,
  `papers_accepted` tinyint(1) NOT NULL DEFAULT 0,

  `base_payout` int(11) NOT NULL DEFAULT 0,
  `base_xp` int(11) NOT NULL DEFAULT 0,

  `final_payout` int(11) DEFAULT NULL,
  `final_xp` int(11) DEFAULT NULL,

  `loading_ends_at` int(11) DEFAULT NULL,

  `unload_x` double DEFAULT NULL,
  `unload_y` double DEFAULT NULL,
  `unload_z` double DEFAULT NULL,
  `unload_w` double DEFAULT NULL,

  `started_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `completed_at` timestamp NULL DEFAULT NULL,
  `cancelled_at` timestamp NULL DEFAULT NULL,
  `failed_at` timestamp NULL DEFAULT NULL,

  `leak_active` tinyint(1) NOT NULL DEFAULT 0,
  `leak_started_at` timestamp NULL DEFAULT NULL,
  `leak_resolved` tinyint(1) NOT NULL DEFAULT 0,

  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `state` (`state`),
  KEY `truck_plate` (`truck_plate`),
  KEY `trailer_plate` (`trailer_plate`),
  KEY `template_id` (`template_id`),
  KEY `pickup_id` (`pickup_id`),
  KEY `receiver_id` (`receiver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ---------------------------------------------------------
-- Tabelle: dk_spedition_documents
-- Speichert ausgestellte Frachtbriefe, Lieferscheine und ADR-Dokumente.
-- Die eigentlichen Dokumentdaten liegen als JSON/Text in `data`.
-- ---------------------------------------------------------

CREATE TABLE `dk_spedition_documents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `run_id` int(11) NOT NULL,
  `citizenid` varchar(50) NOT NULL,

  `serial` varchar(80) NOT NULL,
  `doc_type` varchar(80) NOT NULL,
  `data` longtext NOT NULL,

  `status` varchar(40) NOT NULL DEFAULT 'active',

  `issued_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `expires_at` timestamp NULL DEFAULT NULL,

  PRIMARY KEY (`id`),
  UNIQUE KEY `serial_unique` (`serial`),
  KEY `run_id` (`run_id`),
  KEY `citizenid` (`citizenid`),
  KEY `status` (`status`),
  KEY `doc_type` (`doc_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

COMMIT;