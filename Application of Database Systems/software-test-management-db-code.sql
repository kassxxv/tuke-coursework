-- RESET - odstranenie existujucich objektov
DROP TABLE BUGS CASCADE CONSTRAINTS;
DROP TABLE TEST_RUNS CASCADE CONSTRAINTS;
DROP TABLE RELEASES CASCADE CONSTRAINTS;
DROP TABLE TEST_CASES CASCADE CONSTRAINTS;
DROP TABLE TASKS CASCADE CONSTRAINTS;
DROP TABLE PROJECT_TEAMS CASCADE CONSTRAINTS;
DROP TABLE USERS CASCADE CONSTRAINTS;
DROP TABLE PROJECTS CASCADE CONSTRAINTS;

DROP SEQUENCE seq_project;
DROP SEQUENCE seq_user;
DROP SEQUENCE seq_task;
DROP SEQUENCE seq_test_case;
DROP SEQUENCE seq_release;
DROP SEQUENCE seq_test_run;
DROP SEQUENCE seq_bug;


-- 1. CAST - SEKVENCIA na generovanie primarnych klucov
CREATE SEQUENCE seq_project START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_user START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_task START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_test_case START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_release START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_test_run START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_bug START WITH 1 INCREMENT BY 1;


-- 1. CAST - VYTVORENIE TABULIEK

-- U1: nezavisle tabulky (bez FK)
CREATE TABLE PROJECTS (
    project_id NUMBER(6) CONSTRAINT pk_projects PRIMARY KEY,
    name VARCHAR2(50) CONSTRAINT nn_proj_name NOT NULL,
    description VARCHAR2(300),
    start_date DATE,
    end_date DATE,
    status VARCHAR2(20) CONSTRAINT nn_proj_status NOT NULL,
    CONSTRAINT chk_proj_status CHECK (status IN ('ACTIVE', 'COMPLETED', 'PAUSED', 'CANCELLED'))
);

CREATE TABLE USERS (
    id_user NUMBER(6) CONSTRAINT pk_users PRIMARY KEY,
    first_name VARCHAR2(50) CONSTRAINT nn_user_fname NOT NULL,
    last_name VARCHAR2(50) CONSTRAINT nn_user_lname NOT NULL,
    email VARCHAR2(50) CONSTRAINT uq_user_email UNIQUE NOT NULL,
    role VARCHAR2(30) CONSTRAINT nn_user_role NOT NULL,
    hire_date DATE
);

-- U2: tabulky zavisle od PROJECTS a USERS
CREATE TABLE PROJECT_TEAMS (
    id_user NUMBER(6) CONSTRAINT nn_pt_user NOT NULL,
    id_project NUMBER(6) CONSTRAINT nn_pt_proj NOT NULL,
    role_in_project VARCHAR2(30),
    joined_date DATE,
    CONSTRAINT pk_project_teams PRIMARY KEY (id_user, id_project),
    CONSTRAINT fk_pt_user FOREIGN KEY (id_user) REFERENCES USERS(id_user),
    CONSTRAINT fk_pt_project FOREIGN KEY (id_project) REFERENCES PROJECTS(project_id)
);

