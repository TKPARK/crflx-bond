
-- 종목 조회
DESC BOND_INFO;
SELECT * FROM BOND_INFO;

-- 채권 조회
DESC EVENT_RESULT_NESTED_S;
SELECT * FROM EVENT_RESULT_NESTED_S ORDER BY BOND_CODE;

-- 잔고 조회
DESC BOND_BALANCE;
SELECT * FROM BOND_BALANCE ORDER BY BIZ_DATE, FUND_CODE, BOND_CODE, BUY_DATE, BUY_PRICE, BALAN_SEQ;

-- 거래내역 조회
DESC BOND_TRADE;
SELECT * FROM BOND_TRADE ORDER BY TRD_DATE, TRD_SEQ;


--INSERT INTO BOND_INFO VALUES('KR_단리채', '3', '20121120', '20141120', 6, 10);

-- 해당 채권의 전체 CF_LIST 조회
SELECT A.BOND_CODE, A.BUY_DATE, A.EVENT_DATE, A.EVENT_TYPE, T.*
  FROM EVENT_RESULT_N_S_TKP A, TABLE(A.CF_LIST) T
 WHERE A.BOND_CODE = 'KR01234567'
   AND A.BUY_DATE = '20121130'
   AND A.EVENT_DATE = '20121210'
 ORDER BY A.EVENT_DATE, T.BASE_DATE;

-- 해당 채권의 전체 SGF_LIST 조회
SELECT A.BOND_CODE, A.BUY_DATE, A.EVENT_DATE, A.EVENT_TYPE, T.*
  FROM EVENT_RESULT_N_S_TKP A, TABLE(A.SGF_LIST) T
 WHERE A.BOND_CODE = 'KR01234567'
   AND A.BUY_DATE = '20121130'
   AND A.EVENT_DATE = '20121210'
 ORDER BY A.EVENT_DATE, T.BASE_DATE, SEQ;


-- DELETE
--DELETE FROM BOND_INFO WHERE BOND_CODE = 'KR_TKPARK';
--DELETE FROM EVENT_RESULT_NESTED_S;
--DELETE FROM BOND_BALANCE;
--DELETE FROM BOND_TRADE;
--DELETE FROM EVENT_RESULT_N_S_TKP WHERE BOND_CODE = 'KR01234567' AND EVENT_DATE = '20121130' AND EVENT_SEQ = 2;


SELECT * FROM EVENT_RESULT_NESTED_S ORDER BY BOND_CODE;

SELECT A.BOND_CODE, A.BUY_DATE, A.EVENT_DATE, A.EVENT_TYPE, T.*
  FROM EVENT_RESULT_NESTED_S A, TABLE(A.CF_LIST) T
 WHERE A.BUY_DATE = '20121130'
   AND A.BOND_CODE = '20130606'
 ORDER BY A.EVENT_DATE, T.BASE_DATE;


SELECT A.BOND_CODE, A.BUY_DATE, A.EVENT_DATE, A.EVENT_TYPE, T.*
  FROM EVENT_RESULT_NESTED_S A, TABLE(A.SGF_LIST) T
 WHERE A.BUY_DATE = '20121130'
   AND A.BOND_CODE = '20130606'
 ORDER BY T.BASE_DATE, SEQ;
