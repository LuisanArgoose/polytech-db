-- Практическое задание 1.3. Вариант 7. Удаление данных.
-- Запросы к схеме exam.

-- 1. Удалить все летние экзамены (июнь, июль, август), проходившие в форме зачёта.
DELETE FROM exam."ExamSessions"
WHERE "ExamDate" >= DATE '2026-06-01'
  AND "ExamDate" <  DATE '2026-09-01'
  AND "AssessmentType" = 'Зачёт';

-- 2. Удалить экономические дисциплины, которые ни разу не были назначены ни одной группе.
DELETE FROM exam."Subjects"
WHERE "Department" = 'Кафедра экономики'
  AND "Id" NOT IN (
      SELECT "SubjectId" FROM exam."ExamSessions"
  );