CREATE TABLE TASKS (
    id_task NUMBER(6) CONSTRAINT pk_tasks PRIMARY KEY,
    id_user NUMBER(6) CONSTRAINT nn_task_user NOT NULL,
    id_project NUMBER(6) CONSTRAINT nn_task_proj NOT NULL,
    title VARCHAR2(100) CONSTRAINT nn_task_title NOT NULL,
    description VARCHAR2(500),
    priority VARCHAR2(30),
    status VARCHAR2(20) CONSTRAINT nn_task_status NOT NULL,
    CONSTRAINT chk_task_priority CHECK (priority IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_task_status CHECK (status IN ('TODO', 'IN_PROGRESS', 'DONE', 'BLOCKED')),
    CONSTRAINT fk_task_user FOREIGN KEY (id_user) REFERENCES USERS(id_user),
    CONSTRAINT fk_task_project FOREIGN KEY (id_project) REFERENCES PROJECTS(project_id)
);

CREATE TABLE TEST_CASES (
    id_test_case NUMBER(6) CONSTRAINT pk_test_cases PRIMARY KEY,
    id_project NUMBER(6) CONSTRAINT nn_tc_proj NOT NULL,
    title VARCHAR2(100) CONSTRAINT nn_tc_title NOT NULL,
    steps VARCHAR2(500),
    expected_result VARCHAR2(100),
    CONSTRAINT fk_tc_project FOREIGN KEY (id_project) REFERENCES PROJECTS(project_id)
);

CREATE TABLE RELEASES (
    id_release NUMBER(6) CONSTRAINT pk_releases PRIMARY KEY,
    id_project NUMBER(6) CONSTRAINT nn_rel_proj NOT NULL,
    version VARCHAR2(20) CONSTRAINT nn_rel_ver NOT NULL,
    release_date DATE,
    notes VARCHAR2(500),
    CONSTRAINT fk_rel_project FOREIGN KEY (id_project) REFERENCES PROJECTS(project_id)
);

-- U3: tabulky zavisle od urovne hore
CREATE TABLE TEST_RUNS (
    id_run NUMBER(6) CONSTRAINT pk_test_runs PRIMARY KEY,
    id_test_case NUMBER(6) CONSTRAINT nn_run_tc NOT NULL,
    id_user NUMBER(6) CONSTRAINT nn_run_user NOT NULL,
    notes VARCHAR2(500),
    result VARCHAR2(20),
    run_date DATE,
    CONSTRAINT chk_run_result CHECK (result IN ('PASS', 'FAIL', 'SKIP')),
    CONSTRAINT fk_run_test_case FOREIGN KEY (id_test_case) REFERENCES TEST_CASES(id_test_case),
    CONSTRAINT fk_run_user FOREIGN KEY (id_user) REFERENCES USERS(id_user)
);

CREATE TABLE BUGS (
    id_bug NUMBER(6) CONSTRAINT pk_bugs PRIMARY KEY,
    id_run NUMBER(6) CONSTRAINT nn_bug_run NOT NULL,
    id_user NUMBER(6) CONSTRAINT nn_bug_user NOT NULL,
    title VARCHAR2(100) CONSTRAINT nn_bug_title NOT NULL,
    description VARCHAR2(500),
    severity VARCHAR2(20),
    status VARCHAR2(20) CONSTRAINT nn_bug_status NOT NULL,
    CONSTRAINT chk_bug_severity CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    CONSTRAINT chk_bug_status CHECK (status IN ('OPEN', 'IN_PROGRESS', 'FIXED', 'CLOSED')),
    CONSTRAINT fk_bug_run FOREIGN KEY (id_run) REFERENCES TEST_RUNS(id_run),
    CONSTRAINT fk_bug_user FOREIGN KEY (id_user) REFERENCES USERS(id_user)
);


-- 1. CAST - NAPLNENIE TABULIEK DATAMI

INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Mobile Banking App', 'Banking application for iOS and Android', TO_DATE('2024-01-10','YYYY-MM-DD'), TO_DATE('2024-12-31','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'E-Commerce Platform', 'Online store with payment integration', TO_DATE('2024-02-01','YYYY-MM-DD'), TO_DATE('2024-10-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'HR Management System', 'Internal HR tool for employee management', TO_DATE('2023-06-01','YYYY-MM-DD'), TO_DATE('2024-06-01','YYYY-MM-DD'), 'COMPLETED');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'CRM Dashboard', 'Customer relationship management dashboard', TO_DATE('2024-03-15','YYYY-MM-DD'), TO_DATE('2025-03-15','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Inventory Tracker', 'Warehouse inventory management system', TO_DATE('2023-11-01','YYYY-MM-DD'), TO_DATE('2024-05-01','YYYY-MM-DD'), 'COMPLETED');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'API Gateway', 'Centralized API gateway for microservices', TO_DATE('2024-04-01','YYYY-MM-DD'), TO_DATE('2024-09-30','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Chat Application', 'Real-time chat with file sharing', TO_DATE('2024-05-01','YYYY-MM-DD'), TO_DATE('2025-01-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Analytics Engine', 'Data analytics and reporting engine', TO_DATE('2023-09-01','YYYY-MM-DD'), TO_DATE('2024-03-01','YYYY-MM-DD'), 'COMPLETED');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Notification Service', 'Push and email notification microservice', TO_DATE('2024-02-15','YYYY-MM-DD'), TO_DATE('2024-08-15','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Auth Service', 'Authentication and authorization service', TO_DATE('2024-01-01','YYYY-MM-DD'), TO_DATE('2024-06-01','YYYY-MM-DD'), 'COMPLETED');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'File Storage API', 'Cloud file storage and CDN integration', TO_DATE('2024-06-01','YYYY-MM-DD'), TO_DATE('2025-06-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Payment Gateway', 'Secure payment processing service', TO_DATE('2024-03-01','YYYY-MM-DD'), TO_DATE('2024-11-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Admin Panel', 'Back-office administration panel', TO_DATE('2023-07-01','YYYY-MM-DD'), TO_DATE('2024-01-01','YYYY-MM-DD'), 'COMPLETED');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'Search Service', 'Full-text search with Elasticsearch', TO_DATE('2024-07-01','YYYY-MM-DD'), TO_DATE('2025-02-01','YYYY-MM-DD'), 'ACTIVE');
INSERT INTO PROJECTS (project_id, name, description, start_date, end_date, status) VALUES (seq_project.NEXTVAL, 'CI/CD Pipeline', 'Automated build and deployment pipeline', TO_DATE('2024-01-20','YYYY-MM-DD'), TO_DATE('2024-07-20','YYYY-MM-DD'), 'COMPLETED');

--------------------------------------------------------------
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Alice', 'Johnson', 'alice.johnson@gmail.com', 'Developer', TO_DATE('2021-03-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Bob', 'Smith', 'bob.smith@gmail.com', 'QA Engineer', TO_DATE('2020-07-15','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Carol', 'White', 'carol.white@gmail.com', 'Project Manager', TO_DATE('2019-11-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'David', 'Brown', 'david.brown@gmail.com', 'Developer', TO_DATE('2022-01-10','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Eva', 'Davis', 'eva.davis@gmail.com', 'QA Engineer', TO_DATE('2022-05-20','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Frank', 'Miller', 'frank.miller@gmail.com', 'DevOps', TO_DATE('2021-08-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Grace', 'Wilson', 'grace.wilson@gmail.com', 'Developer', TO_DATE('2023-02-14','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Henry', 'Moore', 'henry.moore@gmail.com', 'Team Lead', TO_DATE('2018-06-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Irene', 'Taylor', 'irene.taylor@gmail.com', 'QA Engineer', TO_DATE('2023-06-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Jack', 'Anderson', 'jack.anderson@gmail.com', 'Developer', TO_DATE('2022-09-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Karen', 'Thomas', 'karen.thomas@gmail.com', 'Designer', TO_DATE('2021-12-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Leo', 'Jackson', 'leo.jackson@gmail.com', 'Developer', TO_DATE('2023-03-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Maria', 'Harris', 'maria.harris@gmail.com', 'Project Manager', TO_DATE('2020-01-15','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Nick', 'Martin', 'nick.martin@gmail.com', 'QA Engineer', TO_DATE('2022-11-01','YYYY-MM-DD'));
INSERT INTO USERS (id_user, first_name, last_name, email, role, hire_date) VALUES (seq_user.NEXTVAL, 'Olivia', 'Garcia', 'olivia.garcia@gmail.com', 'Developer', TO_DATE('2023-08-01','YYYY-MM-DD'));

--------------------------------------------------------------
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (1, 1, 'Lead Developer', TO_DATE('2024-01-10','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (2, 1, 'QA Lead', TO_DATE('2024-01-10','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (3, 1, 'Project Manager', TO_DATE('2024-01-10','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (4, 2, 'Developer', TO_DATE('2024-02-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (5, 2, 'QA Engineer', TO_DATE('2024-02-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (6, 2, 'DevOps', TO_DATE('2024-02-05','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (7, 3, 'Developer', TO_DATE('2023-06-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (8, 3, 'Team Lead', TO_DATE('2023-06-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (9, 4, 'QA Engineer', TO_DATE('2024-03-15','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (10, 4, 'Developer', TO_DATE('2024-03-15','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (11, 5, 'Designer', TO_DATE('2023-11-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (12, 5, 'Developer', TO_DATE('2023-11-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (1, 6, 'Developer', TO_DATE('2024-04-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (13, 6, 'Project Manager', TO_DATE('2024-04-01','YYYY-MM-DD'));
INSERT INTO PROJECT_TEAMS (id_user, id_project, role_in_project, joined_date) VALUES (14, 7, 'QA Engineer', TO_DATE('2024-05-01','YYYY-MM-DD'));

--------------------------------------------------------------
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 1, 1, 'Setup project structure', 'Initialize repo and CI/CD', 'HIGH', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 1, 1, 'Implement login screen', 'UI and API integration for login', 'HIGH', 'IN_PROGRESS');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 4, 2, 'Build product catalog', 'REST API for product listing', 'HIGH', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 4, 2, 'Payment integration', 'Stripe payment gateway', 'HIGH', 'IN_PROGRESS');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 7, 3, 'Employee CRUD', 'Create, read, update, delete employees', 'MEDIUM', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 7, 3, 'Payroll module', 'Monthly payroll calculation', 'HIGH', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 10, 4, 'Dashboard charts', 'Integrate Chart.js for metrics', 'MEDIUM', 'IN_PROGRESS');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 10, 4, 'Customer filters', 'Advanced search and filter UI', 'LOW', 'TODO');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 12, 5, 'Barcode scanner', 'Mobile barcode scanning feature', 'HIGH', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 12, 5, 'Stock alerts', 'Low stock email notifications', 'MEDIUM', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 1, 6, 'Rate limiting', 'Implement API rate limiter', 'HIGH', 'IN_PROGRESS');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 1, 6, 'Token validation', 'JWT validation middleware', 'HIGH', 'DONE');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 15, 7, 'WebSocket server', 'Real-time messaging backend', 'HIGH', 'IN_PROGRESS');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 15, 7, 'File upload feature', 'Upload images and documents in chat', 'MEDIUM', 'TODO');
INSERT INTO TASKS (id_task, id_user, id_project, title, description, priority, status) VALUES (seq_task.NEXTVAL, 6, 9, 'Email templates', 'HTML email template system', 'LOW', 'IN_PROGRESS');

--------------------------------------------------------------
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 1, 'Login with valid credentials', 'Open app > Enter email > Enter password > Tap Login', 'User is logged in and dashboard is shown');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 1, 'Login with wrong password', 'Open app > Enter email > Enter wrong password > Tap Login', 'Error message: Invalid credentials');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 1, 'Session timeout', 'Login > Wait 30 min idle > Try any action', 'User is redirected to login page');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 2, 'Add product to cart', 'Browse catalog > Select product > Click Add to Cart', 'Product appears in cart with correct price');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 2, 'Checkout with valid card', 'Add item > Go to checkout > Enter card > Pay', 'Order confirmation email is sent');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 2, 'Checkout with declined card', 'Add item > Go to checkout > Enter invalid card > Pay', 'Error: Payment declined, order not created');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 3, 'Create new employee', 'Open HR > New Employee > Fill form > Save', 'Employee appears in employee list');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 3, 'Delete employee', 'Open HR > Find employee > Click Delete > Confirm', 'Employee removed from system');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 4, 'Filter customers by country', 'Open CRM > Customers > Filter by Country: Slovakia', 'Only Slovak customers are displayed');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 4, 'Export customer list', 'Open CRM > Customers > Export CSV', 'CSV file downloaded with all customer data');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 5, 'Scan valid barcode', 'Open app > Scan > Point at barcode', 'Product info displayed correctly');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 5, 'Low stock alert trigger', 'Set stock to 2 > Wait for job run', 'Email alert sent to warehouse manager');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 6, 'Exceed rate limit', 'Send 101 requests in 1 minute to API', 'HTTP 429 Too Many Requests returned');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 6, 'Valid JWT token', 'Call API endpoint with valid JWT', 'HTTP 200 and correct data returned');
INSERT INTO TEST_CASES (id_test_case, id_project, title, steps, expected_result) VALUES (seq_test_case.NEXTVAL, 7, 'Send message in chat', 'Login > Open chat > Type message > Send', 'Message appears in chat for both users');

--------------------------------------------------------------
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 1, '1.0.0', TO_DATE('2024-03-01','YYYY-MM-DD'), 'Initial release with login and dashboard');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 1, '1.1.0', TO_DATE('2024-05-15','YYYY-MM-DD'), 'Added transaction history');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 1, '1.2.0', TO_DATE('2024-08-01','YYYY-MM-DD'), 'Biometric login support');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 2, '0.9.0', TO_DATE('2024-03-20','YYYY-MM-DD'), 'Beta release for internal testing');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 2, '1.0.0', TO_DATE('2024-06-01','YYYY-MM-DD'), 'Public launch with full catalog');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 3, '1.0.0', TO_DATE('2023-12-01','YYYY-MM-DD'), 'Core HR features delivered');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 3, '1.5.0', TO_DATE('2024-04-01','YYYY-MM-DD'), 'Payroll module added');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 4, '1.0.0', TO_DATE('2024-06-15','YYYY-MM-DD'), 'Dashboard with basic charts');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 5, '1.0.0', TO_DATE('2024-01-10','YYYY-MM-DD'), 'Barcode scanner and basic inventory');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 5, '1.1.0', TO_DATE('2024-04-15','YYYY-MM-DD'), 'Low stock alerts added');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 6, '1.0.0', TO_DATE('2024-06-01','YYYY-MM-DD'), 'Rate limiting and auth middleware');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 7, '0.1.0', TO_DATE('2024-07-01','YYYY-MM-DD'), 'WebSocket prototype');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 8, '2.0.0', TO_DATE('2024-02-28','YYYY-MM-DD'), 'Full analytics engine rewrite');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 10, '1.0.0', TO_DATE('2024-05-20','YYYY-MM-DD'), 'Auth service stable release');
INSERT INTO RELEASES (id_release, id_project, version, release_date, notes) VALUES (seq_release.NEXTVAL, 12, '1.0.0', TO_DATE('2024-07-01','YYYY-MM-DD'), 'Payment gateway go-live');

