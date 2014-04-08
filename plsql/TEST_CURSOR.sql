DECLARE
  -- CURSOR
  CURSOR C_BOND_INFO_CUR IS
    SELECT A.ROWID
         , A.*
      FROM BOND_INFO A;
  -- TYPE
  T_BOND_INFO C_BOND_INFO_CUR%ROWTYPE;
BEGIN
  -- OPEN
  OPEN C_BOND_INFO_CUR;
    FETCH C_BOND_INFO_CUR INTO T_BOND_INFO;
  CLOSE C_BOND_INFO_CUR;
  
  DBMS_OUTPUT.PUT_LINE(T_BOND_INFO.BOND_CODE);
  DBMS_OUTPUT.PUT_LINE(T_BOND_INFO.ROWID);
  
  --T_BOND_INFO.BOND_CODE := 'KR_�ܸ�ä00';
  
  UPDATE BOND_INFO
     SET ROW = CAST(T_BOND_INFO AS BOND_INFO%ROWTYPE)
   WHERE ROWID = T_BOND_INFO.ROWID;
  
  DBMS_OUTPUT.PUT_LINE('END');
    
END;