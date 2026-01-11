create database ola_sql;
use ola_sql;
drop table bookings;
CREATE TABLE bookings (
    Date DATETIME,
    Time TIME,
    Booking_ID VARCHAR(20),
    Booking_Status VARCHAR(50),
    Customer_ID VARCHAR(20),
    Vehicle_Type VARCHAR(20),
    Pickup_Location VARCHAR(100),
    Drop_Location VARCHAR(100),
    V_TAT INT,
    C_TAT INT,
    Canceled_Rides_by_Customer VARCHAR(255),
    Canceled_Rides_by_Driver VARCHAR(255),
    Incomplete_Rides VARCHAR(10),
    Incomplete_Rides_Reason VARCHAR(255),
    Booking_Value INT,
    Payment_Method VARCHAR(50),
    Ride_Distance INT,
    Driver_Ratings FLOAT,
    Customer_Rating FLOAT,
    Vehicle_Images TEXT
);


SET SESSION sql_mode = '';    
    
LOAD DATA LOCAL INFILE 'D:/Data Analytics project/OLA DA Project/End_To_End_ProjectFile_Date+Cleaned.csv'
INTO TABLE bookings
FIELDS TERMINATED BY ','
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;
  
select * from bookings;
SHOW VARIABLES LIKE 'secure_file_priv';
SELECT @@sql_mode;
-- 1. Retrieve all successful bookings
    select * from bookings where Booking_Status='Success';
-- 2. Find the average ride distance for each vehicle type
select Vehicle_Type,AVG(Ride_Distance) as Avg_Distance from bookings group by Vehicle_Type;

-- 3. Get the total number of canceled rides by customers
   select count(*) from bookings where Booking_Status='Canceled By Customer';

-- 4. List the top 5 customers who booked the highest number of rides
select Customer_id,count(Booking_Id) as total_rides from bookings group by customer_id order by total_rides desc limit 5;

-- 5. Get the number of rides canceled by drivers due to personal and car-related issues
Select count(*) from bookings where Canceled_Rides_by_Driver='Personal & Car related issue';

-- 6. Find the maximum and minimum driver ratings for Prime Sedan bookings
select max(Driver_Ratings) as max_rating,min(Driver_Ratings) from bookings where Vehicle_Type='Prime Sedan';
-- 7. Retrieve all rides where payment was made using UPI
select * from bookings where payment_method='UPI';

-- 8. Find the average customer rating per vehicle type
select Vehicle_Type,AVG(Customer_Rating) as avg_customer_rating from bookings group by Vehicle_Type;

-- 9. Calculate the total booking value of rides completed successfully
select sum(Booking_Value) as total_booking_value from bookings where Booking_Status='Success';

-- 10. List all incomplete rides along with the reason
SELECT Booking_ID, Incomplete_Rides_Reason
FROM bookings
WHERE Incomplete_Rides = 'Yes'
LIMIT 0, 1000;

-- 11. Calculate Revenue per Vehicle Type with Percentage Contribution
-- Show each vehicle's revenue and what % of total revenue it represents
SELECT 
    Vehicle_Type,
    SUM(Booking_Value) AS Total_Revenue,
    ROUND(SUM(Booking_Value) * 100.0 / (SELECT SUM(Booking_Value) FROM bookings WHERE Booking_Status = 'Success'), 2) AS Revenue_Percentage
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY Total_Revenue DESC;

-- 12. Calculate Success Rate by Vehicle Type
-- What % of bookings are successful for each vehicle?
SELECT 
    Vehicle_Type,
    COUNT(*) AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) AS Successful_Bookings,
    ROUND(SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Success_Rate_Percentage
FROM bookings
GROUP BY Vehicle_Type
ORDER BY Success_Rate_Percentage DESC;

-- 13. Revenue Lost Due to Cancellations
-- Estimate potential revenue lost from cancelled rides
SELECT 
    Booking_Status,
    COUNT(*) AS Ride_Count,
    ROUND(AVG(Booking_Value), 2) AS Avg_Booking_Value,
    ROUND(COUNT(*) * AVG(Booking_Value), 2) AS Estimated_Revenue_Impact
FROM bookings
WHERE Booking_Status IN ('Canceled by Customer', 'Canceled by Driver')
GROUP BY Booking_Status;

-- 14. Peak Hour Analysis
-- Identify busiest hours of the day
SELECT 
    HOUR(Time) AS Hour_of_Day,
    COUNT(*) AS Total_Bookings,
    SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) AS Successful_Bookings,
    ROUND(AVG(Booking_Value), 2) AS Avg_Booking_Value