--------------------------------------------------------------
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 1, 2, 'Tested on Android 13', 'PASS', TO_DATE('2024-03-05','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 2, 2, 'Tested on iOS 17', 'PASS', TO_DATE('2024-03-05','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 3, 5, 'Session timer set to 30 min', 'FAIL', TO_DATE('2024-03-06','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 4, 5, 'Cart persistence checked', 'PASS', TO_DATE('2024-06-10','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 5, 2, 'Used Stripe test card 4242', 'PASS', TO_DATE('2024-06-11','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 6, 5, 'Used Stripe declined test card', 'PASS', TO_DATE('2024-06-11','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 7, 9, 'All mandatory fields filled', 'PASS', TO_DATE('2023-12-05','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 8, 9, 'Tested with admin account', 'FAIL', TO_DATE('2023-12-06','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 9, 14, 'Filter applied to 500 records', 'PASS', TO_DATE('2024-07-01','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 10, 14, 'Export with 1000 rows', 'FAIL', TO_DATE('2024-07-02','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 11, 2, 'EAN-13 barcode used', 'PASS', TO_DATE('2024-01-15','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 12, 5, 'Cron job triggered manually', 'PASS', TO_DATE('2024-04-20','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 13, 2, '101 requests sent via Postman', 'PASS', TO_DATE('2024-06-05','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 14, 9, 'Valid JWT generated and used', 'PASS', TO_DATE('2024-06-05','YYYY-MM-DD'));
INSERT INTO TEST_RUNS (id_run, id_test_case, id_user, notes, result, run_date) VALUES (seq_test_run.NEXTVAL, 15, 14, 'Tested with 2 users in same room', 'FAIL', TO_DATE('2024-07-10','YYYY-MM-DD'));

--------------------------------------------------------------
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 3, 2, 'Session not expiring', 'After 30 min idle session is still active', 'HIGH', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 8, 9, 'Delete employee crashes app', 'NullPointerException when deleting employee with active tasks', 'CRITICAL', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 10, 14, 'CSV export timeout', 'Export fails with 1000+ rows, server returns 504', 'HIGH', 'IN_PROGRESS');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 15, 14, 'Message delay in chat', 'Messages arrive with 5+ second delay for second user', 'HIGH', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 3, 5, 'Logout button missing on timeout', 'After session timeout no logout button visible', 'MEDIUM', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 8, 2, 'Employee list not refreshed after delete', 'Page requires manual refresh to show updated list', 'LOW', 'FIXED');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 10, 9, 'Special characters break CSV', 'Commas in customer names break CSV columns', 'MEDIUM', 'IN_PROGRESS');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 15, 2, 'Chat file upload fails on mobile', 'File upload returns 413 error on Android', 'HIGH', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 3, 14, 'Token not invalidated after timeout', 'Old JWT token still works after session expires', 'CRITICAL', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 8, 5, 'Cannot delete manager with reports', 'No error message shown when delete is blocked by FK', 'MEDIUM', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 10, 2, 'Export button disabled for viewer role', 'Viewer role should be able to export but button is grayed out', 'LOW', 'FIXED');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 15, 5, 'Emoji not rendered in chat', 'Unicode emoji shows as question mark on Windows', 'LOW', 'OPEN');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 3, 9, 'Remember me checkbox ignored', 'Session expires even when Remember Me is checked', 'MEDIUM', 'IN_PROGRESS');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 8, 14, 'Duplicate employee created on double click', 'Clicking Save twice creates two identical records', 'HIGH', 'FIXED');
INSERT INTO BUGS (id_bug, id_run, id_user, title, description, severity, status) VALUES (seq_bug.NEXTVAL, 10, 2, 'Date format wrong in CSV export', 'Dates exported as MM/DD/YYYY instead of YYYY-MM-DD', 'LOW', 'OPEN');

