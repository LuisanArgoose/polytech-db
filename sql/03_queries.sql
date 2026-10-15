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
-- Окно: экзамены с датой в январе любого года.

SELECT DISTINCT
    f."Name" AS "Факультет",
    COUNT(g."Id") OVER (PARTITION BY f."Id") AS "Количество групп",
    SUM(g."StudentCount") OVER (PARTITION BY f."Id") AS "Количество студентов",
    COUNT(e."Id") OVER (PARTITION BY f."Id") AS "Количество экзаменов",
    COUNT(e."TeacherId") OVER (PARTITION BY f."Id") AS "Количество преподавателей"
FROM exam."Faculties" AS f
JOIN exam."StudentGroups" AS g
    ON g."FacultyId" = f."Id"
JOIN exam."ExamSessions" AS e
    ON e."StudentGroupId" = g."Id"
   AND EXTRACT(MONTH FROM e."ExamDate") = 1
ORDER BY "Факультет";

-- 3. Студенто-часы преподавателя.
-- Студенто-час: один час дисциплины на одного студента группы.
-- Объём испытания = часы дисциплины × численность группы,
-- и он относится к преподавателю, который это испытание принимает.
-- Показатель нужен для последующего расчёта оплаты педагогической нагрузки.
-- Место внутри кафедры используется только для сортировки.
-- Коррелированный подзапрос оставляет преподавателей, у которых студенто-часов
-- не меньше среднего по их кафедре.

WITH "ExamLoad" AS (
    SELECT
        t."Id" AS "TeacherId",
        t."FullName",
        s."Department",
        e."Id" AS "ExamSessionId",
        s."TotalHours" * g."StudentCount" AS "StudentHours"
    FROM exam."Teachers" AS t
    JOIN exam."ExamSessions" AS e
        ON e."TeacherId" = t."Id"
    JOIN exam."Subjects" AS s
        ON s."Id" = e."SubjectId"
    JOIN exam."StudentGroups" AS g
        ON g."Id" = e."StudentGroupId"
),
"TeacherLoad" AS (
    SELECT
        "TeacherId",
        "FullName",
        "Department",
        COUNT("ExamSessionId") AS "ExamCount",
        SUM("StudentHours") AS "StudentHours"
    FROM "ExamLoad"
    GROUP BY "TeacherId", "FullName", "Department"
)
SELECT
    "FullName" AS "Преподаватель",
    "Department" AS "Кафедра",
    "StudentHours" AS "Студенто-часы"
FROM "TeacherLoad"
WHERE "StudentHours" >= (
    SELECT AVG(load."StudentHours")
    FROM "TeacherLoad" AS load
    WHERE load."Department" = "TeacherLoad"."Department"
)
ORDER BY
    "Кафедра",
    RANK() OVER (
        PARTITION BY "Department"
        ORDER BY "StudentHours" DESC
    ),
    "Преподаватель";

-- 4. Расписание экзаменов групп.
-- Строка расписания: группа, предмет, форма контроля и дата.
-- Сначала строки собираются по группе, внутри группы — по дате экзамена.

WITH "GroupExams" AS (
    SELECT
        g."Id" AS "GroupId",
        COUNT(e."Id") AS "ExamCount"
    FROM exam."StudentGroups" AS g
    JOIN exam."ExamSessions" AS e
        ON e."StudentGroupId" = g."Id"
    GROUP BY g."Id"
),
"GroupSchedule" AS (
    SELECT
        g."GroupCode",
        s."SubjectName",
        e."AssessmentType",
        e."ExamDate",
        ROW_NUMBER() OVER (
            PARTITION BY g."Id"
            ORDER BY e."ExamDate", s."SubjectName"
        ) AS "ExamNumber"
    FROM exam."StudentGroups" AS g
    JOIN "GroupExams" AS ge
        ON ge."GroupId" = g."Id"
    JOIN exam."ExamSessions" AS e
        ON e."StudentGroupId" = g."Id"
    JOIN exam."Subjects" AS s
        ON s."Id" = e."SubjectId"
)
SELECT
    "GroupCode" AS "Группа",
    "SubjectName" AS "Предмет экзамена",
    "AssessmentType" AS "Тип экзамена",
    "ExamDate" AS "Дата"
FROM "GroupSchedule"
ORDER BY "Группа", "Дата", "ExamNumber";

