
-- 1. Top 10 Customers by Total Spending

-- Approach 1: JOIN + GROUP BY
SELECT
  c.Customer_ID,
  c.Customer_Name,
  SUM(o.Total_Sales) AS total_spent
FROM customers c
JOIN Orders o
  ON c.Customer_Name = o.Customer_Name
GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY total_spent DESC
LIMIT 10;

-- Approach 2: EXISTS + Correlated Subquery
SELECT
  c.Customer_ID,
  c.Customer_Name,
  (
    SELECT SUM(o2.Total_Sales)
    FROM Orders o2
    WHERE o2.Customer_Name = c.Customer_Name
  ) AS total_spent
FROM customers c
WHERE EXISTS (
    SELECT 1
    FROM Orders o3
    WHERE o3.Customer_Name = c.Customer_Name
)
ORDER BY total_spent DESC
LIMIT 10;

-- Approach 3: Window Function
SELECT DISTINCT
  c.Customer_ID,
  c.Customer_Name,
  SUM(o.Total_Sales) OVER (PARTITION BY c.Customer_Name) AS total_spent,
  ROW_NUMBER() OVER (ORDER BY SUM(o.Total_Sales) OVER (PARTITION BY c.Customer_Name) DESC) AS rn
FROM customers c
JOIN Orders o
  ON c.Customer_Name = o.Customer_Name
WHERE rn <= 10;


-- 2. Distribution of Customers by Age Group and Gender

-- Approach 1: GROUP BY with CASE
SELECT
  CASE
    WHEN Age < 18 THEN '<18'
    WHEN Age BETWEEN 18 AND 25 THEN '18-25'
    WHEN Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN Age BETWEEN 36 AND 50 THEN '36-50'
    ELSE '>50'
  END AS age_group,
  Gender,
  COUNT(*) AS cnt
FROM customers
GROUP BY age_group, Gender;

-- Approach 2: Subquery for Age Groups + JOIN
WITH age_buckets AS (
  SELECT Customer_ID,
    CASE
      WHEN Age < 18 THEN '<18'
      WHEN Age BETWEEN 18 AND 25 THEN '18-25'
      WHEN Age BETWEEN 26 AND 35 THEN '26-35'
      WHEN Age BETWEEN 36 AND 50 THEN '36-50'
      ELSE '>50'
    END AS age_group
  FROM customers
)
SELECT
  ab.age_group,
  c.Gender,
  COUNT(*) AS cnt
FROM age_buckets ab
JOIN customers c USING(Customer_ID)
GROUP BY ab.age_group, c.Gender;

-- Approach 3: Window Function + FILTER
SELECT DISTINCT
  CASE
    WHEN Age < 18 THEN '<18'
    WHEN Age BETWEEN 18 AND 25 THEN '18-25'
    WHEN Age BETWEEN 26 AND 35 THEN '26-35'
    WHEN Age BETWEEN 36 AND 50 THEN '36-50'
    ELSE '>50'
  END AS age_group,
  Gender,
  COUNT(*) OVER (PARTITION BY 
    CASE
      WHEN Age < 18 THEN '<18'
      WHEN Age BETWEEN 18 AND 25 THEN '18-25'
      WHEN Age BETWEEN 26 AND 35 THEN '26-35'
      WHEN Age BETWEEN 36 AND 50 THEN '36-50'
      ELSE '>50'
    END,
    Gender
  ) AS cnt
FROM customers;

-- 3. Top 5 Best-Selling Products (by quantity)

-- Approach 1: JOIN + GROUP BY
SELECT
  p.Product_ID,
  p.Product_Name,
  SUM(o.Quantity) AS total_qty
FROM products p
JOIN Orders o
  ON p.Product_Name = o.Product
GROUP BY p.Product_ID, p.Product_Name
ORDER BY total_qty DESC
LIMIT 5;

-- Approach 2: EXISTS + Subquery
SELECT
  p.Product_ID,
  p.Product_Name,
  (
    SELECT SUM(o2.Quantity)
    FROM Orders o2
    WHERE o2.Product = p.Product_Name
  ) AS total_qty
FROM products p
WHERE EXISTS (
    SELECT 1 FROM Orders o3 WHERE o3.Product = p.Product_Name
)
ORDER BY total_qty DESC
LIMIT 5;

-- Approach 3: Window Function + ROW_NUMBER
SELECT DISTINCT
  p.Product_ID,
  p.Product_Name,
  SUM(o.Quantity) OVER (PARTITION BY p.Product_Name) AS total_qty,
  ROW_NUMBER() OVER (ORDER BY SUM(o.Quantity) OVER (PARTITION BY p.Product_Name) DESC) AS rn