COMMIT;


-- 2. CAST - POHĽADY

-- Uloha 1: 2 pohľady s netriviálnym selektom nad jednou tabuľkou

-- Pohľad 1: Zobrazuje používateľov prijatých po roku 2021 s datumom
CREATE OR REPLACE VIEW v_users_hired_after_2021 AS
SELECT id_user, first_name, last_name, role, TO_CHAR(hire_date, 'DD.MM.YYYY') AS hire_date_formatted
FROM USERS
WHERE hire_date > TO_DATE('2021-01-01', 'YYYY-MM-DD')
ORDER BY hire_date;

SELECT * FROM v_users_hired_after_2021;

-- Pohľad 2: Zobrazuje nedokoncene ulohy zoradene podla priority
CREATE OR REPLACE VIEW v_pending_tasks AS
SELECT id_task, title, priority, status,
    CASE priority
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH'     THEN 2
        WHEN 'MEDIUM'   THEN 3
        WHEN 'LOW'      THEN 4
    END AS priority_order
FROM TASKS
WHERE status != 'DONE'
ORDER BY priority_order;

SELECT * FROM v_pending_tasks;

-- Uloha 2: 3 pohľady so spájaním tabuliek

-- Pohľad 3: Zobrazuje členov projektových tímov s ich rolami
-- spája PROJECT_TEAMS, USERS a PROJECTS
CREATE OR REPLACE VIEW v_project_members AS
SELECT p.name AS project_name, u.first_name || ' ' || u.last_name AS member_name,
    u.role, pt.role_in_project, pt.joined_date
