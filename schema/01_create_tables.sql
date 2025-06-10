-- customers table
  Customer_ID    INT PRIMARY KEY,
  Customer_Name  VARCHAR(100),
  Email          VARCHAR(255),
  Age            INT,
  Gender         VARCHAR(20),
  Location       VARCHAR(100),
  Signup_Date    DATE,
  referred_by    INT
);

-- orders table
  Order_ID           VARCHAR(20) PRIMARY KEY,
  Orders_Date        DATE,
  Product            VARCHAR(100),
  Category           VARCHAR(50),
  Price              DECIMAL(10,2),
  Quantity           INT,
  Total_Sales        DECIMAL(10,2),
  Customer_Name      VARCHAR(100),
  Customer_Location  VARCHAR(100),
  Payment_Method     VARCHAR(50),
  By_mode            VARCHAR(50)
);

-- payments table
  payment_id      INT PRIMARY KEY,
  Order_id        VARCHAR(20),
  Payment_method  VARCHAR(50),
  Payment_status  VARCHAR(50),
  Paid_Amount     DECIMAL(10,2),
  Payment_date    DATE
);

-- products table
  Product_ID       INT PRIMARY KEY,
  Product_Name     VARCHAR(100),
  Category         VARCHAR(50),
  Price            DECIMAL(10,2),
  Brand            VARCHAR(50),
  Stock_Quantity   INT,
  parent_category  VARCHAR(100)
);

-- shipping table
  Shipping_ID      INT PRIMARY KEY,
  Order_ID         VARCHAR(20),
  Shipped_Date     DATE,
  Delivery_Date    DATE,
  Shipping_Status  VARCHAR(50),
  Courier          VARCHAR(50)
);
