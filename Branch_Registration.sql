CREATE OR REPLACE PROCEDURE p_Branch_Reg (
    p_branch_name IN  VARCHAR2,
    p_ifsc_cd     IN  VARCHAR2,
    p_brnch_add   IN  VARCHAR2,
    p_city        IN  VARCHAR2,
    p_state       IN  VARCHAR2,
    p_pin_cd      IN  VARCHAR2,
    p_contact_no  IN  VARCHAR2,
    error_desc    OUT VARCHAR2
)
IS
    i_cnt            NUMBER;
    e_branch_exists  EXCEPTION;   -- user-defined exception
BEGIN
    error_desc := 'SUCCESS';

    -- Check whether this branch already exists
	SELECT COUNT(*)
	INTO i_cnt
	FROM BRANCH_MASTER
	WHERE UPPER(BRANCH_NAME) = UPPER(p_branch_name)
	OR IFSC_CODE          = p_ifsc_cd;

    IF i_cnt = 0 THEN
        INSERT INTO BRANCH_MASTER
               (BRANCH_NAME, IFSC_CODE, BRANCH_ADDRESS, CITY, STATE,
                PINCODE, CONTACT_NUMBER, CREATED_DATE)
        VALUES (p_branch_name, p_ifsc_cd, p_brnch_add, p_city, p_state,
                p_pin_cd, p_contact_no, SYSDATE);

        COMMIT;
    ELSE
        RAISE e_branch_exists;
    END IF;

EXCEPTION
    WHEN e_branch_exists THEN
        ROLLBACK;
        error_desc := 'Branch name or IFSC code already exists';

    WHEN DUP_VAL_ON_INDEX THEN
        ROLLBACK;
        error_desc := 'Duplicate value: ' || SQLERRM;

    WHEN OTHERS THEN
        ROLLBACK;
        error_desc := SQLCODE || '|' || SQLERRM;
END p_Branch_Reg;
/