FROM PROJECT_TEAMS pt
JOIN USERS u ON pt.id_user = u.id_user
JOIN PROJECTS p ON pt.id_project = p.project_id;

SELECT * FROM v_project_members;

-- Pohľad 4: Zobrazuje plne informacie o testovacich behoch
-- spaja TEST_RUNS, TEST_CASES a USERS
CREATE OR REPLACE VIEW v_test_runs_full AS
SELECT tr.id_run, tc.title AS test_case_title,
    u.first_name || ' ' || u.last_name AS run_by,
    tr.result, tr.run_date, tr.notes
FROM TEST_RUNS tr
JOIN TEST_CASES tc ON tr.id_test_case = tc.id_test_case
JOIN USERS u ON tr.id_user = u.id_user;

SELECT * FROM v_test_runs_full;

-- Pohľad 5: Zobrazuje releases s nazvom projektu
-- a poctom testovacich scenárov v danom projekte
CREATE OR REPLACE VIEW v_releases_with_project AS
SELECT r.id_release, r.version, r.release_date,
    p.name AS project_name, p.status AS project_status,
    COUNT(tc.id_test_case) AS test_cases_count
FROM RELEASES r
JOIN PROJECTS p ON r.id_project = p.project_id
LEFT JOIN TEST_CASES tc ON p.project_id = tc.id_project
GROUP BY r.id_release, r.version, r.release_date, p.name, p.status;

