CREATE OR REPLACE FUNCTION ISS.FN_CALC_DAYS (
  -- FROM ~ TO �ϼ����
    I_FROM_DATE IN CHAR
  , I_TO_DATE   IN CHAR
  ) RETURN NUMBER AS
BEGIN
    RETURN TO_DATE(I_TO_DATE,'YYYYMMDD') - TO_DATE(I_FROM_DATE,'YYYYMMDD');
END;