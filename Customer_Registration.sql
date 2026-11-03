CREATE OR REPLACE PROCEDURE p_Customer_Reg (
    p_fname      IN  VARCHAR2,
    p_mname      IN  VARCHAR2,
    p_lname      IN  VARCHAR2,
    p_email      IN  VARCHAR2,
    p_dob        IN  DATE,
    p_gender     IN  VARCHAR2,
    p_mobno      IN  VARCHAR2,
    p_pan_no     IN  VARCHAR2,
    p_addhar     IN  VARCHAR2,
    p_id         IN  VARCHAR2,
    p_address    IN  VARCHAR2,
    p_add_line_1 IN  VARCHAR2,
    p_add_line_2 IN  VARCHAR2,
    p_city       IN  VARCHAR2,
    p_state      IN  VARCHAR2,
    p_country    IN  VARCHAR2,
    p_pin_code   IN  VARCHAR2,
    p_updt_dt    IN  DATE,
    error_desc   OUT VARCHAR2
)
IS
    i_cnt          NUMBER;
    v_cust_id      customer_master.CIN%TYPE;
    e_cust_exists  EXCEPTION;
    e_invalid      EXCEPTION;
BEGIN
    error_desc := 'Success';

    -- 1. Mandatory field validation
    IF p_fname IS NULL OR p_lname IS NULL OR p_mobno IS NULL THEN
        error_desc := 'First name, last name and mobile number are mandatory';
        RAISE e_invalid;
    END IF;

    IF NOT REGEXP_LIKE(p_mobno, '^[6-9][0-9]{9}$') THEN
        error_desc := 'Invalid mobile number (must be 10 digits)';
        RAISE e_invalid;
    END IF;

    IF p_email IS NOT NULL
       AND NOT REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
        error_desc := 'Invalid email format';
        RAISE e_invalid;
    END IF;

    IF p_pan_no IS NOT NULL
       AND NOT REGEXP_LIKE(UPPER(p_pan_no), '^[A-Z]{5}[0-9]{4}[A-Z]$') THEN
        error_desc := 'Invalid PAN format (e.g. ABCDE1234F)';
        RAISE e_invalid;
    END IF;

    IF p_addhar IS NOT NULL
       AND NOT REGEXP_LIKE(p_addhar, '^[0-9]{12}$') THEN
        error_desc := 'Invalid Aadhaar number (must be 12 digits)';
        RAISE e_invalid;
    END IF;

    IF p_dob IS NULL OR p_dob > ADD_MONTHS(TRUNC(SYSDATE), -216) THEN
        error_desc := 'Customer must be at least 18 years old';
        RAISE e_invalid;
    END IF;

    -- 2. Duplicate check on mobile, PAN or Aadhaar
    SELECT COUNT(*)
      INTO i_cnt
      FROM customer_master
     WHERE Mob_no = p_mobno
        OR (p_pan_no IS NOT NULL AND UPPER(Pan_number) = UPPER(p_pan_no))
        OR (p_addhar IS NOT NULL AND Addhar_No = p_addhar);

    IF i_cnt > 0 THEN
        RAISE e_cust_exists;
    END IF;

    -- 3. Generate customer ID and insert
    SELECT SEQ_CUSTOMER.NEXTVAL INTO v_cust_id FROM dual;

    INSERT INTO customer_master
           (CIN, f_name, m_name, l_name, Email, DOB, gender, Mob_no,
            Pan_number, Addhar_No, Id_Number, Address, Add_line_1,
            Add_line_2, City, State, Country, Pin_Code,
            Customer_Status, Create_dt, Updated_Dt)
    VALUES (v_cust_id, TRIM(p_fname), TRIM(p_mname), TRIM(p_lname),
            LOWER(TRIM(p_email)), p_dob, UPPER(p_gender), p_mobno,
            UPPER(p_pan_no), p_addhar, p_id, p_address, p_add_line_1,
            p_add_line_2, p_city, p_state, p_country, p_pin_code,
            'Active', SYSDATE, NVL(p_updt_dt, SYSDATE));

    COMMIT;

EXCEPTION
    WHEN e_invalid THEN
        ROLLBACK;                       -- error_desc already set above

    WHEN e_cust_exists THEN
        ROLLBACK;
        error_desc := 'Customer already exists (mobile, PAN or Aadhaar matched)';

    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        error_desc := 'Duplicate value: ' || SQLERRM;

    WHEN OTHERS THEN
        ROLLBACK;
        error_desc := SQLCODE || '-' || SQLERRM;
END p_Customer_Reg;
/