--
-- PostgreSQL database dump
--

\restrict dTzJrt941jM5q2n3VrWBo0UaKf0TZ4VqiLMhILe2bCrpHAfhEVkPPit8HqkCUHQ

-- Dumped from database version 16.15 (Debian 16.15-1.pgdg13+2)
-- Dumped by pg_dump version 16.15 (Debian 16.15-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: exam; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA exam;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ExamSessions; Type: TABLE; Schema: exam; Owner: -
--

CREATE TABLE exam."ExamSessions" (
    "Id" uuid NOT NULL,
    "StudentGroupId" uuid NOT NULL,
    "SubjectId" uuid NOT NULL,
    "ExamDate" date NOT NULL,
    "TeacherId" uuid NOT NULL,
    "AssessmentType" character varying(50) NOT NULL,
    CONSTRAINT "ExamSessions_AssessmentType_check" CHECK ((("AssessmentType")::text = ANY ((ARRAY['Экзамен'::character varying, 'Зачёт'::character varying, 'Дифференцированный зачёт'::character varying])::text[])))
);


--
-- Name: TABLE "ExamSessions"; Type: COMMENT; Schema: exam; Owner: -
--

COMMENT ON TABLE exam."ExamSessions" IS 'Экзамен: группа, дисциплина, дата, преподаватель, форма контроля';


--
-- Name: Faculties; Type: TABLE; Schema: exam; Owner: -
--

CREATE TABLE exam."Faculties" (
    "Id" uuid NOT NULL,
    "Name" character varying(100) NOT NULL
);


--
-- Name: TABLE "Faculties"; Type: COMMENT; Schema: exam; Owner: -
--

COMMENT ON TABLE exam."Faculties" IS 'Факультет: наименование';


--
-- Name: StudentGroups; Type: TABLE; Schema: exam; Owner: -
--

CREATE TABLE exam."StudentGroups" (
    "Id" uuid NOT NULL,
    "GroupCode" character varying(20) NOT NULL,
    "CourseYear" smallint NOT NULL,
    "StudentCount" integer NOT NULL,
    "FacultyId" uuid NOT NULL,
    CONSTRAINT "StudentGroups_CourseYear_check" CHECK ((("CourseYear" >= 1) AND ("CourseYear" <= 6))),
    CONSTRAINT "StudentGroups_StudentCount_check" CHECK (("StudentCount" >= 0))
);


--
-- Name: TABLE "StudentGroups"; Type: COMMENT; Schema: exam; Owner: -
--

COMMENT ON TABLE exam."StudentGroups" IS 'Учебная группа: код, курс, численность, факультет';


--
-- Name: Subjects; Type: TABLE; Schema: exam; Owner: -
--

CREATE TABLE exam."Subjects" (
    "Id" uuid NOT NULL,
    "SubjectName" character varying(150) NOT NULL,
    "Department" character varying(100) NOT NULL,
    "TotalHours" integer NOT NULL,
    CONSTRAINT "Subjects_TotalHours_check" CHECK (("TotalHours" > 0))
);


--
-- Name: TABLE "Subjects"; Type: COMMENT; Schema: exam; Owner: -
--

COMMENT ON TABLE exam."Subjects" IS 'Дисциплина: название, кафедра, объём в часах';


--
-- Name: Teachers; Type: TABLE; Schema: exam; Owner: -
--

CREATE TABLE exam."Teachers" (
    "Id" uuid NOT NULL,
    "FullName" character varying(150) NOT NULL
);


--
-- Name: TABLE "Teachers"; Type: COMMENT; Schema: exam; Owner: -
--

COMMENT ON TABLE exam."Teachers" IS 'Преподаватель: ФИО';


--
-- Data for Name: ExamSessions; Type: TABLE DATA; Schema: exam; Owner: -
--

COPY exam."ExamSessions" ("Id", "StudentGroupId", "SubjectId", "ExamDate", "TeacherId", "AssessmentType") FROM stdin;
a5000001-0000-4000-8000-000000000001	a3000001-0000-4000-8000-000000000001	a4000001-0000-4000-8000-000000000001	2026-01-12	a2000001-0000-4000-8000-000000000001	Экзамен
a5000001-0000-4000-8000-000000000002	a3000001-0000-4000-8000-000000000001	a4000001-0000-4000-8000-000000000002	2026-01-19	a2000001-0000-4000-8000-000000000003	Экзамен
a5000001-0000-4000-8000-000000000003	a3000001-0000-4000-8000-000000000001	a4000001-0000-4000-8000-000000000004	2026-01-09	a2000001-0000-4000-8000-000000000005	Экзамен
a5000001-0000-4000-8000-000000000004	a3000001-0000-4000-8000-000000000002	a4000001-0000-4000-8000-000000000001	2026-01-14	a2000001-0000-4000-8000-000000000001	Экзамен
a5000001-0000-4000-8000-000000000005	a3000001-0000-4000-8000-000000000002	a4000001-0000-4000-8000-000000000003	2026-01-18	a2000001-0000-4000-8000-000000000002	Экзамен
a5000001-0000-4000-8000-000000000006	a3000001-0000-4000-8000-000000000002	a4000001-0000-4000-8000-000000000008	2026-01-11	a2000001-0000-4000-8000-000000000006	Экзамен
a5000001-0000-4000-8000-000000000007	a3000001-0000-4000-8000-000000000003	a4000001-0000-4000-8000-000000000004	2026-06-05	a2000001-0000-4000-8000-000000000005	Дифференцированный зачёт
a5000001-0000-4000-8000-000000000008	a3000001-0000-4000-8000-000000000003	a4000001-0000-4000-8000-000000000001	2026-06-10	a2000001-0000-4000-8000-000000000001	Зачёт
a5000001-0000-4000-8000-000000000009	a3000001-0000-4000-8000-000000000003	a4000001-0000-4000-8000-000000000007	2026-06-08	a2000001-0000-4000-8000-000000000006	Экзамен
a5000001-0000-4000-8000-00000000000a	a3000001-0000-4000-8000-000000000004	a4000001-0000-4000-8000-000000000001	2026-01-16	a2000001-0000-4000-8000-000000000002	Экзамен
a5000001-0000-4000-8000-00000000000b	a3000001-0000-4000-8000-000000000004	a4000001-0000-4000-8000-000000000003	2026-01-13	a2000001-0000-4000-8000-000000000002	Экзамен
a5000001-0000-4000-8000-00000000000c	a3000001-0000-4000-8000-000000000005	a4000001-0000-4000-8000-000000000002	2026-01-21	a2000001-0000-4000-8000-000000000003	Дифференцированный зачёт
a5000001-0000-4000-8000-00000000000d	a3000001-0000-4000-8000-000000000006	a4000001-0000-4000-8000-000000000002	2026-01-23	a2000001-0000-4000-8000-000000000003	Зачёт
a5000001-0000-4000-8000-00000000000e	a3000001-0000-4000-8000-000000000007	a4000001-0000-4000-8000-000000000006	2026-01-26	a2000001-0000-4000-8000-000000000005	Экзамен
a5000001-0000-4000-8000-00000000000f	a3000001-0000-4000-8000-000000000007	a4000001-0000-4000-8000-000000000008	2026-06-15	a2000001-0000-4000-8000-000000000006	Зачёт
a5000001-0000-4000-8000-000000000010	a3000001-0000-4000-8000-000000000007	a4000001-0000-4000-8000-000000000007	2026-06-08	a2000001-0000-4000-8000-000000000006	Экзамен
a5000001-0000-4000-8000-000000000011	a3000001-0000-4000-8000-000000000008	a4000001-0000-4000-8000-000000000007	2026-01-15	a2000001-0000-4000-8000-000000000006	Экзамен
a5000001-0000-4000-8000-000000000012	a3000001-0000-4000-8000-000000000009	a4000001-0000-4000-8000-000000000009	2026-01-22	a2000001-0000-4000-8000-000000000004	Экзамен
a5000001-0000-4000-8000-000000000013	a3000001-0000-4000-8000-000000000009	a4000001-0000-4000-8000-00000000000a	2026-06-06	a2000001-0000-4000-8000-000000000004	Экзамен
a5000001-0000-4000-8000-000000000014	a3000001-0000-4000-8000-00000000000a	a4000001-0000-4000-8000-00000000000a	2026-01-27	a2000001-0000-4000-8000-000000000004	Дифференцированный зачёт
a5000001-0000-4000-8000-000000000015	a3000001-0000-4000-8000-00000000000b	a4000001-0000-4000-8000-00000000000b	2026-01-29	a2000001-0000-4000-8000-000000000007	Экзамен
a5000001-0000-4000-8000-000000000016	a3000001-0000-4000-8000-00000000000c	a4000001-0000-4000-8000-00000000000b	2026-01-30	a2000001-0000-4000-8000-000000000007	Экзамен
\.


--
-- Data for Name: Faculties; Type: TABLE DATA; Schema: exam; Owner: -
--

COPY exam."Faculties" ("Id", "Name") FROM stdin;
a1000001-0000-4000-8000-000000000001	Институт компьютерных наук
a1000001-0000-4000-8000-000000000002	Институт прикладной математики
a1000001-0000-4000-8000-000000000003	Инженерно-экономический институт
a1000001-0000-4000-8000-000000000004	Механико-технологический институт
\.


--
-- Data for Name: StudentGroups; Type: TABLE DATA; Schema: exam; Owner: -
--

COPY exam."StudentGroups" ("Id", "GroupCode", "CourseYear", "StudentCount", "FacultyId") FROM stdin;
a3000001-0000-4000-8000-000000000001	ИВТ-21	4	24	a1000001-0000-4000-8000-000000000001
a3000001-0000-4000-8000-000000000002	ИВТ-22	3	26	a1000001-0000-4000-8000-000000000001
a3000001-0000-4000-8000-000000000003	ИВТ-23	2	28	a1000001-0000-4000-8000-000000000001
a3000001-0000-4000-8000-000000000004	ПИ-21	4	22	a1000001-0000-4000-8000-000000000001
a3000001-0000-4000-8000-000000000005	ПИ-22	3	25	a1000001-0000-4000-8000-000000000001
a3000001-0000-4000-8000-000000000006	ИБ-23	2	23	a1000001-0000-4000-8000-000000000001
a3000001-0000-4000-8000-000000000007	ПМ-21	4	20	a1000001-0000-4000-8000-000000000002
a3000001-0000-4000-8000-000000000008	ПМ-22	3	21	a1000001-0000-4000-8000-000000000002
a3000001-0000-4000-8000-000000000009	ЭК-21	4	30	a1000001-0000-4000-8000-000000000003
a3000001-0000-4000-8000-00000000000a	ЭК-22	3	27	a1000001-0000-4000-8000-000000000003
a3000001-0000-4000-8000-00000000000b	МТ-21	4	18	a1000001-0000-4000-8000-000000000004
a3000001-0000-4000-8000-00000000000c	МТ-22	3	19	a1000001-0000-4000-8000-000000000004
\.


--
-- Data for Name: Subjects; Type: TABLE DATA; Schema: exam; Owner: -
--

COPY exam."Subjects" ("Id", "SubjectName", "Department", "TotalHours") FROM stdin;
a4000001-0000-4000-8000-000000000001	Базы данных	Кафедра вычислительных систем	144
a4000001-0000-4000-8000-000000000002	Операционные системы	Кафедра вычислительных систем	108
a4000001-0000-4000-8000-000000000003	Компьютерные сети	Кафедра вычислительных систем	108
a4000001-0000-4000-8000-000000000004	Программирование	Кафедра программного обеспечения	144
a4000001-0000-4000-8000-000000000005	Информационная безопасность	Кафедра защиты информации	108
a4000001-0000-4000-8000-000000000006	Алгоритмы и структуры данных	Кафедра прикладной математики	108
a4000001-0000-4000-8000-000000000007	Дискретная математика	Кафедра прикладной математики	72
a4000001-0000-4000-8000-000000000008	Математический анализ	Кафедра прикладной математики	144
a4000001-0000-4000-8000-000000000009	Экономика предприятия	Кафедра экономики	108
a4000001-0000-4000-8000-00000000000a	Бухгалтерский учёт	Кафедра экономики	72
a4000001-0000-4000-8000-00000000000b	Технология машиностроения	Кафедра технологии машиностроения	144
a4000001-0000-4000-8000-00000000000c	Материаловедение	Кафедра технологии машиностроения	72
a4000001-0000-4000-8000-00000000000d	Философия	Кафедра гуманитарных наук	72
\.


--
-- Data for Name: Teachers; Type: TABLE DATA; Schema: exam; Owner: -
--

COPY exam."Teachers" ("Id", "FullName") FROM stdin;
a2000001-0000-4000-8000-000000000001	Соколова Анна Петровна
a2000001-0000-4000-8000-000000000002	Орлов Игорь Сергеевич
a2000001-0000-4000-8000-000000000003	Кузнецов Павел Андреевич
a2000001-0000-4000-8000-000000000004	Белова Мария Олеговна
a2000001-0000-4000-8000-000000000005	Морозова Елена Викторовна
a2000001-0000-4000-8000-000000000006	Волков Дмитрий Игоревич
a2000001-0000-4000-8000-000000000007	Ершов Сергей Павлович
a2000001-0000-4000-8000-000000000008	Новикова Ольга Дмитриевна
\.


--
-- Name: ExamSessions ExamSessions_pkey; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."ExamSessions"
    ADD CONSTRAINT "ExamSessions_pkey" PRIMARY KEY ("Id");


--
-- Name: Faculties Faculties_Name_key; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."Faculties"
    ADD CONSTRAINT "Faculties_Name_key" UNIQUE ("Name");


--
-- Name: Faculties Faculties_pkey; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."Faculties"
    ADD CONSTRAINT "Faculties_pkey" PRIMARY KEY ("Id");


--
-- Name: StudentGroups StudentGroups_GroupCode_key; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."StudentGroups"
    ADD CONSTRAINT "StudentGroups_GroupCode_key" UNIQUE ("GroupCode");


--
-- Name: StudentGroups StudentGroups_pkey; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."StudentGroups"
    ADD CONSTRAINT "StudentGroups_pkey" PRIMARY KEY ("Id");


--
-- Name: Subjects Subjects_SubjectName_key; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."Subjects"
    ADD CONSTRAINT "Subjects_SubjectName_key" UNIQUE ("SubjectName");


--
-- Name: Subjects Subjects_pkey; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."Subjects"
    ADD CONSTRAINT "Subjects_pkey" PRIMARY KEY ("Id");


--
-- Name: Teachers Teachers_pkey; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."Teachers"
    ADD CONSTRAINT "Teachers_pkey" PRIMARY KEY ("Id");


--
-- Name: ExamSessions UQ_ExamSessions_Group_Subject_Date; Type: CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."ExamSessions"
    ADD CONSTRAINT "UQ_ExamSessions_Group_Subject_Date" UNIQUE ("StudentGroupId", "SubjectId", "ExamDate");


--
-- Name: IX_ExamSessions_StudentGroupId; Type: INDEX; Schema: exam; Owner: -
--

CREATE INDEX "IX_ExamSessions_StudentGroupId" ON exam."ExamSessions" USING btree ("StudentGroupId");


--
-- Name: IX_ExamSessions_SubjectId; Type: INDEX; Schema: exam; Owner: -
--

CREATE INDEX "IX_ExamSessions_SubjectId" ON exam."ExamSessions" USING btree ("SubjectId");


--
-- Name: IX_ExamSessions_TeacherId; Type: INDEX; Schema: exam; Owner: -
--

CREATE INDEX "IX_ExamSessions_TeacherId" ON exam."ExamSessions" USING btree ("TeacherId");


--
-- Name: IX_StudentGroups_FacultyId; Type: INDEX; Schema: exam; Owner: -
--

CREATE INDEX "IX_StudentGroups_FacultyId" ON exam."StudentGroups" USING btree ("FacultyId");


--
-- Name: ExamSessions FK_ExamSessions_StudentGroups; Type: FK CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."ExamSessions"
    ADD CONSTRAINT "FK_ExamSessions_StudentGroups" FOREIGN KEY ("StudentGroupId") REFERENCES exam."StudentGroups"("Id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ExamSessions FK_ExamSessions_Subjects; Type: FK CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."ExamSessions"
    ADD CONSTRAINT "FK_ExamSessions_Subjects" FOREIGN KEY ("SubjectId") REFERENCES exam."Subjects"("Id") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: ExamSessions FK_ExamSessions_Teachers; Type: FK CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."ExamSessions"
    ADD CONSTRAINT "FK_ExamSessions_Teachers" FOREIGN KEY ("TeacherId") REFERENCES exam."Teachers"("Id") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- Name: StudentGroups FK_StudentGroups_Faculties; Type: FK CONSTRAINT; Schema: exam; Owner: -
--

ALTER TABLE ONLY exam."StudentGroups"
    ADD CONSTRAINT "FK_StudentGroups_Faculties" FOREIGN KEY ("FacultyId") REFERENCES exam."Faculties"("Id") ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- PostgreSQL database dump complete
--

\unrestrict dTzJrt941jM5q2n3VrWBo0UaKf0TZ4VqiLMhILe2bCrpHAfhEVkPPit8HqkCUHQ

