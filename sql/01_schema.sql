-- Практическое задание 1.2. Вариант 7.
-- Предметная область: учёт экзаменационных сессий учебных групп.
-- СУБД: PostgreSQL 16. Суррогатные ключи UUID задаются при вставке.

DROP SCHEMA IF EXISTS exam CASCADE;
CREATE SCHEMA exam;
SET search_path TO exam, public;

-- Стержневая сущность: факультет.
CREATE TABLE "Faculties" (
    "Id"   UUID PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL UNIQUE
);

-- Стержневая сущность: преподаватель.
CREATE TABLE "Teachers" (
    "Id"       UUID PRIMARY KEY,
    "FullName" VARCHAR(150) NOT NULL
);

-- Стержневая сущность: учебная группа.
CREATE TABLE "StudentGroups" (
    "Id"           UUID PRIMARY KEY,
    "GroupCode"    VARCHAR(20) NOT NULL UNIQUE,
    "CourseYear"   SMALLINT    NOT NULL CHECK ("CourseYear" BETWEEN 1 AND 6),
    "StudentCount" INTEGER     NOT NULL CHECK ("StudentCount" >= 0),
    "FacultyId"    UUID        NOT NULL,

    CONSTRAINT "FK_StudentGroups_Faculties"
        FOREIGN KEY ("FacultyId") REFERENCES "Faculties" ("Id")
        ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX "IX_StudentGroups_FacultyId" ON "StudentGroups" ("FacultyId");

-- Стержневая сущность: учебная дисциплина.
CREATE TABLE "Subjects" (
    "Id"          UUID PRIMARY KEY,
    "SubjectName" VARCHAR(150) NOT NULL UNIQUE,
    "Department"  VARCHAR(100) NOT NULL,
    "TotalHours"  INTEGER      NOT NULL CHECK ("TotalHours" > 0)
);

-- Ассоциативная сущность: экзамен группы по дисциплине в конкретную дату.
CREATE TABLE "ExamSessions" (
    "Id"             UUID PRIMARY KEY,
    "StudentGroupId" UUID        NOT NULL,
    "SubjectId"      UUID        NOT NULL,
    "ExamDate"       DATE        NOT NULL,
    "TeacherId"      UUID        NOT NULL,
    "AssessmentType" VARCHAR(50) NOT NULL
        CHECK ("AssessmentType" IN ('Экзамен', 'Зачёт', 'Дифференцированный зачёт')),

    CONSTRAINT "FK_ExamSessions_StudentGroups"
        FOREIGN KEY ("StudentGroupId") REFERENCES "StudentGroups" ("Id")
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT "FK_ExamSessions_Subjects"
        FOREIGN KEY ("SubjectId") REFERENCES "Subjects" ("Id")
        ON UPDATE CASCADE ON DELETE CASCADE,

    CONSTRAINT "FK_ExamSessions_Teachers"
        FOREIGN KEY ("TeacherId") REFERENCES "Teachers" ("Id")
        ON UPDATE CASCADE ON DELETE RESTRICT,

    CONSTRAINT "UQ_ExamSessions_Group_Subject_Date"
        UNIQUE ("StudentGroupId", "SubjectId", "ExamDate")
);

CREATE INDEX "IX_ExamSessions_StudentGroupId" ON "ExamSessions" ("StudentGroupId");
CREATE INDEX "IX_ExamSessions_SubjectId" ON "ExamSessions" ("SubjectId");
CREATE INDEX "IX_ExamSessions_TeacherId" ON "ExamSessions" ("TeacherId");

COMMENT ON TABLE "Faculties" IS 'Факультет: наименование';
COMMENT ON TABLE "Teachers" IS 'Преподаватель: ФИО';
COMMENT ON TABLE "StudentGroups" IS 'Учебная группа: код, курс, численность, факультет';
COMMENT ON TABLE "Subjects" IS 'Дисциплина: название, кафедра, объём в часах';
COMMENT ON TABLE "ExamSessions" IS 'Экзамен: группа, дисциплина, дата, преподаватель, форма контроля';