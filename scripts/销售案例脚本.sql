-- 2015年各城市的手机销量
USE test;
SELECT SUM(Units_Sold),City
FROM Fact_Sales a 
JOIN Dim_Store b ON a.Store_Id = b.id
JOIN Dim_Date c ON a.Date_Id = c.id
JOIN Dim_Product d ON a.Product_Id = d.id
WHERE c.Year=2018 AND d.Product_Category='mobile'
GROUP BY City;
USE snow;
SELECT SUM(Units_Sold),City
FROM Fact_Sales a
JOIN Dim_Store b ON a.Store_Id = b.id
JOIN Dim_Geography c ON  b.Geography_Id = c.id
JOIN Dim_Product d ON a.Product_Id = d.Product_Id
JOIN Dim_Category e ON d.Category_Id = e.Category_Id
JOIN Dim_Date f ON a.Date_Id = f.id
WHERE e.Categoryt_Name='mobile' AND f.Year = 2015
GROUP BY City;