FROM products p
JOIN Orders o
  ON p.Product_Name = o.Product
WHERE rn <= 5;

-- 4. Most Profitable Brands (Profit = Revenue - Cost)
-- Assuming Cost = Price * Quantity * some cost factor; here use Revenue only as proxy

-- Approach 1: JOIN + GROUP BY
SELECT
  p.Brand,
  SUM(o.Total_Sales) AS revenue
FROM products p
JOIN Orders o
  ON p.Product_Name = o.Product
GROUP BY p.Brand
ORDER BY revenue DESC;

-- Approach 2: Subquery + EXISTS
SELECT
  Brand,
  (
    SELECT SUM(o2.Total_Sales)
    FROM Orders o2
    JOIN products p2 ON p2.Product_Name = o2.Product
    WHERE p2.Brand = b.Brand
  ) AS revenue
FROM (SELECT DISTINCT Brand FROM products) b
WHERE EXISTS (
    SELECT 1 FROM Orders o3 JOIN products p3 ON p3.Product_Name = o3.Product WHERE p3.Brand = b.Brand
)
ORDER BY revenue DESC;

-- Approach 3: Window Function
SELECT DISTINCT
  p.Brand,
  SUM(o.Total_Sales) OVER (PARTITION BY p.Brand) AS revenue,
  RANK() OVER (ORDER BY SUM(o.Total_Sales) OVER (PARTITION BY p.Brand) DESC) AS rnk
FROM products p
JOIN Orders o
  ON p.Product_Name = o.Product
ORDER BY rnk;

-- 5. Total Monthly Revenue Over 12 Months

-- Approach 1: GROUP BY with DATE_TRUNC
SELECT
  DATE_TRUNC('month', Orders_Date) AS month,
  SUM(Total_Sales) AS revenue
FROM Orders
WHERE Orders_Date >= CURRENT_DATE - INTERVAL '1 year'
GROUP BY month
ORDER BY month;

-- Approach 2: Subquery
SELECT
  m.month,
  (SELECT SUM(o.Total_Sales) FROM Orders o WHERE DATE_TRUNC('month', o.Orders_Date)=m.month) AS revenue
FROM (
  SELECT generate_series(
    DATE_TRUNC('month', CURRENT_DATE - INTERVAL '11 months'),
    DATE_TRUNC('month', CURRENT_DATE),
    INTERVAL '1 month'
  ) AS month
) m;

-- Approach 3: Window Function
SELECT DISTINCT
  DATE_TRUNC('month', Orders_Date) AS month,
  SUM(Total_Sales) OVER (PARTITION BY DATE_TRUNC('month', Orders_Date)) AS revenue
FROM Orders
WHERE Orders_Date >= CURRENT_DATE - INTERVAL '1 year'
ORDER BY month;

-- 6. Common Payment Method Used by Customers

-- Approach 1: GROUP BY
SELECT
  Payment_Method,
  COUNT(*) AS cnt
FROM Orders
GROUP BY Payment_Method
ORDER BY cnt DESC;

-- Approach 2: EXISTS + Subquery
SELECT
  pmt,
  (SELECT COUNT(*) FROM Orders o WHERE o.Payment_Method = pm.pmt) AS cnt
FROM (SELECT DISTINCT Payment_Method AS pmt FROM Orders) pm
WHERE EXISTS (SELECT 1 FROM Orders o2 WHERE o2.Payment_Method = pm.pmt)
ORDER BY cnt DESC;

-- Approach 3: Window Function
SELECT DISTINCT
  Payment_Method,
  COUNT(*) OVER (PARTITION BY Payment_Method) AS cnt
FROM Orders
ORDER BY cnt DESC;

-- 7. Payment Methods Linked to Failed Transactions

-- Approach 1: JOIN + GROUP BY
SELECT
  pm.Payment_method,
  COUNT(*) AS failed_count
FROM payments pm
JOIN Orders o ON o.Order_ID = pm.Order_id
WHERE pm.Payment_status != 'Success'
GROUP BY pm.Payment_method;

-- Approach 2: EXISTS + Subquery
SELECT
  Payment_method,
  (
    SELECT COUNT(*) FROM payments p2 WHERE p2.Payment_method = p.Payment_method AND p2.Payment_status!='Success'
  ) AS failed_count
FROM payments p
WHERE EXISTS (
    SELECT 1 FROM payments p3 WHERE p3.Payment_method = p.Payment_method AND p3.Payment_status!='Success'
)
GROUP BY Payment_method;

