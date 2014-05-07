DECLARE
  O_PRO_CN NUMBER := 0;
BEGIN
  -- 손상
  PR_CANCEL_DAMAGE_BOND('20140429'  -- 손상일자
                      , 'KR_이표채' -- 손상종목
                      , 10650       -- 손상단가
                      , O_PRO_CN);
  
  DBMS_OUTPUT.PUT_LINE('O_PRO_CN=' || O_PRO_CN);
  
END;