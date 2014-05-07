DECLARE
  O_PRO_CN NUMBER := 0;
BEGIN
  -- 손상
  PR_ADD_DAMAGE_BOND('20121231'  -- 손상일자
                   , 'KR_이표채' -- 손상종목
                   , 10690       -- 손상단가
                   , '3'         -- 손상구분(2.추가손상, 3. 환입)
                   , O_PRO_CN);
  
  DBMS_OUTPUT.PUT_LINE('O_PRO_CN=' || O_PRO_CN);
  
END;