-- Approach 3: Window Function
SELECT DISTINCT
  Payment_method,
  COUNT(*) OVER (PARTITION BY Payment_method) FILTER (WHERE Payment_status!='Success') AS failed_count
FROM payments;

-- 8. Average Payment Amount by Payment Method

-- Approach 1: GROUP BY
SELECT
  Payment_method,
  AVG(Paid_Amount) AS avg_amount
FROM payments
GROUP BY Payment_method;

-- Approach 2: Subquery with EXISTS
SELECT
  pmtd,
  (
    SELECT AVG(Paid_Amount) FROM payments p2 WHERE p2.Payment_method = pm.pmt
  ) AS avg_amount
FROM (SELECT DISTINCT Payment_method AS pmt FROM payments) pm;

-- Approach 3: Window Function
SELECT DISTINCT
  Payment_method,
  AVG(Paid_Amount) OVER (PARTITION BY Payment_method) AS avg_amount
FROM payments;

-- 9. Fastest Courier Company (by average delivery time)

-- Approach 1: JOIN + GROUP BY
SELECT
  Courier,
  AVG(Delivery_Date - Shipped_Date) AS avg_days
FROM shipping
GROUP BY Courier
ORDER BY avg_days ASC
LIMIT 1;

-- Approach 2: Subquery
SELECT
  Courier,
  (
    SELECT AVG(Delivery_Date - Shipped_Date) FROM shipping s2 WHERE s2.Courier = s.Courier
  ) AS avg_days
FROM shipping s
GROUP BY Courier
ORDER BY avg_days LIMIT 1;

-- Approach 3: Window Function
SELECT DISTINCT
  Courier,
  AVG(Delivery_Date - Shipped_Date) OVER (PARTITION BY Courier) AS avg_days,
  RANK() OVER (ORDER BY AVG(Delivery_Date - Shipped_Date) OVER (PARTITION BY Courier)) AS rnk
FROM shipping
WHERE rnk = 1;

-- 10. Orders Took More Than 7 Days

-- Approach 1: Simple WHERE
SELECT *
FROM Orders o
JOIN shipping s USING(Order_ID)
WHERE s.Delivery_Date - s.Shipped_Date > 7;

-- Approach 2: EXISTS
SELECT *
FROM Orders o
WHERE EXISTS (
  SELECT 1 FROM shipping s WHERE s.Order_ID=o.Order_ID AND s.Delivery_Date - s.Shipped_Date>7
);

-- Approach 3: Window Function
SELECT *
FROM (
  SELECT o.*, s.Delivery_Date - s.Shipped_Date AS delta_days,
    ROW_NUMBER() OVER (PARTITION BY o.Order_ID ORDER BY delta_days DESC) AS rn
  FROM Orders o
  JOIN shipping s USING(Order_ID)
) t
WHERE delta_days>7;

-- 11. Regions with Most Delayed Shipments (> Expected Date)

-- Approach 1: JOIN + GROUP BY
SELECT
  o.Customer_Location AS region,
  COUNT(*) AS delayed_count
FROM Orders o
JOIN shipping s USING(Order_ID)
WHERE s.Shipping_Status = 'Delayed'
GROUP BY region
ORDER BY delayed_count DESC;

-- Approach 2: EXISTS
SELECT
  region,
  (
    SELECT COUNT(*) FROM Orders o2 JOIN shipping s2 USING(Order_ID)
    WHERE o2.Customer_Location=t.region AND s2.Shipping_Status='Delayed'
  ) AS delayed_count
FROM (
  SELECT DISTINCT Customer_Location AS region FROM Orders
) t
ORDER BY delayed_count DESC;

-- Approach 3: Window Function
SELECT DISTINCT
  Customer_Location AS region,
  COUNT(*) OVER (PARTITION BY Customer_Location) FILTER (WHERE Shipping_Status='Delayed') AS delayed_count
FROM Orders o
JOIN shipping s USING(Order_ID)
ORDER BY delayed_count DESC;

