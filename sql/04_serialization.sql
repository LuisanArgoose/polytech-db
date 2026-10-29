-- 04_serialization.sql
-- Аномалия: сериализация (Serialization Anomaly)
-- Таблица: exam."StudentGroups", строки ИВТ-21 и ИВТ-22

-- Подготовка:
-- SET search_path TO exam, public;
-- UPDATE "StudentGroups" SET "StudentCount" = 24 WHERE "GroupCode" = 'ИВТ-21';
-- UPDATE "StudentGroups" SET "StudentCount" = 26 WHERE "GroupCode" = 'ИВТ-22';
-- COMMIT;

-- Состояние 1 (последовательное выполнение): выполнить T1 потом T2, зафиксировать результат.
-- Состояние 2 (параллельное выполнение): выполнить шаги ниже, зафиксировать результат.
-- Сравнить состояния. Если различаются -> аномалия сериализации.

-- ===== Сессия A (T1) =====
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- BEGIN;
-- UPDATE "StudentGroups"
--    SET "StudentCount" = (SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-22')
--  WHERE "GroupCode" = 'ИВТ-21';

-- ===== Сессия B (T2) =====
-- SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- BEGIN;
-- UPDATE "StudentGroups"
--    SET "StudentCount" = (SELECT "StudentCount" FROM "StudentGroups" WHERE "GroupCode" = 'ИВТ-21')
--  WHERE "GroupCode" = 'ИВТ-22';
-- COMMIT;   -- B фиксируется

-- ===== Сессия A =====
-- COMMIT;   -- на RR пройдёт; на SERIALIZABLE — откат с ошибкой сериализации

-- Проверка:
-- SELECT "GroupCode", "StudentCount" FROM "StudentGroups"
--  WHERE "GroupCode" IN ('ИВТ-21','ИВТ-22');
-- На RR результат параллельного выполнения отличается от последовательного -> аномалия.
-- На SERIALIZABLE вторая транзакция откатывается -> аномалия не фиксируется.