-- Практическое задание 2.1. Роли, права и представления.
-- Выполнять от имени владельца базы (postgres).
SET search_path TO exam, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'test') THEN
        CREATE ROLE test LOGIN PASSWORD 'test123';
    ELSE
        ALTER ROLE test LOGIN PASSWORD 'test123';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'exam_editor') THEN
        CREATE ROLE exam_editor NOLOGIN;
    END IF;
END
$$;

GRANT CONNECT ON DATABASE examdb TO test;
GRANT USAGE ON SCHEMA exam TO test;

REVOKE ALL ON ALL TABLES IN SCHEMA exam FROM test;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA exam FROM test;
REVOKE ALL ON ALL FUNCTIONS IN SCHEMA exam FROM test;
REVOKE ALL ON ALL TABLES IN SCHEMA exam FROM exam_editor;

-- StudentGroups: полный SELECT, INSERT и UPDATE без DELETE.
GRANT SELECT, INSERT, UPDATE ON exam."StudentGroups" TO test;

-- Subjects: читать всю таблицу, изменять только объём часов.
GRANT SELECT ON exam."Subjects" TO test;
GRANT UPDATE ("TotalHours") ON exam."Subjects" TO test;

-- Teachers: только чтение.
GRANT SELECT ON exam."Teachers" TO test;

-- Однотабличное представление: только безопасные сведения о группах.
CREATE OR REPLACE VIEW exam."v_group_load" AS
SELECT "GroupCode", "CourseYear", "StudentCount"
FROM exam."StudentGroups";

-- Многотабличное представление расписания без UUID и служебных ключей.
CREATE OR REPLACE VIEW exam."v_exam_schedule" AS
SELECT g."GroupCode", s."SubjectName", e."ExamDate",
       t."FullName" AS "TeacherFullName", e."AssessmentType"
FROM exam."ExamSessions" e
JOIN exam."StudentGroups" g ON g."Id" = e."StudentGroupId"
JOIN exam."Subjects" s ON s."Id" = e."SubjectId"
JOIN exam."Teachers" t ON t."Id" = e."TeacherId";

-- Роль изменяет только численность через однотабличное представление.
GRANT SELECT ON exam."v_group_load" TO exam_editor;
GRANT UPDATE ("StudentCount") ON exam."v_group_load" TO exam_editor;
GRANT exam_editor TO test;

-- Вставка в многотабличное представление преобразуется в INSERT базовой таблицы.
CREATE OR REPLACE FUNCTION exam.fn_insert_exam_schedule()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = exam, pg_catalog
AS $$
BEGIN
    INSERT INTO exam."ExamSessions"
        ("Id", "StudentGroupId", "SubjectId", "ExamDate",
         "TeacherId", "AssessmentType")
    SELECT gen_random_uuid(), g."Id", s."Id", NEW."ExamDate",
           t."Id", NEW."AssessmentType"
    FROM exam."StudentGroups" g
    CROSS JOIN exam."Subjects" s
    CROSS JOIN exam."Teachers" t
    WHERE g."GroupCode" = NEW."GroupCode"
      AND s."SubjectName" = NEW."SubjectName"
      AND t."FullName" = NEW."TeacherFullName";

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Группа, дисциплина или преподаватель не найдены';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_insert_exam_schedule ON exam."v_exam_schedule";
CREATE TRIGGER trg_insert_exam_schedule
INSTEAD OF INSERT ON exam."v_exam_schedule"
FOR EACH ROW EXECUTE FUNCTION exam.fn_insert_exam_schedule();

GRANT SELECT ON exam."v_exam_schedule" TO test;
GRANT INSERT ON exam."v_exam_schedule" TO test;

-- Для новых объектов права по умолчанию не расширяются.
ALTER DEFAULT PRIVILEGES IN SCHEMA exam REVOKE ALL ON TABLES FROM test, exam_editor;