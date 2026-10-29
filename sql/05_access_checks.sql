-- Практическое задание 2.1. Проверки от имени test.
\set ON_ERROR_STOP off
\pset pager off
\set VERBOSITY terse
SET search_path TO exam, public;

SELECT session_user, current_user;
\dp exam.*

-- Разрешённые выборки из таблиц и представлений.
SELECT "GroupCode", "CourseYear", "StudentCount"
FROM exam."StudentGroups" ORDER BY "GroupCode" LIMIT 2;
SELECT "SubjectName", "TotalHours"
FROM exam."Subjects" ORDER BY "SubjectName" LIMIT 2;
SELECT "FullName" FROM exam."Teachers" ORDER BY "FullName" LIMIT 2;
SELECT * FROM exam."v_group_load" ORDER BY "GroupCode" LIMIT 2;
SELECT * FROM exam."v_exam_schedule" ORDER BY "ExamDate" LIMIT 2;

-- Разрешённый UPDATE полного набора строк StudentGroups.
BEGIN;
UPDATE exam."StudentGroups"
SET "StudentCount" = "StudentCount" + 1
WHERE "GroupCode" = 'ИВТ-21';
ROLLBACK;

-- Разрешённое изменение выбранного столбца Subjects.
BEGIN;
UPDATE exam."Subjects"
SET "TotalHours" = "TotalHours" + 1
WHERE "SubjectName" = 'Базы данных';
ROLLBACK;

-- Запрещённое изменение другого столбца Subjects.
UPDATE exam."Subjects"
SET "Department" = 'Кафедра доступа'
WHERE "SubjectName" = 'Базы данных';

-- UPDATE через назначенную роль.
BEGIN;
UPDATE exam."v_group_load"
SET "StudentCount" = "StudentCount" + 1
WHERE "GroupCode" = 'ИВТ-21';
ROLLBACK;

-- Вставка в многотабличное представление.
INSERT INTO exam."v_exam_schedule"
    ("GroupCode", "SubjectName", "ExamDate", "TeacherFullName", "AssessmentType")
VALUES ('ИВТ-21', 'Базы данных', DATE '2026-07-01',
        'Соколова Анна Петровна', 'Экзамен');

SELECT * FROM exam."v_exam_schedule"
WHERE "GroupCode" = 'ИВТ-21' AND "ExamDate" = DATE '2026-07-01';

-- Запрещённые операции.
DELETE FROM exam."StudentGroups" WHERE "GroupCode" = 'ИВТ-21';
SELECT * FROM exam."Subjects";