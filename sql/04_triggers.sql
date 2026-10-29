-- 04_triggers.sql
-- Триггеры для сохранения целостности данных

SET search_path TO exam, public;

-- 1. Триггер: StudentCount не может быть отрицательным
CREATE OR REPLACE FUNCTION fn_check_student_count()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW."StudentCount" < 0 THEN
        RAISE EXCEPTION 'StudentCount не может быть отрицательным';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_studentgroup_check_nonneg ON "StudentGroups";
CREATE TRIGGER trg_studentgroup_check_nonneg
BEFORE INSERT OR UPDATE ON "StudentGroups"
FOR EACH ROW EXECUTE FUNCTION fn_check_student_count();

-- 2. Триггер: один преподаватель не может принимать два экзамена в одну дату
CREATE OR REPLACE FUNCTION fn_check_teacher_conflict()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM "ExamSessions"
        WHERE "TeacherId" = NEW."TeacherId"
          AND "ExamDate" = NEW."ExamDate"
          AND "Id" <> NEW."Id"
    ) THEN
        RAISE EXCEPTION 'Преподаватель уже занят в эту дату';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_examsession_teacher_conflict ON "ExamSessions";
CREATE TRIGGER trg_examsession_teacher_conflict
BEFORE INSERT OR UPDATE ON "ExamSessions"
FOR EACH ROW EXECUTE FUNCTION fn_check_teacher_conflict();

-- Демонстрация: корректное изменение
-- UPDATE "StudentGroups" SET "StudentCount" = 30 WHERE "GroupCode" = 'ИВТ-21';

-- Демонстрация: нарушение целостности (должен откатиться)
-- UPDATE "StudentGroups" SET "StudentCount" = -5 WHERE "GroupCode" = 'ИВТ-21';

-- Демонстрация: конфликт преподавателя (должен откатиться)
-- INSERT INTO "ExamSessions" ("Id","StudentGroupId","SubjectId","ExamDate","TeacherId","AssessmentType")
-- VALUES (gen_random_uuid(), 'a3000001-0000-4000-8000-000000000001', 'a4000001-0000-4000-8000-000000000001', DATE '2026-01-12',
--         (SELECT "TeacherId" FROM "ExamSessions" WHERE "ExamDate" = DATE '2026-01-12' LIMIT 1), 'Экзамен');