FROM bookings
GROUP BY HOUR(Time)
ORDER BY Total_Bookings DESC;

-- 15. Customer Lifetime Value (CLV)
-- Find top customers by total spending
SELECT 
    Customer_ID,
    COUNT(*) AS Total_Rides,
    SUM(Booking_Value) AS Total_Spent,
    ROUND(AVG(Booking_Value), 2) AS Avg_Booking_Value,
    ROUND(AVG(Customer_Rating), 2) AS Avg_Rating
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Customer_ID
ORDER BY Total_Spent DESC
LIMIT 10;

-- 16. Categorize Booking Values
-- Classify bookings as Low/Medium/High value
SELECT 
    Booking_ID,
    Booking_Value,
    CASE 
        WHEN Booking_Value >= 500 THEN 'High Value'
        WHEN Booking_Value >= 300 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS Booking_Category
FROM bookings
WHERE Booking_Status = 'Success'
LIMIT 20;

-- 17. Categorize TAT Performance
-- Label rides based on vehicle arrival time
SELECT 
    Booking_ID,
    V_TAT,
    CASE 
        WHEN V_TAT <= 5 THEN 'Excellent'
        WHEN V_TAT <= 10 THEN 'Good'
        WHEN V_TAT <= 15 THEN 'Average'
        ELSE 'Poor'
    END AS TAT_Performance
FROM bookings
WHERE Booking_Status = 'Success'
LIMIT 20;

-- 18. Identify Peak vs Off-Peak Hours
-- Label bookings as peak or off-peak
SELECT 
    Booking_ID,
    Time,
    CASE 
        WHEN HOUR(Time) BETWEEN 6 AND 9 THEN 'Morning Peak'
        WHEN HOUR(Time) BETWEEN 17 AND 21 THEN 'Evening Peak'
        ELSE 'Off-Peak'
    END AS Time_Category,
    Booking_Value
FROM bookings
LIMIT 20;

-- 19. Peak Hour Revenue Analysis
-- Compare peak vs off-peak revenue
SELECT 
    CASE 
        WHEN HOUR(Time) BETWEEN 6 AND 9 THEN 'Morning Peak'
        WHEN HOUR(Time) BETWEEN 17 AND 21 THEN 'Evening Peak'
        ELSE 'Off-Peak'
    END AS Time_Period,
    COUNT(*) AS Total_Bookings,
    SUM(Booking_Value) AS Total_Revenue,
    ROUND(AVG(Booking_Value), 2) AS Avg_Revenue
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Time_Period
ORDER BY Total_Revenue DESC;

-- Category C: Subqueries
-- 20. Find Customers Who Spent Above Average
-- Customers spending more than the average
SELECT 
    Customer_ID,
    SUM(Booking_Value) AS Total_Spent
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Customer_ID
HAVING SUM(Booking_Value) > (
    SELECT AVG(total_spent) 
    FROM (
        SELECT SUM(Booking_Value) AS total_spent 
        FROM bookings 
        WHERE Booking_Status = 'Success' 
        GROUP BY Customer_ID
    ) AS customer_totals
)
ORDER BY Total_Spent DESC;

-- 21. Top 10% Revenue-Generating Bookings

-- Find bookings in the top 10% by value
SELECT 
    Booking_ID,
    Booking_Value,
    Vehicle_Type
FROM bookings
WHERE Booking_Value >= (
    SELECT Booking_Value
    FROM (
        SELECT 
            Booking_Value,
            PERCENT_RANK() OVER (ORDER BY Booking_Value) AS pr
        FROM bookings
        WHERE Booking_Status = 'Success'
    ) ranked
    WHERE pr >= 0.9
    ORDER BY pr
    LIMIT 1
)
ORDER BY Booking_Value DESC;

-- 22. Compare Each Vehicle's Revenue to Average
-- Show how each vehicle type performs vs average
SELECT 
    Vehicle_Type,
    SUM(Booking_Value) AS Total_Revenue,
    (SELECT AVG(vehicle_revenue) 
     FROM (
         SELECT SUM(Booking_Value) AS vehicle_revenue 
         FROM bookings 
         WHERE Booking_Status = 'Success' 
         GROUP BY Vehicle_Type
     ) AS avg_calc) AS Avg_Vehicle_Revenue,
    SUM(Booking_Value) - (SELECT AVG(vehicle_revenue) 
     FROM (
         SELECT SUM(Booking_Value) AS vehicle_revenue 
         FROM bookings 
         WHERE Booking_Status = 'Success' 
         GROUP BY Vehicle_Type
     ) AS avg_calc) AS Difference_From_Average
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Vehicle_Type
ORDER BY Total_Revenue DESC;

 -- LEVEL 3: Advanced SQL (Window Functions & CTEs)
