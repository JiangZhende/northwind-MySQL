/* RENAME `order details` relation to have no spaces in relation name 
ALTER TABLE `northwind`.`order details` 
RENAME TO  `northwind`.`orderDET`; */

/* BEGIN WITH PRELIMINARY INVESTIGATION OF RELATIONS OF INTEREST */
SELECT * FROM categories; 
SELECT * FROM customers;
SELECT * FROM employees;
SELECT * FROM orderDET limit 3000;
SELECT * FROM orders limit 3000;
SELECT * FROM products;


/* START WITH SOME ANALYSES OF EMPLOYEES */
/* IDENTIFY THE BEST PERFORMING SALESPEOPLE, NO. OF PRODUCTS SOLD, AND GROSS SALES */
/* CREATE INDEX ON EMPLOYEES(EMPLOYEEID) 
CREATE UNIQUE INDEX EmployeeID on employees(EmployeeID); */
SELECT LastName, FirstName, COUNT(O.OrderID) AS NumOrders, 
       SUM(UnitPrice*Quantity) AS SalesGross
FROM   employees E INNER JOIN orders O ON (E.EmployeeID = O.EmployeeID) 
	   INNER JOIN orderDET D ON (O.OrderID = D.OrderID)
GROUP BY E.EmployeeID
ORDER BY SalesGross DESC;

/* IDENTIFY THE BEST PERFORMING SALESPEOPLE, NO. OF PRODUCTS SOLD, AND NET SALES (w/ DISCOUNT)*/
SELECT LastName, FirstName, COUNT(O.OrderID) AS NumOrders, 
       SUM(UnitPrice*(1-Discount)*Quantity) AS SalesNet
FROM employees E INNER JOIN orders O ON (E.EmployeeID = O.EmployeeID) 
     INNER JOIN orderDET D ON (O.OrderID = D.OrderID)
GROUP BY E.EmployeeID
ORDER BY SalesNet DESC;

/* "OLDER" VS. "YOUNGER" EMPLOYEES 
ALTER TABLE employees ADD birth1960 TEXT;
UPDATE employees SET birth1960 = 'pre' WHERE EmployeeID <> 0 AND BirthDate < '1960-01-01 00:00:00';
UPDATE employees SET birth1960 = 'post' WHERE EmployeeID <> 0 AND BirthDate >= '1960-01-01 00:00:00'; */
SELECT birth1960, COUNT(O.OrderID) AS NumOrders, 
       SUM(UnitPrice*(1-Discount)*Quantity) AS SalesNet
FROM employees E INNER JOIN orders O ON (E.EmployeeID = O.EmployeeID) 
     INNER JOIN orderDET D ON (O.OrderID = D.OrderID)
GROUP BY E.birth1960
ORDER BY SalesNet DESC;


/* SOME ANALYSES OF CUSTOMERS */
/* ALL CUSTOMERS AND THEIR ASSOCIATED ORDERS */
SELECT C.CustomerID, C.CompanyName, O.OrderID, O.OrderDate, O.ShipCountry, O.EmployeeID
FROM  customers C LEFT JOIN orders O ON (C.CustomerID = O.CustomerID);

SELECT C.CustomerID, C.CompanyName, O.OrderID, O.OrderDate, O.ShipCountry, O.EmployeeID
FROM   orders O RIGHT JOIN customers C ON (C.CustomerID = O.CustomerID);

/* FIND THE 2 CUSTOMERS WHO HAVE NOT PLACED AN ORDER */
SELECT C.CustomerID, C.CompanyName, O.OrderID, O.OrderDate
FROM   customers C LEFT JOIN orders O ON (C.CustomerID = O.CustomerID)
WHERE  OrderID IS NULL;

