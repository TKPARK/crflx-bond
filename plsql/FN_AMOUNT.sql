CREATE OR REPLACE FUNCTION ISS.FN_AMOUNT (
    I_AMT IN CHAR
  ) RETURN NUMBER AS
BEGIN
    RETURN TRUNC(I_AMT);
END;