-- Category A: Window Functions (RANK, ROW_NUMBER, etc.)
-- 23. Rank Customers by Total Spending
-- Rank customers and show their position
SELECT 
    Customer_ID,
    SUM(Booking_Value) AS Total_Spent,
    COUNT(*) AS Total_Rides,
    RANK() OVER (ORDER BY SUM(Booking_Value) DESC) AS Spending_Rank,
    ROW_NUMBER() OVER (ORDER BY SUM(Booking_Value) DESC) AS Row_Num
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Customer_ID
LIMIT 20;

-- 24. Rank Vehicle Types by Revenue Within Each Payment Method
-- Which vehicle type generates most revenue for each payment method?
SELECT 
    Payment_Method,
    Vehicle_Type,
    SUM(Booking_Value) AS Revenue,
    RANK() OVER (PARTITION BY Payment_Method ORDER BY SUM(Booking_Value) DESC) AS Revenue_Rank
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY Payment_Method, Vehicle_Type
ORDER BY Payment_Method, Revenue_Rank;

-- 25. Running Total of Revenue Over Time
-- Cumulative revenue day by day
SELECT 
    DATE(Date) AS Booking_Date,
    SUM(Booking_Value) AS Daily_Revenue,
    SUM(SUM(Booking_Value)) OVER (ORDER BY DATE(Date)) AS Cumulative_Revenue
FROM bookings
WHERE Booking_Status = 'Success'
GROUP BY DATE(Date)
ORDER BY Booking_Date;

-- 26. Moving Average of Daily Bookings (7-Day)

