-- Практическое задание 2.2. Простые функции PL/pgSQL.
SET search_path TO exam, public;

-- 1. Переменные и ветвление: краткая характеристика группы.
CREATE OR REPLACE FUNCTION exam.fn_group_info(p_group_code varchar)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_students integer;
    v_course smallint;
    v_result text;
BEGIN
    SELECT "StudentCount", "CourseYear"
    INTO v_students, v_course
    FROM exam."StudentGroups"
    WHERE "GroupCode" = p_group_code;

    IF NOT FOUND THEN
        RETURN 'Группа не найдена';
    ELSIF v_students >= 25 THEN
        v_result := 'Группа ' || p_group_code || ': ' || v_students
                    || ' студентов, курс ' || v_course || ', большая группа';
    ELSE
        v_result := 'Группа ' || p_group_code || ': ' || v_students
                    || ' студентов, курс ' || v_course || ', обычная группа';
    END IF;
    RETURN v_result;
END;
$$;

-- 2. Явный курсор и цикл: подсчёт экзаменов группы.
CREATE OR REPLACE FUNCTION exam.fn_count_group_exams(p_group_code varchar)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_exam record;
    v_count integer := 0;
    exam_cursor CURSOR FOR
        SELECT e."Id"
        FROM exam."ExamSessions" e
        JOIN exam."StudentGroups" g ON g."Id" = e."StudentGroupId"
        WHERE g."GroupCode" = p_group_code;
BEGIN
    OPEN exam_cursor;
    LOOP
        FETCH exam_cursor INTO v_exam;
        EXIT WHEN NOT FOUND;
        v_count := v_count + 1;
    END LOOP;
    CLOSE exam_cursor;
    RETURN v_count;
END;
$$;

-- 3. Переменные, ветвление и исключения: изменение часов дисциплины.
CREATE OR REPLACE FUNCTION exam.fn_change_subject_hours(
    p_subject_name varchar,
    p_delta integer
)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_hours integer;
BEGIN
    IF p_delta = 0 THEN
        RAISE EXCEPTION 'Изменение часов не должно быть равно нулю';
    END IF;
    IF p_delta < 0 THEN
        RAISE EXCEPTION 'Изменение часов не может быть отрицательным';
    END IF;

    UPDATE exam."Subjects"
    SET "TotalHours" = "TotalHours" + p_delta
    WHERE "SubjectName" = p_subject_name
    RETURNING "TotalHours" INTO v_hours;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Дисциплина не найдена: %', p_subject_name;
    END IF;
    RETURN v_hours;
END;
$$;

-- 4. Цикл FOR и переменная: строковое расписание на дату.
CREATE OR REPLACE FUNCTION exam.fn_schedule_for_date(p_exam_date date)
RETURNS text
LANGUAGE plpgsql
AS $$
DECLARE
    v_row record;
    v_result text := '';
BEGIN
    FOR v_row IN
        SELECT g."GroupCode", s."SubjectName", t."FullName"
        FROM exam."ExamSessions" e
        JOIN exam."StudentGroups" g ON g."Id" = e."StudentGroupId"
        JOIN exam."Subjects" s ON s."Id" = e."SubjectId"
        JOIN exam."Teachers" t ON t."Id" = e."TeacherId"
        WHERE e."ExamDate" = p_exam_date
        ORDER BY g."GroupCode"
    LOOP
        v_result := v_result || v_row."GroupCode" || ': '
                    || v_row."SubjectName" || ' — '
                    || v_row."FullName" || E'\n';
    END LOOP;

    IF v_result = '' THEN
        RETURN 'На указанную дату экзаменов нет';
    END IF;
    RETURN rtrim(v_result);
END;
$$;