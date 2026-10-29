-- Практическое задание 1.3. Вариант 7. Обновление данных.
-- Запросы к схеме exam.

-- 1. Увеличить численность группы ИВТ-21 на 1 человека.
UPDATE exam."StudentGroups"
SET "StudentCount" = "StudentCount" + 1
WHERE "GroupCode" = 'ИВТ-21';

-- 2. Изменить форму контроля экзамена группы ПИ-21 по дисциплине Базы данных
--    с 16.01.2026 с экзамена на дифференцированный зачёт.
UPDATE exam."ExamSessions"
SET "AssessmentType" = 'Дифференцированный зачёт'
WHERE "StudentGroupId" = (SELECT "Id" FROM exam."StudentGroups" WHERE "GroupCode" = 'ПИ-21')
  AND "SubjectId" = (SELECT "Id" FROM exam."Subjects" WHERE "SubjectName" = 'Базы данных')
  AND "ExamDate" = DATE '2026-01-16';
