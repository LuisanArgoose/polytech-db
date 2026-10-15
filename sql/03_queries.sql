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


-- 2. Сводка по факультетам за январь.
-- Окно — все экзамены января внутри факультета (PARTITION BY факультет).
-- Группа и преподаватель считаются один раз: ROW_NUMBER помечает первую строку,
-- иначе одна группа попала бы в сумму столько раз, сколько у неё экзаменов.
-- Зачёты и дифференцированные зачёты в «экзамены» не входят.

WITH "JanuaryExams" AS (
    SELECT
        f."Id" AS "FacultyId",
        f."Name" AS "FacultyName",
        g."Id" AS "GroupId",
        g."StudentCount",
        e."Id" AS "ExamId",
        e."TeacherId"
    FROM exam."ExamSessions" AS e
    JOIN exam."StudentGroups" AS g
        ON g."Id" = e."StudentGroupId"
    JOIN exam."Faculties" AS f
        ON f."Id" = g."FacultyId"
    WHERE e."AssessmentType" = 'Экзамен'
      AND EXTRACT(MONTH FROM e."ExamDate") = 1
),
"Marked" AS (
    SELECT
        "FacultyId",
        "FacultyName",
        "GroupId",
        "StudentCount",
        "ExamId",
        "TeacherId",
        ROW_NUMBER() OVER (
            PARTITION BY "FacultyId", "GroupId"
            ORDER BY "ExamId"
        ) AS "GroupRow",
        ROW_NUMBER() OVER (
            PARTITION BY "FacultyId", "TeacherId"
            ORDER BY "ExamId"
        ) AS "TeacherRow"
    FROM "JanuaryExams"
)
SELECT DISTINCT
    "FacultyName" AS "Факультет",
    COUNT("GroupId") FILTER (WHERE "GroupRow" = 1)
        OVER (PARTITION BY "FacultyId") AS "Количество групп",
    SUM("StudentCount") FILTER (WHERE "GroupRow" = 1)
        OVER (PARTITION BY "FacultyId") AS "Количество студентов",
    COUNT("ExamId")
        OVER (PARTITION BY "FacultyId") AS "Количество экзаменов",
    COUNT("TeacherId") FILTER (WHERE "TeacherRow" = 1)
        OVER (PARTITION BY "FacultyId") AS "Количество преподавателей"
FROM "Marked"
ORDER BY "Факультет";

-- 3. Та же сводка. Окно идёт по датам января внутри факультета:
-- от первого экзамена января до текущего (ROWS UNBOUNDED PRECEDING).
-- В результат берётся последняя строка окна — итог на конец января.

WITH "JanuaryExams" AS (
    SELECT
        f."Id" AS "FacultyId",
        f."Name" AS "FacultyName",
        g."Id" AS "GroupId",
        g."StudentCount",
        e."Id" AS "ExamId",
        e."ExamDate",
        e."TeacherId"
    FROM exam."ExamSessions" AS e
    JOIN exam."StudentGroups" AS g
        ON g."Id" = e."StudentGroupId"
    JOIN exam."Faculties" AS f
        ON f."Id" = g."FacultyId"
    WHERE e."AssessmentType" = 'Экзамен'
      AND EXTRACT(MONTH FROM e."ExamDate") = 1
),
"Marked" AS (
    SELECT
        "FacultyId",
        "FacultyName",
        "GroupId",
        "StudentCount",
        "ExamId",
        "ExamDate",
        "TeacherId",
        ROW_NUMBER() OVER (
            PARTITION BY "FacultyId", "GroupId"
            ORDER BY "ExamDate", "ExamId"
        ) AS "GroupRow",
        ROW_NUMBER() OVER (
            PARTITION BY "FacultyId", "TeacherId"
            ORDER BY "ExamDate", "ExamId"
        ) AS "TeacherRow"
    FROM "JanuaryExams"
),
"Running" AS (
    SELECT
        "FacultyName",
        SUM(CASE WHEN "GroupRow" = 1 THEN 1 ELSE 0 END)
            OVER january AS "Количество групп",
        SUM(CASE WHEN "GroupRow" = 1 THEN "StudentCount" ELSE 0 END)
            OVER january AS "Количество студентов",
        COUNT("ExamId")
            OVER january AS "Количество экзаменов",
        SUM(CASE WHEN "TeacherRow" = 1 THEN 1 ELSE 0 END)
            OVER january AS "Количество преподавателей",
        ROW_NUMBER() OVER (
            PARTITION BY "FacultyId"
            ORDER BY "ExamDate" DESC, "ExamId" DESC
        ) AS "IsLastInJanuary"
    FROM "Marked"
    WINDOW january AS (
        PARTITION BY "FacultyId"
        ORDER BY "ExamDate", "ExamId"
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    )
)
SELECT
    "FacultyName" AS "Факультет",
    "Количество групп",
    "Количество студентов",
    "Количество экзаменов",
    "Количество преподавателей"
FROM "Running"
WHERE "IsLastInJanuary" = 1
ORDER BY "Факультет";