/* FIND ALL CITIES WHICH CONTAIN 5 OR MORE CUSTOMERS */
SELECT C1.City, C1.CompanyName, C2.CompanyName, C3.CompanyName, C4.CompanyName, C5.CompanyName
FROM   customers C1, customers C2, customers C3, customers C4, customers C5
WHERE C1.City = C2.City AND C2.City = C3.City AND C3.City = C4.City AND C4.City = C5.City 
      AND C1.CompanyName < C2.CompanyName AND C2.CompanyName < C3.CompanyName
      AND C3.CompanyName < C4.CompanyName AND C4.CompanyName < C5.CompanyName;
      
      
/* SOME ANALYSES OF SALES */
/* IN WHAT COUNTRY ARE SALES HIGHER? */
SELECT Country, count(O.OrderID) as NumOrders, 
       sum(UnitPrice*(1-Discount)*Quantity) as SalesNet
FROM employees E INNER JOIN orders O ON (E.EmployeeID = O.EmployeeID) 
	 INNER JOIN orderDET D ON (O.OrderID = D.OrderID)
GROUP BY E.Country
ORDER BY SalesNet DESC;

/* BREAKDOWN BY CATEGORIES */
SELECT C.CategoryID, C.CategoryName, sum(D.UnitPrice*(1-D.Discount)*D.Quantity) as SalesNet
FROM   orderDET D INNER JOIN products P ON (D.ProductID = P.ProductID) 
       INNER JOIN categories C ON(C.CategoryID = P.CategoryID)
GROUP BY C.CategoryID   
ORDER BY SalesNet DESC;

/* FIND ALL PRODUCTS THAT HAVE GENERATED GREATER THAN 25K IN SALES */
SELECT P.ProductID, ProductName,sum(D.UnitPrice*(1-D.Discount)*D.Quantity) as SalesNet
FROM orderDET D INNER JOIN products P ON (D.ProductID = P.ProductID)
GROUP BY P.ProductID    
HAVING SalesNet > 25000     
ORDER BY SalesNet DESC;


/* FIND COMPANIES THAT HAVE SAVED MORE THAN 10% FROM DISCOUNTS */
SELECT * 
FROM(
	SELECT C.CompanyName,
		   SUM(UnitPrice*Quantity) AS SalesGross , 
		   SUM(UnitPrice*(1-Discount)*Quantity) AS SalesNet,
		   1 - SUM(UnitPrice*(1-Discount)*Quantity) / SUM(UnitPrice*Quantity) AS Discount
	FROM orders O INNER JOIN orderDET D ON (O.OrderID = D.OrderID) 
         INNER JOIN customers C ON (O.CustomerID = C.CustomerID)
    GROUP BY O.CustomerID
	HAVING Discount > 0.1
	ORDER BY Discount DESC ) S ;
          
SELECT C.CompanyName,
	   SUM(UnitPrice*Quantity) AS SalesGross , 
	   SUM(UnitPrice*(1-Discount)*Quantity) AS SalesNet,
	   1 - SUM(UnitPrice*(1-Discount)*Quantity) / SUM(UnitPrice*Quantity) AS Discount
FROM   orders O INNER JOIN orderDET D ON (O.OrderID = D.OrderID) 
       INNER JOIN customers C ON (O.CustomerID = C.CustomerID)
GROUP BY O.CustomerID
HAVING Discount > 0.1
ORDER BY Discount DESC;

/* FIND COMPANIES THAT HAVE SAVED MORE THAN 5% FROM DISCOUNTS AND HAVE 1+ OTHER COMPANIES IN SAME CITY */
/* APPROACH 1 */
SELECT * 
FROM(
	SELECT C.CompanyName,
           C.City,
		   SUM(UnitPrice*Quantity) AS SalesGross , 
		   SUM(UnitPrice*(1-Discount)*Quantity) AS SalesNet,
		   1 - sum(UnitPrice*(1-Discount)*Quantity) / SUM(UnitPrice*Quantity) AS Discount
	FROM orders O INNER JOIN orderDET D ON (O.OrderID = D.OrderID) 
		 INNER JOIN customers C ON (O.CustomerID = C.CustomerID)
	GROUP BY O.CustomerID
    HAVING Discount > 0.05
	ORDER BY Discount DESC ) S 
