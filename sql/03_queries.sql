-- Практическое задание 1.3. Вариант 7.
-- Запросы к схеме exam. Имена таблиц квалифицированы схемой, search_path не нужен.

-- 1. Сколько работ нужно проверить каждому преподавателю.
-- Работа = письменная работа одного студента на одном экзамене (или зачёте).
-- Число работ по экзамену равно численности группы StudentGroups.StudentCount.
-- Преподаватели без назначенных экзаменов тоже попадают в результат (0 работ).

WITH "TeacherExamLoad" AS (
    SELECT
        t."Id",
        t."FullName",
        e."Id" AS "ExamSessionId",
        g."StudentCount"
    FROM exam."Teachers" AS t
    LEFT JOIN exam."ExamSessions" AS e
        ON e."TeacherId" = t."Id"
    LEFT JOIN exam."StudentGroups" AS g
        ON g."Id" = e."StudentGroupId"
)
SELECT
    "FullName" AS "Преподаватель",
    COUNT("ExamSessionId") AS "Число экзаменов",
    COALESCE(SUM("StudentCount"), 0) AS "Работ к проверке"
FROM "TeacherExamLoad"
GROUP BY "Id", "FullName"
ORDER BY "Работ к проверке" DESC, "Преподаватель";