SELECT * FROM v_releases_with_project;


-- Uloha 3: 2 pohľady s použitím agregačných funkcií alebo zoskupenia

-- Pohľad 6: Statistika testovacich behov pre kazdeho pouzivatela
-- zobrazi len tych co spustili aspon 1 test
CREATE OR REPLACE VIEW v_user_test_stats AS
SELECT u.first_name || ' ' || u.last_name AS full_name, u.role,
    COUNT(tr.id_run) AS total_runs,
    COUNT(CASE WHEN tr.result = 'PASS' THEN 1 END) AS passed,
    COUNT(CASE WHEN tr.result = 'FAIL' THEN 1 END) AS failed
FROM USERS u
JOIN TEST_RUNS tr ON u.id_user = tr.id_user
GROUP BY u.id_user, u.first_name, u.last_name, u.role
HAVING COUNT(tr.id_run) >= 1;

SELECT * FROM v_user_test_stats;

-- Pohľad 7: Statistika releases pre kazdy projekt
CREATE OR REPLACE VIEW v_project_releases_stats AS
SELECT p.name AS project_name, p.status AS project_status,
    COUNT(r.id_release) AS total_releases,
    MAX(r.release_date) AS last_release_date,
    MIN(r.release_date) AS first_release_date
FROM PROJECTS p
LEFT JOIN RELEASES r ON p.project_id = r.id_project
GROUP BY p.project_id, p.name, p.status
HAVING COUNT(r.id_release) > 0
ORDER BY total_releases DESC;

