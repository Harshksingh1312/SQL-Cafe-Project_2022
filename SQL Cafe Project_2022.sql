-- SQL Cafe Project: Customer Transactions, Loyalty Program, and Sales Analysis

-- Create Database
CREATE DATABASE SQL_TEXTBOOK;
USE SQL_TEXTBOOK; 

-- Create Tables
CREATE TABLE transactions (cutomer_id VARCHAR(5), transaction_date DATE, product_id INT); 
ALTER TABLE transactions RENAME COLUMN cutomer_id TO customer_id;

INSERT INTO transactions (customer_id, transaction_date, product_id)
VALUES
('A', '2022-03-01', '1'),
('A', '2022-03-01', '2'),
('A', '2022-03-03', '3'),
('A', '2022-03-05', '3'),
('A', '2022-03-07', '1'),
('B', '2022-03-02', '2'),
('B', '2022-03-03', '2'),
('B', '2022-03-06', '3'),
('B', '2022-03-08', '3'),
('B', '2022-03-10', '1'),
('C', '2022-03-01', '3'),
('C', '2022-03-02', '3'),
('C', '2022-03-03', '2'),
('C', '2022-03-05', '1'),
('C', '2022-03-06', '1');

CREATE TABLE menu (product_id INT, product_name VARCHAR(20), price INT);

INSERT INTO menu (product_id, product_name, price)
VALUES
('1', 'espresso', '5'),
('2', 'sandwich', '10'),
('3', 'latte', '8');

CREATE TABLE loyalty_members (customer_id VARCHAR(1), join_date DATE);

INSERT INTO loyalty_members (customer_id, join_date)
VALUES 
('A', '2022-03-04'),
('B', '2022-03-07');

-- Queries:

-- 1. Total amount spent by each customer
SELECT t.customer_id, SUM(m.price) AS TOTAL_AMOUNT
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
GROUP BY t.customer_id;

-- 2. Number of visits by each customer
SELECT t.customer_id, COUNT(*) AS visit_count
FROM transactions t
GROUP BY t.customer_id;

-- 3. First item purchased by each customer
SELECT t.customer_id, t.transaction_date, m.product_name
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
WHERE t.transaction_date = (
    SELECT MIN(t2.transaction_date) 
    FROM transactions t2
    WHERE t2.customer_id = t.customer_id
);

-- 4. Most frequently purchased item
SELECT m.product_name, COUNT(t.product_id) AS TOTAL_COUNT
FROM menu m
JOIN transactions t ON m.product_id = t.product_id
GROUP BY m.product_name, m.product_id;

-- 5. Customer who spent the most overall
SELECT t.customer_id, SUM(m.price) AS TOTAL_SPENT
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
GROUP BY t.customer_id
ORDER BY TOTAL_SPENT DESC;

-- 6. First item purchased after becoming a loyalty member
SELECT t.customer_id, m.product_name, t.transaction_date
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
JOIN loyalty_members l ON t.customer_id = l.customer_id
WHERE t.transaction_date >= l.join_date
AND t.transaction_date = (
    SELECT MIN(t2.transaction_date)
    FROM transactions t2
    WHERE t2.customer_id = t.customer_id
      AND t2.transaction_date >= l.join_date
);

-- 7. Total spent before becoming a loyalty member
SELECT t.customer_id, SUM(m.price) AS Total_Spent_BLM
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
JOIN loyalty_members l ON t.customer_id = l.customer_id
WHERE t.transaction_date <= l.join_date
GROUP BY t.customer_id;

-- 8. Item purchased just before becoming a member
SELECT t.customer_id, m.product_name, t.transaction_date, l.join_date
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
JOIN loyalty_members l ON t.customer_id = l.customer_id
WHERE t.transaction_date <= l.join_date
AND t.transaction_date = (
    SELECT MAX(t2.transaction_date) 
    FROM transactions t2
    WHERE t2.customer_id = t.customer_id
      AND t2.transaction_date <= l.join_date
);

-- 9. Points system (espresso = 3x points, others = 1x, $1 = 10 points)
SELECT t.customer_id, 
SUM(CASE WHEN m.product_name = "espresso" THEN m.price*10*3
         ELSE m.price*10 END) AS Points
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
GROUP BY t.customer_id
ORDER BY t.customer_id;

-- 10. Double points in first 10 days after joining
SELECT t.customer_id,
SUM(CASE 
        WHEN t.transaction_date BETWEEN l.join_date AND DATE_ADD(l.join_date, INTERVAL 9 DAY)
        THEN CASE WHEN m.product_name ="espresso" THEN m.price*10*3*2 ELSE m.price*10*2 END
        ELSE CASE WHEN m.product_name ="espresso" THEN m.price*10*3 ELSE m.price*10 END
    END) AS Total_Points
FROM transactions t 
JOIN menu m ON t.product_id = m.product_id
JOIN loyalty_members l ON t.customer_id = l.customer_id
WHERE t.transaction_date <= '2022-03-31'
GROUP BY t.customer_id
ORDER BY t.customer_id;

-- 11. Total revenue by item
SELECT m.product_id, m.product_name, SUM(m.price) AS Total_Revenue
FROM menu m 
JOIN transactions t ON m.product_id = t.product_id
GROUP BY m.product_id, m.product_name;

-- 12. Day with highest sales
SELECT t.transaction_date, SUM(m.price) AS Daily_Sales
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
GROUP BY t.transaction_date
ORDER BY Daily_Sales DESC
LIMIT 1;

-- 13. Unique customers visited in March
SELECT COUNT(DISTINCT t.customer_id) AS Unique_Customers
FROM transactions t 
WHERE MONTH(t.transaction_date) = 3
AND YEAR(t.transaction_date) = 2022;

-- 14. Percentage of sales from loyalty vs non-members
SELECT  
    CASE WHEN l.customer_id IS NOT NULL THEN 'Loyalty Members' ELSE 'Non-Members' END AS Customer_Type,
    SUM(m.price) AS Total_Sales,
    ROUND(100* SUM(m.price) / (SELECT SUM(m2.price) FROM transactions t2 
                               JOIN menu m2 ON t2.product_id = m2.product_id),2) AS Percentage_Sales
FROM transactions t
JOIN menu m ON t.product_id = m.product_id
LEFT JOIN loyalty_members l ON t.customer_id = l.customer_id
GROUP BY Customer_Type;

-- 15. Highest revenue item
SELECT m.product_name, SUM(m.price) AS Menu_Revenue
FROM menu m 
JOIN transactions t ON m.product_id = t.product_id
GROUP BY m.product_name
ORDER BY Menu_Revenue DESC
LIMIT 1;

-- 16. Customers who purchased all menu items
SELECT t.customer_id
FROM transactions t
GROUP BY t.customer_id
HAVING COUNT(DISTINCT t.product_id) = (SELECT COUNT(*) FROM menu);
