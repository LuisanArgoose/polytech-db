-- 04_lost_update.sql
-- Аномалия: потерянные изменения (Lost Update)
-- Таблица: exam."StudentGroups", колонка "StudentCount"
-- Требуются 2 параллельные сессии A и B.

-- Подготовка (выполнить один раз в любой сессии):
-- SET search_path TO exam, public;
-- UPDATE "StudentGroups" SET "StudentCount" = 24 WHERE "GroupCode" = 'ИВТ-21';
-- COMMIT;

-- Уровень изоляции: READ COMMITTED / READ UNCOMMITTED (в PostgreSQL это синонимы)

-- ===== Сессия A =====
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- BEGIN;
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';   -- 24
-- UPDATE "StudentGroups" SET "StudentCount" = "StudentCount" + 5 WHERE "GroupCode" = 'ИВТ-21';
-- -- не COMMIT, ждём шаг из сессии B

-- ===== Сессия B =====
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- BEGIN;
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';   -- 24
-- UPDATE "StudentGroups" SET "StudentCount" = "StudentCount" + 3 WHERE "GroupCode" = 'ИВТ-21';
-- COMMIT;   -- B фиксируется первой

-- ===== Сессия A =====
-- COMMIT;   -- A фиксируется второй, затирает +3 от B

-- Проверка:
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';
-- Ожидаемое при отсутствии аномалии: 24+5+3 = 32. Фактически: 29 (потеря +3).