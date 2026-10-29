-- Проверки функций задания 2.2.
SET search_path TO exam, public;

SELECT exam.fn_group_info('ИВТ-21');
SELECT exam.fn_group_info('НЕ-СУЩЕСТВУЕТ');
SELECT exam.fn_count_group_exams('ИВТ-21');
SELECT exam.fn_schedule_for_date(DATE '2026-01-12');

SELECT exam.fn_change_subject_hours('Базы данных', 4);
UPDATE exam."Subjects"
SET "TotalHours" = "TotalHours" - 4
WHERE "SubjectName" = 'Базы данных';

DO $$
BEGIN
    PERFORM exam.fn_change_subject_hours('Базы данных', -1);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Проверка исключения: %', SQLERRM;
END;
$$;

DO $$
BEGIN
    PERFORM exam.fn_change_subject_hours('Несуществующая дисциплина', 4);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Проверка исключения: %', SQLERRM;
END;
$$;