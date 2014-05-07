CREATE OR REPLACE PROCEDURE ISS.PR_ADD_DAMAGE_BOND (
  I_TRD_DATE        IN  CHAR
, I_BOND_CODE       IN  CHAR
, I_DAMAGE_PRICE    IN  NUMBER
, I_ADD_DAMAGE_TYPE IN  CHAR   -- 손상구분(2.추가손상, 3. 환입)
, O_PRO_CN          OUT NUMBER -- 처리건수
) IS
  -- TYPE
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : 잔고
  T_BOND_DAMAGE    BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : 손상내역
  
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_TRD_DATE  -- 거래일자(잔고 PK)
       AND BOND_CODE = I_BOND_CODE -- 종목코드(잔고 PK)
       AND DAMAGE_YN = 'Y'         -- 손상여부(N인 잔고만)
       AND TOT_QTY   > 0;          -- 총잔고수량(0이상인 것)
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   I_TRD_DATE     -- 거래일자
  --   I_BOND_CODE    -- 종목코드
  --   I_DAMAGE_PRICE -- 손상단가
  ----------------------------------------------------------------------------------------------------
  O_PRO_CN := 0;
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)잔고 손상 처리
  --   * 손상된 종목을 가지고 있는 잔고 조회
  --   * LOOP로 한건씩 손상 처리
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_BALANCE_CUR;
    LOOP
      FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
      EXIT WHEN C_BOND_BALANCE_CUR%NOTFOUND;
      
      ----------------------------------------------------------------------------------------------------
      -- 3)잔고 Validation
      --   * 
      ----------------------------------------------------------------------------------------------------
      
      
      ----------------------------------------------------------------------------------------------------
      -- 4)손상내역 등록
      --   * 손상후 추가손상/환입시는 감액금액만 변동
      ----------------------------------------------------------------------------------------------------
      PR_INIT_BOND_DAMAGE(T_BOND_DAMAGE);
      
      T_BOND_DAMAGE.DAMAGE_DT := I_TRD_DATE;             -- 손상일자(PK)
      
      -- 거래일련번호 채번 RULE //
      SELECT NVL(MAX(DAMAGE_SEQ), 0) + 1 AS DAMAGE_SEQ
        INTO T_BOND_DAMAGE.DAMAGE_SEQ                    -- 손상일련번호(PK)
        FROM BOND_DAMAGE
       WHERE DAMAGE_DT = I_TRD_DATE;
      -- // END
      
      T_BOND_DAMAGE.FUND_CODE       := T_BOND_BALANCE.FUND_CODE;                     -- 펀드코드(잔고PK)
      T_BOND_DAMAGE.BOND_CODE       := T_BOND_BALANCE.BOND_CODE;                     -- 종목코드(잔고PK)
      T_BOND_DAMAGE.BUY_DATE        := T_BOND_BALANCE.BUY_DATE;                      -- 매수일자(잔고PK)
      T_BOND_DAMAGE.BUY_PRICE       := T_BOND_BALANCE.BUY_PRICE;                     -- 매수단가(잔고PK)
      T_BOND_DAMAGE.BALAN_SEQ       := T_BOND_BALANCE.BALAN_SEQ;                     -- 잔고일련번호(잔고PK)
      T_BOND_DAMAGE.CANCEL_YN       := 'N';                                          -- 취소여부(Y/N)
      T_BOND_DAMAGE.DAMAGE_TYPE     := I_ADD_DAMAGE_TYPE;                            -- 손상구분(1.손상, 2.추가손상, 3. 환입, 4.취소)
      T_BOND_DAMAGE.DAMAGE_PRICE    := I_DAMAGE_PRICE;                               -- 손상단가
      T_BOND_DAMAGE.DAMAGE_QTY      := T_BOND_BALANCE.TOT_QTY;                       -- 손상수량
      T_BOND_DAMAGE.DAMAGE_EVAL_AMT := I_DAMAGE_PRICE * T_BOND_BALANCE.TOT_QTY / 10; -- 손상평가금액(= 수량 * 손상단가 / 10)
      
      -- 2.추가손상, 3.환입 처리 RULE //
      IF I_ADD_DAMAGE_TYPE = '2' THEN
        T_BOND_DAMAGE.REDUCTION_AM := T_BOND_BALANCE.BOOK_PRC_AMT - T_BOND_DAMAGE.DAMAGE_EVAL_AMT; -- 감액금액 = (장부원금 - 손상평가금액)
      ELSIF I_ADD_DAMAGE_TYPE = '3' THEN
        T_BOND_DAMAGE.REDUCTION_AM := ABS(T_BOND_BALANCE.BOOK_PRC_AMT - T_BOND_DAMAGE.DAMAGE_EVAL_AMT - T_BOND_DAMAGE.REDUCTION_AM); -- 감액금액 = ABS(장부원금 - 손상평가금액 - 기 감액금액)
      END IF;
      -- // END
      
      -- INSERT : 손상내역 등록
      INSERT INTO BOND_DAMAGE VALUES T_BOND_DAMAGE;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)잔고 업데이트
      --   * 손상후 추가손상/환입시는 감액금액만 변동
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.REDUCTION_AM    := T_BOND_DAMAGE.REDUCTION_AM; -- 감액금액
      
      
      -- UPDATE : 잔고 업데이트
      UPDATE BOND_BALANCE 
         SET ROW = T_BOND_BALANCE
       WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
         AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
         AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
         AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
         AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
         AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
      
      O_PRO_CN := O_PRO_CN + 1;
    END LOOP;
  CLOSE C_BOND_BALANCE_CUR;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PR_ADD_DAMAGE_BOND END');
  
END;