DECLARE
  T_BOND_DAMAGE   BOND_DAMAGE%ROWTYPE;       -- OUTPUT
BEGIN
  -- 손상
  PR_DAMAGE_BOND('20130520'  -- 손상일자
               , 'KR_이표채' -- 손상종목
               , 10650       -- 손상단가
               , T_BOND_DAMAGE);
    
END;