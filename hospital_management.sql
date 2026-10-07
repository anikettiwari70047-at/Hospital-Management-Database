# 1.Physicians who are the department heads
SELECT p.employeeid,p.name,d.departmentid,d.name
FROM physician p
JOIN department d
ON p.employeeid=d.head;

# 2.Floor and block where room number 212 is located
SELECT roomnumber,blockfloor,blockcode 
FROM room
WHERE roomnumber=212;

# 3. Number of unavailable rooms
SELECT COUNT(*) AS 'Number of unavailable rooms'
FROM room 
WHERE unavailable='t';

-- 4. Identify the physician and the department with which he or she is affiliated
SELECT p.name AS physician_name, d.name as department_name
FROM physician p
JOIN affiliated_with a
ON p.employeeid = a.physician
JOIN department d
ON a.department = d.departmentid;

-- 5. Find those physicians who have received special training
SELECT DISTINCT p.name AS physician_name
FROM physician p
JOIN trained_in t
ON p.employeeid = t.physician;

-- 6. Identify the patients and the number of physicians with whom they have scheduled appointments
SELECT p.name AS patient_name, COUNT(DISTINCT a.physician) AS number_of_physicians
FROM patient p
JOIN appointment a
ON p.ssn = a.patient
GROUP BY p.ssn, p.name;

# 7.Number of unique patients who have been scheduled for examination room 'C'. 
SELECT COUNT(DISTINCT patient) AS `Number of patients scheduled for room C`
FROM appointment
WHERE examinationroom='C';

# 8.Number of available rooms for each floor in each block. 
SELECT blockfloor,blockcode,COUNT(*) AS `Number of available roos`
FROM room
WHERE unavailable='f'
GROUP BY blockfloor,blockcode;

# 9.Name of the patients, their block, floor, and room number where they are admitted.
CREATE VIEW view1 AS 
SELECT p.name,r.blockcode,r.blockfloor,s.room
FROM patient p
JOIN stay s 
ON p.ssn=s.patient
JOIN room r 
ON s.room=r.roomnumber;

SELECT * FROM view1;

-- 10. Find those patients who have undergone a procedure costing more than $5,000, 
-- as well as the name of the physician who has provided primary care, should be identified
SELECT p.name AS patient_name, ph.name AS primary_care_physician,  pr.name AS procedure_name, pr.cost
FROM patient p
JOIN undergoes u
ON p.ssn = u.patient
JOIN `procedure` pr
ON u.procedure = pr.code
JOIN physician ph
ON p.pcp = ph.employeeid
WHERE pr.cost > 5000;

-- 11. Identify those patients whose primary care is provided by a physician who is not the head of any department
SELECT name AS patient_name
FROM patient
WHERE pcp NOT IN (
	SELECT head FROM department
);

-- 12. Retrieve the names of patients who have been prescribed at least one medication by a physician from the Psychiatry department using a subquery
SELECT DISTINCT p.name as patient_name
FROM patient p
JOIN prescribes pr
ON p.ssn = pr.patient
WHERE pr.physician IN (
	SELECT aw.physician
    FROM affiliated_with aw
    JOIN department d
    ON aw.department = d.departmentid
    WHERE d.name = 'Psychiatry'
);

# 13.Trigger that prevents inserting a new appointment if the physician does not have a primary affiliation with a department.
DELIMITER $$
CREATE TRIGGER check_primary_affiliation
BEFORE INSERT ON appointment
FOR EACH ROW
BEGIN 
IF NOT EXISTS(
SELECT 1 
FROM affiliated_with 
WHERE physician=NEW.physician AND primaryaffiliation='t')
THEN SIGNAL SQLSTATE '45000'
SET MESSAGE_TEXT='Appointment cannot be created: Physician has no primary department affiliation.';
END IF;
END$$ 
DELIMITER ;

INSERT INTO appointment
(appointmentid, patient, prepnurse, physician, startdatetime, enddatetime, examinationroom)
VALUES
(99999991, 100000001, 101, 1, '2026-07-20 10:00', '2026-07-20 10:30', 'A');

SELECT  * FROM appointment;

INSERT INTO appointment
(appointmentid, patient, prepnurse, physician, startdatetime, enddatetime, examinationroom)
VALUES
(99999992, 100000001, 101, 15, '2026-07-20 11:00', '2026-07-20 11:30', 'B');

# 14.Updating the insurance ID of patients whose primary care physician (PCP) is 'John Dorian' to a new value '99999999'.
UPDATE patient p
JOIN physician ps
ON p.pcp=ps.employeeid
SET p.insuranceid=99999999
WHERE ps.name LIKE 'John Dorian';

SELECT * FROM patient;

# 15. Retrieving each physician's name along with the number of appointments they have
SELECT ps.employeeid,ps.name,COUNT(*) `Total number of appointments`,
RANK() OVER(ORDER BY COUNT(*) DESC) AS `Rank`
FROM physician ps
JOIN appointment a
ON ps.employeeid=a.physician
GROUP BY ps.employeeid,ps.name;