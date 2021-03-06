
DESC EVENT_RESULT_NESTED_S;
SELECT * FROM EVENT_RESULT_N_S_TKP ORDER BY BOND_CODE;
--DELETE FROM EVENT_RESULT_N_S_TKP WHERE BOND_CODE = '이표채20년' AND EVENT_SEQ = 2;

-- 해당 채권의 전체 CF_LIST 조회
SELECT A.BOND_CODE, A.BUY_DATE, A.EVENT_DATE, A.EVENT_TYPE, T.*
  FROM EVENT_RESULT_N_S_TKP A, TABLE(A.CF_LIST) T
 WHERE A.BOND_CODE = '이표채02년'
   AND A.BUY_DATE = '20130515'
 ORDER BY A.EVENT_DATE, T.BASE_DATE;

-- 해당 채권의 전체 SGF_LIST 조회
SELECT A.BOND_CODE, A.BUY_DATE, A.EVENT_DATE, A.EVENT_TYPE, T.*
  FROM EVENT_RESULT_N_S_TKP A, TABLE(A.SGF_LIST) T
 WHERE A.BOND_CODE = '이표채02년'
   AND A.BUY_DATE = '20130515'
 ORDER BY A.EVENT_DATE, T.BASE_DATE, SEQ;