SELECT * FROM v_project_releases_stats;

-- Uloha 4: 1 pohľad s použitím množinových operácií

-- Pohľad 8: Spaja aktivne a dokoncene projekty do jedneho zoznamu
-- kazda cast ma vlastnu oznacku stavu
CREATE OR REPLACE VIEW v_projects_by_status AS
SELECT project_id, name, start_date, end_date, 'Active' AS status_label
FROM PROJECTS WHERE status = 'ACTIVE'
UNION
SELECT project_id, name, start_date, end_date, 'Completed' AS status_label
FROM PROJECTS WHERE status = 'COMPLETED'
ORDER BY status_label, name;

SELECT * FROM v_projects_by_status;

-- Uloha 5: 2 pohľady s použitím vnorených selektov

-- Pohľad 9: Zobrazi testovacie scenare ktore este neboli spustene
CREATE OR REPLACE VIEW v_untested_cases AS
SELECT tc.id_test_case, tc.title, tc.steps, tc.expected_result, p.name AS project_name
FROM TEST_CASES tc
JOIN PROJECTS p ON tc.id_project = p.project_id
WHERE tc.id_test_case NOT IN (SELECT DISTINCT id_test_case FROM TEST_RUNS);

SELECT * FROM v_untested_cases;

-- Pohľad 10: Zobrazi pouzivatelov ktori nahlasili chyby ale nemaju ziadne ulohy
CREATE OR REPLACE VIEW v_bug_reporters_no_tasks AS
SELECT id_user, first_name, last_name, role, email
FROM USERS
WHERE id_user IN (SELECT DISTINCT id_user FROM BUGS)
AND id_user NOT IN (SELECT DISTINCT id_user FROM TASKS);

SELECT * FROM v_bug_reporters_no_tasks;

-- Uloha 6: Sekvencia + trigger na automaticke generovanie PK

-- Sekvencia seq_bug je uz vytvorena vysie v 1. casti.
-- Trigger trg_bugs_autoid sluzi na automaticke doplnenie id_bug
CREATE OR REPLACE TRIGGER trg_bugs_autoid
BEFORE INSERT ON BUGS
FOR EACH ROW
BEGIN
    IF :NEW.id_bug IS NULL THEN
        :NEW.id_bug := seq_bug.NEXTVAL;
    END IF;
END;
/

-- Test - vlozenie bez id_bug
INSERT INTO BUGS (id_run, id_user, title, severity, status)
VALUES (1, 1, 'New bug found by test', 'LOW', 'OPEN');

SELECT * FROM BUGS WHERE title = 'New bug found by test';


-- Uloha 7: Ľubovoľný trigger (iný typ v predch. ulohe)
-- Trigger trg_task_status_change sluzi na logovanie zmien stavu ulohy.
SET SERVEROUTPUT ON;

CREATE OR REPLACE TRIGGER trg_task_status_change
AFTER UPDATE OF status ON TASKS
FOR EACH ROW
BEGIN
    IF :OLD.status != :NEW.status THEN
        DBMS_OUTPUT.PUT_LINE(
            'Task ' || :NEW.id_task || ' - ' || :NEW.title ||
            ': status changed from ' || :OLD.status ||
            ' to ' || :NEW.status
        );
    END IF;
END;
/

-- Test - zmena stavu ulohy
UPDATE TASKS SET status = 'DONE' WHERE id_task = 2;
SELECT id_task, title, status FROM TASKS WHERE id_task = 2;