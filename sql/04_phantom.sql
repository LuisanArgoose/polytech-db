-- 04_phantom.sql
-- Аномалия: фантомы (Phantom Read)
-- Таблица: exam."StudentGroups", условие CourseYear = 4

-- Подготовка:
-- SET search_path TO exam, public;

-- ===== Сессия A =====
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- BEGIN;
-- SELECT COUNT(*) FROM "StudentGroups" WHERE "CourseYear" = 4;   -- N

-- ===== Сессия B =====
-- SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- BEGIN;
-- INSERT INTO "StudentGroups" ("Id","GroupCode","CourseYear","StudentCount","FacultyId")
-- VALUES ('a3000001-0000-4000-8000-0000000000ff', 'Тест-99', 4, 10,
--         (SELECT "Id" FROM "Faculties" LIMIT 1));
-- COMMIT;

-- ===== Сессия A =====
-- SELECT COUNT(*) FROM "StudentGroups" WHERE "CourseYear" = 4;   -- N+1 (фантом)
-- COMMIT;

-- Проверка: количество строк изменилось -> аномалия фантома.
-- На REPEATABLE READ / SERIALIZABLE количество должно остаться N.
-- Очистка тестовой строки:
-- DELETE FROM "StudentGroups" WHERE "GroupCode" = 'Тест-99';