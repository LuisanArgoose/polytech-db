-- 04_non_repeatable_read.sql
-- Аномалия: неповторяющееся чтение (Non-Repeatable Read)
-- Таблица: exam."StudentGroups", колонка "StudentCount"

-- Подготовка:
-- SET search_path TO exam, public;
-- UPDATE "StudentGroups" SET "StudentCount" = 24 WHERE "GroupCode" = 'ИВТ-21';
-- COMMIT;

-- ===== Сессия A =====
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- BEGIN;
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';   -- 24

-- ===== Сессия B =====
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- BEGIN;
-- UPDATE "StudentGroups" SET "StudentCount" = 30 WHERE "GroupCode" = 'ИВТ-21';
-- COMMIT;

-- ===== Сессия A =====
-- SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21';   -- 30 (изменилось)
-- COMMIT;

-- Проверка: повторное чтение в одной транзакции дало другой результат -> аномалия.
-- На REPEATABLE READ повторное чтение должно дать 24.