WHERE CompanyName IN 
		(SELECT DISTINCT C1.CompanyName
		FROM  customers C1, customers C2, customers C3
		WHERE C1.City = C2.City AND C2.City = C3.City AND
		      C1.CompanyName <> C2.CompanyName AND 
              C2.CompanyName <> C3.CompanyName AND 
              C1.CompanyName <> C3.CompanyName) ;    

/* APPROACH 2 */
SELECT * 
FROM(
	SELECT C.CompanyName,
		   sum(UnitPrice*Quantity) as SalesGross , 
		   sum(UnitPrice*(1-Discount)*Quantity) as SalesNet,
		   1 - sum(UnitPrice*(1-Discount)*Quantity) / sum(UnitPrice*Quantity) as Discount
	FROM orders O INNER JOIN orderDET D ON (O.OrderID = D.OrderID) INNER JOIN customers C 
		  ON (O.CustomerID = C.CustomerID)
		  GROUP BY O.CustomerID
          HAVING Discount > 0.05
		  ORDER BY Discount DESC ) S 
WHERE CompanyName IN 
	(SELECT C1.CompanyName
	FROM customers C1, customers C2, customers C3
	WHERE C1.City = C2.City AND C2.City = C3.City 
		  AND C1.CompanyName < C2.CompanyName AND C2.CompanyName < C3.CompanyName 
	UNION
	SELECT C2.CompanyName
	FROM customers C1, customers C2, customers C3
	WHERE C1.City = C2.City AND C2.City = C3.City 
		  AND C1.CompanyName < C2.CompanyName AND C2.CompanyName < C3.CompanyName 
	UNION
	SELECT C3.CompanyName
	FROM customers C1, customers C2, customers C3
	WHERE C1.City = C2.City AND C2.City = C3.City 
		  AND C1.CompanyName < C2.CompanyName AND C2.CompanyName < C3.CompanyName ) ;
      

/* ESTABLISH TRIGGERS */
/* UNIT PRICE MUST BE POSITIVE */
INSERT INTO orderDet VALUES (99999, 99999, -5, 99999 , 0);
DELETE FROM orderDet WHERE OrderID = 99999;


DELIMITER $$

CREATE TRIGGER NegPrice
BEFORE INSERT ON orderDET 
FOR EACH ROW 
BEGIN
	IF New.UnitPrice < 0 THEN
    SIGNAL SQLSTATE '22003' SET MESSAGE_TEXT = 'Unit Price Must Be Positive';
    END IF;
END$$

DELIMITER ;

/* THIS WILL CORRECTLY RETURN AN ERROR */ INSERT INTO orderDet VALUES (99999, 99999, -5, 99999 , 0);

/* QUANTITY MUST BE POSITIVE */
DELIMITER $$

CREATE TRIGGER NegQuantity
BEFORE INSERT ON orderDET 
FOR EACH ROW 
BEGIN
	IF New.Quantity < 0 THEN
    SIGNAL SQLSTATE '22003' SET MESSAGE_TEXT = 'Quantity Must Be Positive';
    END IF;
END$$

DELIMITER ;

INSERT INTO orderDet VALUES (99999, 99999, 99999, -5 , 0);

/* DELETE ON ORDERS TRIGGERS DELETE ON ORDER DETAILS */
INSERT INTO orders VALUES(99999, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO orderDET VALUES(99999, 99999, 99999, 99999, 0);
DELETE FROM orders WHERE OrderID = 99999;
DELETE FROM orderDET WHERE OrderID = 99999;

DELIMITER $$

CREATE TRIGGER OrderDel
AFTER DELETE ON orders 
FOR EACH ROW 
BEGIN
	DELETE FROM orderDET
    WHERE Old.OrderID = orderDET.OrderId ;
END$$

DELIMITER ;

INSERT INTO orders VALUES(99999, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
INSERT INTO orderDET VALUES(99999, 99999, 99999, 99999, 0);
DELETE FROM orders WHERE OrderID = 99999;