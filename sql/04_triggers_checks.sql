-- Проверки после 04_triggers.sql. Все изменения данных отменяются.
\set ON_ERROR_STOP on
\pset pager off
\set VERBOSITY terse
SET search_path TO exam, public;
BEGIN;

SELECT "GroupCode", "StudentCount" FROM "StudentGroups"
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';

UPDATE "StudentGroups" SET "GroupCode" = '  ивт-21  '
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';

SELECT "GroupCode", length("GroupCode") AS "CodeLength"
FROM "StudentGroups"
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';

SAVEPOINT empty_code;
\set ON_ERROR_STOP off
UPDATE "StudentGroups" SET "GroupCode" = '   '
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT empty_code;

SELECT "GroupCode" FROM "StudentGroups"
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';

SELECT g."GroupCode", COUNT(*) AS "ExamCount"
FROM "StudentGroups" g
JOIN "ExamSessions" e ON e."StudentGroupId" = g."Id"
WHERE g."Id" = 'a3000001-0000-4000-8000-000000000001'
GROUP BY g."GroupCode";

SAVEPOINT group_delete;
\set ON_ERROR_STOP off
DELETE FROM "StudentGroups"
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';
\set ON_ERROR_STOP on
ROLLBACK TO SAVEPOINT group_delete;

SELECT "GroupCode" FROM "StudentGroups"
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';

INSERT INTO "StudentGroups"
    ("Id", "GroupCode", "CourseYear", "StudentCount", "FacultyId")
VALUES ('b3000001-0000-4000-8000-000000000001', '  test-26  ', 1, 0,
        'a1000001-0000-4000-8000-000000000001');

SELECT "GroupCode" FROM "StudentGroups"
WHERE "Id" = 'b3000001-0000-4000-8000-000000000001';

DELETE FROM "StudentGroups"
WHERE "Id" = 'b3000001-0000-4000-8000-000000000001';

SELECT COUNT(*) AS "GroupCount" FROM "StudentGroups"
WHERE "Id" = 'b3000001-0000-4000-8000-000000000001';

ROLLBACK;

SELECT "GroupCode", "StudentCount" FROM "StudentGroups"
WHERE "Id" = 'a3000001-0000-4000-8000-000000000001';