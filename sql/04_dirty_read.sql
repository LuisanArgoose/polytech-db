-- 04_dirty_read.sql
-- Аномалия: грязное чтение (Dirty Read)
-- Таблица: exam."StudentGroups", колонка "StudentCount"

-- Подготовка:
-- SET search_path TO exam, public;
-- UPDATE "StudentGroups" SET "StudentCount" = 24 WHERE "GroupCode" = 'ИВТ-21';
-- COMMIT;

-- Уровень изоляции: READ UNCOMMITTED (в PostgreSQL = READ COMMITTED)

-- ===== Сессия A =====
-- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- BEGIN;
-- UPDATE "StudentGroups" SET "StudentCount" = 999 WHERE "GroupCode" = 'ИВТ-21';
-- -- не COMMIT

-- ===== Сессия B =====
-- SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- BEGIN;
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';   -- видит 999 (грязное)
-- COMMIT;

-- ===== Сессия A =====
-- ROLLBACK;

-- Проверка:
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';
-- Ожидаемое: 24. Если B прочитала 999 — аномалия грязного чтения.