-- 7-day moving average of bookings
SELECT 
    DATE(Date) AS Booking_Date,
    COUNT(*) AS Daily_Bookings,
    AVG(COUNT(*)) OVER (
        ORDER BY DATE(Date) 
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS Moving_Avg_7_Days
FROM bookings
GROUP BY DATE(Date)
ORDER BY Booking_Date;

-- Category B: CTEs (Common Table Expressions)
-- 27. Multi-Step Analysis Using CTE
-- Find customers who cancelled more than 20% of their bookings
WITH customer_stats AS (
    SELECT 
        Customer_ID,
        COUNT(*) AS Total_Bookings,
        SUM(CASE WHEN Booking_Status = 'Canceled by Customer' THEN 1 ELSE 0 END) AS Cancelled_Bookings
    FROM bookings
    GROUP BY Customer_ID
),
cancellation_rates AS (
    SELECT 
        Customer_ID,
        Total_Bookings,
        Cancelled_Bookings,
        ROUND((Cancelled_Bookings * 100.0 / Total_Bookings), 2) AS Cancellation_Rate
    FROM customer_stats
)
SELECT *
FROM cancellation_rates
WHERE Cancellation_Rate > 20
ORDER BY Cancellation_Rate DESC;


-- 28. Vehicle Type Performance Dashboard Query
-- Complete vehicle analysis in one query
WITH vehicle_metrics AS (
    SELECT 
        Vehicle_Type,
        COUNT(*) AS Total_Bookings,
        SUM(CASE WHEN Booking_Status = 'Success' THEN 1 ELSE 0 END) AS Successful_Rides,
        SUM(Booking_Value) AS Total_Revenue,
        AVG(Ride_Distance) AS Avg_Distance,
        AVG(Driver_Ratings) AS Avg_Driver_Rating,
        AVG(Customer_Rating) AS Avg_Customer_Rating
    FROM bookings
    WHERE Booking_Status = 'Success'
    GROUP BY Vehicle_Type
)
SELECT 
    Vehicle_Type,
    Total_Bookings,
    Successful_Rides,
    ROUND((Successful_Rides * 100.0 / Total_Bookings), 2) AS Success_Rate,
    Total_Revenue,
    ROUND(Avg_Distance, 2) AS Avg_Distance_KM,
    ROUND(Avg_Driver_Rating, 2) AS Avg_Driver_Rating,
    ROUND(Avg_Customer_Rating, 2) AS Avg_Customer_Rating,
    ROUND(Total_Revenue / Successful_Rides, 2) AS Revenue_Per_Ride
FROM vehicle_metrics
ORDER BY Total_Revenue DESC;

-- 29. Customer Segmentation (RFM-Style Analysis)

-- Recency, Frequency, Monetary analysis
WITH customer_rfm AS (
    SELECT 
        Customer_ID,
        DATEDIFF(CURDATE(), MAX(Date)) AS Days_Since_Last_Ride,
        COUNT(*) AS Total_Rides,
        SUM(Booking_Value) AS Total_Spent
    FROM bookings
    WHERE Booking_Status = 'Success'
    GROUP BY Customer_ID
)
SELECT 
    Customer_ID,
    Days_Since_Last_Ride,
    Total_Rides,
    Total_Spent,
    CASE 
        WHEN Days_Since_Last_Ride <= 7 AND Total_Spent >= 2000 THEN 'VIP Active'
        WHEN Days_Since_Last_Ride <= 7 THEN 'Active'
        WHEN Days_Since_Last_Ride <= 30 AND Total_Spent >= 1000 THEN 'Regular'
        WHEN Days_Since_Last_Ride > 30 THEN 'At Risk'
        ELSE 'New'
    END AS Customer_Segment
FROM customer_rfm
ORDER BY Total_Spent DESC
LIMIT 50;


-- LEVEL 4: Expert SQL (Business Intelligence Queries)
-- 30. Cancellation Pattern Analysis

-- Deep dive into cancellation reasons
WITH cancellation_analysis AS (
    SELECT 
        COALESCE(Canceled_Rides_by_Customer, Canceled_Rides_by_Driver) AS Cancellation_Reason,
        Vehicle_Type,
        HOUR(Time) AS Hour_of_Day,
        COUNT(*) AS Cancellation_Count
    FROM bookings
    WHERE Booking_Status IN ('Canceled by Customer', 'Canceled by Driver')
    GROUP BY Cancellation_Reason, Vehicle_Type, HOUR(Time)
)
SELECT 
    Cancellation_Reason,
    Vehicle_Type,
    Hour_of_Day,
    Cancellation_Count,
    RANK() OVER (PARTITION BY Vehicle_Type ORDER BY Cancellation_Count DESC) AS Reason_Rank
FROM cancellation_analysis
WHERE Cancellation_Reason IS NOT NULL
ORDER BY Vehicle_Type, Reason_Rank
LIMIT 50;

-- 31. Location-Based Revenue Heatmap Data
-- Top pickup-drop location pairs by revenue
SELECT 
    Pickup_Location,
    Drop_Location,
    COUNT(*) AS Trip_Count,
    SUM(Booking_Value) AS Total_Revenue,
    ROUND(AVG(Booking_Value), 2) AS Avg_Fare,
    ROUND(AVG(Ride_Distance), 2) AS Avg_Distance,
    ROUND(SUM(Booking_Value) / SUM(Ride_Distance), 2) AS Revenue_Per_KM
FROM bookings
WHERE Booking_Status = 'Success' 
  AND Ride_Distance > 0
GROUP BY Pickup_Location, Drop_Location
HAVING Trip_Count >= 10
ORDER BY Total_Revenue DESC
LIMIT 20;

-- 32. Driver Performance Score

-- Composite driver performance metric
WITH driver_metrics AS (
    SELECT 
        Vehicle_Type,
        COUNT(*) AS Total_Rides,
        AVG(Driver_Ratings) AS Avg_Rating,
        AVG(V_TAT) AS Avg_Arrival_Time,
        SUM(CASE WHEN Booking_Status = 'Canceled by Driver' THEN 1 ELSE 0 END) AS Driver_Cancellations
    FROM bookings
    GROUP BY Vehicle_Type
)
SELECT 
    Vehicle_Type,
    Total_Rides,
    ROUND(Avg_Rating, 2) AS Avg_Rating,
    ROUND(Avg_Arrival_Time, 2) AS Avg_TAT_Minutes,
    Driver_Cancellations,
    ROUND(
        (Avg_Rating / 5 * 50) + 
        (CASE WHEN Avg_Arrival_Time <= 10 THEN 30 ELSE 15 END) +
        (20 - (Driver_Cancellations * 100.0 / Total_Rides)),
        2
    ) AS Performance_Score
FROM driver_metrics
ORDER BY Performance_Score DESC;


---

