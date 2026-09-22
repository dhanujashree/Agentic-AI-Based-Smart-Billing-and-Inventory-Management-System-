-- ============================================
-- AGENTIC AI SMART RETAIL
-- DATABASE SCHEMA
-- ============================================


CREATE DATABASE smart_retail;

USE smart_retail;


-- ============================================
-- 1. TENANTS
-- Stores / Shops
-- ============================================

CREATE TABLE tenants (
    tenant_id INT AUTO_INCREMENT PRIMARY KEY,
    store_name VARCHAR(100) NOT NULL,
    owner_name VARCHAR(100) NOT NULL,
    business_type VARCHAR(50),
    phone VARCHAR(15),
    email VARCHAR(100) UNIQUE,
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP
);


-- ============================================
-- 2. SUBSCRIPTIONS
-- SaaS subscription details
-- ============================================

CREATE TABLE subscriptions (
    subscription_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    plan_name VARCHAR(50) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    status ENUM('ACTIVE','EXPIRED','CANCELLED')
        DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE
);


-- ============================================
-- 3. USERS
-- Owner / Employee login
-- ============================================

CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    username VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('OWNER','EMPLOYEE')
        DEFAULT 'EMPLOYEE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, username),

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE
);


-- ============================================
-- 4. CATEGORIES
-- Product categories
-- ============================================

CREATE TABLE categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    category_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, category_name),

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE
);


-- ============================================
-- 5. PRODUCTS
-- Product master details
-- ============================================

CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    category_id INT,
    product_name VARCHAR(100) NOT NULL,
    sku VARCHAR(50),
    barcode VARCHAR(50),
    unit VARCHAR(20),
    purchase_price DECIMAL(10,2),
    selling_price DECIMAL(10,2),
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, sku),
    UNIQUE (tenant_id, barcode),

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE,

    FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE SET NULL
);


-- ============================================
-- 6. INVENTORY
-- Current stock details
-- ============================================

CREATE TABLE inventory (
    inventory_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    product_id INT NOT NULL,
    stock_quantity INT DEFAULT 0,
    reorder_level INT DEFAULT 10,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, product_id),

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);


-- ============================================
-- 7. SUPPLIER INVOICE
-- OCR uploaded invoice details
-- ============================================

CREATE TABLE supplier_invoice (
    invoice_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    supplier_name VARCHAR(100),
    invoice_number VARCHAR(50),
    invoice_date DATE,
    invoice_file VARCHAR(255),
    uploaded_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE,

    FOREIGN KEY (uploaded_by)
        REFERENCES users(user_id)
        ON DELETE SET NULL
);


-- ============================================
-- 8. INVOICE ITEMS
-- OCR extracted invoice items
-- ============================================

CREATE TABLE invoice_items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    product_id INT,
    product_name VARCHAR(100),
    quantity INT,
    price DECIMAL(10,2),

    validation_status ENUM(
        'PENDING',
        'VALID',
        'INVALID'
    ) DEFAULT 'PENDING',

    FOREIGN KEY (invoice_id)
        REFERENCES supplier_invoice(invoice_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE SET NULL
);


-- ============================================
-- 9. SALES
-- Billing / sales transaction
-- ============================================

CREATE TABLE sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    bill_no VARCHAR(30) NOT NULL,
    customer_name VARCHAR(100),
    total_amount DECIMAL(10,2),

    payment_method ENUM(
        'CASH',
        'CARD',
        'UPI',
        'OTHER'
    ),

    sale_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    UNIQUE (tenant_id, bill_no),

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE
);


-- ============================================
-- 10. SALES ITEMS
-- Products included in each bill
-- ============================================

CREATE TABLE sales_items (
    sale_item_id INT AUTO_INCREMENT PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2),
    subtotal DECIMAL(10,2),

    FOREIGN KEY (sale_id)
        REFERENCES sales(sale_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
);


-- ============================================
-- 11. SALES HISTORY
-- Historical sales data for ML
-- ============================================

CREATE TABLE sales_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    product_id INT NOT NULL,
    sale_date DATE NOT NULL,
    quantity_sold INT NOT NULL,

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);


-- ============================================
-- 12. SALES PREDICTION
-- XGBoost prediction results
-- ============================================

CREATE TABLE sales_prediction (
    prediction_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    product_id INT NOT NULL,
    predicted_date DATE NOT NULL,
    predicted_quantity INT NOT NULL,
    model_name VARCHAR(50)
        DEFAULT 'XGBoost',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);


-- ============================================
-- 13. AI RECOMMENDATION
-- CrewAI / Agentic AI recommendations
-- ============================================

CREATE TABLE ai_recommendation (
    recommendation_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    product_id INT NOT NULL,
    current_stock INT,
    predicted_demand INT,
    recommended_quantity INT,
    recommendation_text TEXT,

    status ENUM(
        'PENDING',
        'COMPLETED'
    ) DEFAULT 'PENDING',

    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE,

    FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE
);


-- ============================================
-- 14. AGENT LOGS
-- CrewAI agent activity
-- ============================================

CREATE TABLE agent_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    tenant_id INT NOT NULL,
    agent_name VARCHAR(100) NOT NULL,
    action_taken TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (tenant_id)
        REFERENCES tenants(tenant_id)
        ON DELETE CASCADE
);


-- ============================================
-- CHECK ALL TABLES
-- ============================================

SHOW TABLES;