-- 12. Most Valuable and Engaged Customers (Total spent + #orders)

-- Approach 1: JOIN + GROUP BY + Derived engagement score
SELECT
  c.Customer_ID,
  c.Customer_Name,
  SUM(o.Total_Sales) AS total_spent,
  COUNT(o.Order_ID) AS order_count,
  (SUM(o.Total_Sales) * COUNT(o.Order_ID)) AS engagement_score
FROM customers c
JOIN Orders o USING(Customer_Name)
GROUP BY c.Customer_ID, c.Customer_Name
ORDER BY engagement_score DESC
LIMIT 10;

-- Approach 2: EXISTS + Subquery
SELECT
  c.Customer_ID,
  c.Customer_Name,
  (
    SELECT SUM(o2.Total_Sales) FROM Orders o2 WHERE o2.Customer_Name=c.Customer_Name
  ) AS total_spent,
  (
    SELECT COUNT(*) FROM Orders o3 WHERE o3.Customer_Name=c.Customer_Name
  ) AS order_count
FROM customers c
WHERE EXISTS (SELECT 1 FROM Orders o4 WHERE o4.Customer_Name=c.Customer_Name)
ORDER BY (total_spent * order_count) DESC
LIMIT 10;

-- Approach 3: Window Function
SELECT DISTINCT
  c.Customer_ID,
  c.Customer_Name,
  SUM(o.Total_Sales) OVER (PARTITION BY c.Customer_Name) AS total_spent,
  COUNT(o.Order_ID) OVER (PARTITION BY c.Customer_Name) AS order_count,
  RANK() OVER (ORDER BY SUM(o.Total_Sales) OVER (PARTITION BY c.Customer_Name) * COUNT(o.Order_ID) OVER (PARTITION BY c.Customer_Name) DESC) AS rnk
FROM customers c
JOIN Orders o USING(Customer_Name)
WHERE rnk <= 10;

-- 13. Monthly Retention: % of users who signed up in each month returned for another purchase

-- Approach 1: CTE + JOIN
WITH signups AS (
  SELECT Customer_ID,
    DATE_TRUNC('month', Signup_Date) AS signup_month
  FROM customers
), purchases AS (
  SELECT Customer_Name,
    DATE_TRUNC('month', Orders_Date) AS purchase_month
  FROM Orders
)
SELECT
  s.signup_month,
  COUNT(DISTINCT s.Customer_ID) AS total_signed_up,
  COUNT(DISTINCT CASE WHEN p.purchase_month > s.signup_month THEN c.Customer_ID END) AS returned_count,
  ROUND(
    100.0 * COUNT(DISTINCT CASE WHEN p.purchase_month > s.signup_month THEN c.Customer_ID END)
    / NULLIF(COUNT(DISTINCT s.Customer_ID),0),2
  ) AS retention_pct
FROM signups s
JOIN customers c USING(Customer_ID)
LEFT JOIN purchases p ON p.Customer_Name=c.Customer_Name
GROUP BY s.signup_month
ORDER BY s.signup_month;

-- Approach 2: EXISTS + Correlated
SELECT
  DATE_TRUNC('month', Signup_Date) AS signup_month,
  COUNT(*) AS total_signed_up,
  SUM(CASE WHEN EXISTS (
    SELECT 1 FROM Orders o WHERE o.Customer_Name=c.Customer_Name AND DATE_TRUNC('month',o.Orders_Date)>DATE_TRUNC('month',c.Signup_Date)
  ) THEN 1 ELSE 0 END) AS returned_count,
  ROUND(100.0 * SUM(CASE WHEN EXISTS (
    SELECT 1 FROM Orders o WHERE o.Customer_Name=c.Customer_Name AND DATE_TRUNC('month',o.Orders_Date)>DATE_TRUNC('month',c.Signup_Date)
  ) THEN 1 ELSE 0 END)::numeric / COUNT(*),2) AS retention_pct
FROM customers c
GROUP BY signup_month
ORDER BY signup_month;

-- Approach 3: Window + Flag
SELECT DISTINCT
  signup_month,
  total_signed_up,
  returned_count,
  ROUND(100.0 * returned_count::numeric / total_signed_up,2) AS retention_pct
FROM (
  SELECT
    Customer_ID,
    DATE_TRUNC('month', Signup_Date) AS signup_month,
    COUNT(*) OVER (PARTITION BY DATE_TRUNC('month', Signup_Date)) AS total_signed_up,
    MAX(CASE WHEN Orders_Date > Signup_Date THEN 1 ELSE 0 END) OVER (PARTITION BY Customer_ID, DATE_TRUNC('month', Signup_Date)) AS returned_flag,
    SUM(MAX(CASE WHEN Orders_Date > Signup_Date THEN 1 ELSE 0 END) OVER (PARTITION BY Customer_ID, DATE_TRUNC('month', Signup_Date)))
      OVER (PARTITION BY DATE_TRUNC('month', Signup_Date)) AS returned_count
  FROM customers c
  LEFT JOIN Orders o USING(Customer_Name)
) sub
ORDER BY signup_month;
