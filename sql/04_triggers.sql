-- Два триггера для учебных групп. Повторный запуск допустим.
BEGIN;

-- Приведение кода группы к единому виду и запрет пустого кода.
CREATE OR REPLACE FUNCTION exam.fn_normalize_group_code()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW."GroupCode" := upper(btrim(NEW."GroupCode"));
    IF NEW."GroupCode" IS NULL OR NEW."GroupCode" = '' THEN
        RAISE EXCEPTION 'Код группы не должен быть пустым';
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_normalize_group_code ON exam."StudentGroups";
CREATE TRIGGER trg_normalize_group_code
BEFORE INSERT OR UPDATE OF "GroupCode" ON exam."StudentGroups"
FOR EACH ROW EXECUTE FUNCTION exam.fn_normalize_group_code();

-- Защита расписания от каскадного удаления вместе с группой.
CREATE OR REPLACE FUNCTION exam.fn_prevent_group_delete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM exam."ExamSessions"
        WHERE "StudentGroupId" = OLD."Id"
    ) THEN
        RAISE EXCEPTION 'Нельзя удалить группу: для неё есть экзамены';
    END IF;
    RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_prevent_group_delete ON exam."StudentGroups";
CREATE TRIGGER trg_prevent_group_delete
BEFORE DELETE ON exam."StudentGroups"
FOR EACH ROW EXECUTE FUNCTION exam.fn_prevent_group_delete();

COMMIT;