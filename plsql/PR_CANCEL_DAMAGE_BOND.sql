CREATE OR REPLACE PROCEDURE ISS.PR_CANCEL_DAMAGE_BOND (
  I_DAMAGE_DT    IN  CHAR
, I_BOND_CODE    IN  CHAR
, I_DAMAGE_PRICE IN  NUMBER
, O_PRO_CN       OUT NUMBER -- 처리건수
) IS
  -- TYPE
  T_EVENT_INFO       EVENT_INFO_TYPE;               -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT     EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : 이벤트 OUTPUT
  T_ORGN_BOND_DAMAGE BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : 손상 원거래내역
  T_BOND_DAMAGE      BOND_DAMAGE%ROWTYPE;           -- ROWTYPE : 손상내역
  T_BOND_BALANCE     BOND_BALANCE%ROWTYPE;          -- ROWTYPE : 잔고
  
  -- CURSOR : 손상내역
  CURSOR C_BOND_DAMAGE_CUR IS
    SELECT *
      FROM BOND_DAMAGE
     WHERE DAMAGE_DT    = I_DAMAGE_DT     -- 손상일자
       AND BOND_CODE    = I_BOND_CODE     -- 종목코드
       AND DAMAGE_PRICE = I_DAMAGE_PRICE; -- 손상단가
       
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = T_ORGN_BOND_DAMAGE.TRD_DATE   -- 거래일자(잔고 PK)
       AND FUND_CODE = T_ORGN_BOND_DAMAGE.FUND_CODE  -- 펀드코드(잔고 PK)
       AND BOND_CODE = T_ORGN_BOND_DAMAGE.BOND_CODE  -- 종목코드(잔고 PK)
       AND BUY_DATE  = T_ORGN_BOND_DAMAGE.BUY_DATE   -- 매수일자(잔고 PK)
       AND BUY_PRICE = T_ORGN_BOND_DAMAGE.BUY_PRICE  -- 매수단가(잔고 PK)
       AND BALAN_SEQ = T_ORGN_BOND_DAMAGE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   I_DAMAGE_DT    -- 손상일자
  --   I_BOND_CODE    -- 종목코드
  --   I_DAMAGE_PRICE -- 손상단가
  ----------------------------------------------------------------------------------------------------
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)손상 처리된 내역 복구 처리
  --   * 손상내역을 조회하여 잔고 복구 처리
  --   * LOOP로 한건씩 손상 처리
  ----------------------------------------------------------------------------------------------------
  OPEN C_BOND_DAMAGE_CUR;
    LOOP
      FETCH C_BOND_DAMAGE_CUR INTO T_ORGN_BOND_DAMAGE;
      EXIT WHEN C_BOND_DAMAGE_CUR%NOTFOUND;
      
      ----------------------------------------------------------------------------------------------------
      -- 3)변수초기화
      --   * Object들을 초기화 및 Default값으로 설정함
      ----------------------------------------------------------------------------------------------------
      PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 4)취소 처리 프로시져 호출
      --   * INPUT 설정
      --   * EVENT_RESULT 테이블 원거래내역 삭제
      ----------------------------------------------------------------------------------------------------
      T_EVENT_INFO.FUND_CODE  := T_ORGN_BOND_DAMAGE.FUND_CODE; -- 펀드코드(잔고 PK)
      T_EVENT_INFO.BOND_CODE  := T_ORGN_BOND_DAMAGE.BOND_CODE; -- 종목코드(잔고 PK)
      T_EVENT_INFO.BUY_DATE   := T_ORGN_BOND_DAMAGE.BUY_DATE;  -- 매수일자(잔고 PK)
      T_EVENT_INFO.BUY_PRICE  := T_ORGN_BOND_DAMAGE.BUY_PRICE; -- 매수단가(잔고 PK)
      T_EVENT_INFO.BALAN_SEQ  := T_ORGN_BOND_DAMAGE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
      T_EVENT_INFO.EVENT_DATE := T_ORGN_BOND_DAMAGE.TRD_DATE;  -- 이벤트일
      T_EVENT_INFO.EVENT_SEQ  := T_ORGN_BOND_DAMAGE.EVENT_SEQ; -- 이벤트 SEQ
      
      PKG_EIR_NESTED_NSC.PR_CANCEL_EVENT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)잔고 조회
      --   * 손상내역을 가지고 잔고 조회
      ----------------------------------------------------------------------------------------------------
      OPEN C_BOND_BALANCE_CUR;
        FETCH C_BOND_BALANCE_CUR INTO T_BOND_BALANCE;
        IF C_BOND_BALANCE_CUR%NOTFOUND THEN
          CLOSE C_BOND_BALANCE_CUR;
          RAISE_APPLICATION_ERROR(-20011, '잔고 오류');
        END IF;
      CLOSE C_BOND_BALANCE_CUR;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 6)잔고 복구
      --   * 손상 처리에 대한 잔고 복구
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.BOOK_AMT        := T_ORGN_BOND_DAMAGE.CHBF_BOOK_AMT;       -- 장부금액
      T_BOND_BALANCE.BOOK_PRC_AMT    := T_ORGN_BOND_DAMAGE.CHBF_BOOK_PRC_AMT;   -- 장부원금
      T_BOND_BALANCE.BTRM_UNPAID_INT := T_ORGN_BOND_DAMAGE.BTRM_UNPAID_INT;     -- 미수이자
      T_BOND_BALANCE.SANGGAK_AMT     := T_BOND_BALANCE.SANGGAK_AMT + (T_ORGN_BOND_TRADE.DSCT_SANGGAK_AMT - T_ORGN_BOND_TRADE.EX_CHA_SANGGAK_AMT); -- 상각금액
      T_BOND_BALANCE.BTRM_EVAL_PRFT  := T_ORGN_BOND_DAMAGE.CHBF_BTRM_EVAL_PRFT; -- 전기평가이익
      T_BOND_BALANCE.BTRM_EVAL_LOSS  := T_ORGN_BOND_DAMAGE.CHBF_BTRM_EVAL_LOSS; -- 전기평가손실
      T_BOND_BALANCE.DAMAGE_YN       := 'N';                                    -- 손상여부(Y/N)
      T_BOND_BALANCE.DAMAGE_DT       := '';                                     -- 손상일자
      T_BOND_BALANCE.REDUCTION_AM    := 0;                                      -- 감액금액
      
      
      -- UPDATE : 잔고 업데이트
      UPDATE BOND_BALANCE 
         SET ROW = T_BOND_BALANCE
       WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
         AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
         AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
         AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
         AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
         AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
      
      
      ----------------------------------------------------------------------------------------------------
      -- 7)원거래내역 취소처리
      --   * 취소여부 'Y' 세팅후 업데이트
      ----------------------------------------------------------------------------------------------------
      T_ORGN_BOND_DAMAGE.CANCEL_YN := 'Y'; -- 취소여부(Y/N)
      
      -- UPDATE : 손상내역 업데이트
      UPDATE BOND_DAMAGE 
         SET ROW = T_ORGN_BOND_DAMAGE
       WHERE DAMAGE_DT  = T_ORGN_BOND_DAMAGE.DAMAGE_DT   -- 손상일자(PK)
         AND DAMAGE_SEQ = T_ORGN_BOND_DAMAGE.DAMAGE_SEQ; -- 손상일련번호(PK)
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 8)취소거래내역 등록
      ----------------------------------------------------------------------------------------------------
      PR_INIT_BOND_DAMAGE(T_BOND_DAMAGE);
      
      T_BOND_DAMAGE.DAMAGE_DT := I_DAMAGE_DT;                -- 손상일자(PK)
      -- 거래일련번호 채번 RULE //
      SELECT NVL(MAX(DAMAGE_SEQ), 0) + 1 AS DAMAGE_SEQ
        INTO T_BOND_DAMAGE.DAMAGE_SEQ                        -- 손상일련번호(PK)
        FROM BOND_DAMAGE
       WHERE DAMAGE_DT = I_DAMAGE_DT;
      -- // END
      T_BOND_DAMAGE.FUND_CODE   := T_BOND_BALANCE.FUND_CODE; -- 펀드코드
      T_BOND_DAMAGE.BOND_CODE   := T_BOND_BALANCE.BOND_CODE; -- 종목코드
      T_BOND_DAMAGE.BUY_DATE    := T_BOND_BALANCE.BUY_DATE;  -- 매수일자
      T_BOND_DAMAGE.BUY_PRICE   := T_BOND_BALANCE.BUY_PRICE; -- 매수단가
      T_BOND_DAMAGE.BALAN_SEQ   := T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호
  
      T_BOND_DAMAGE.CANCEL_YN   := 'Y';                      -- 취소여부(Y/N)
      T_BOND_DAMAGE.DAMAGE_TYPE := '4';                      -- 손상구분(1.손상, 2.추가손상, 3. 환입, 4.취소)
      
      -- INSERT : 손상내역 등록
      INSERT INTO BOND_DAMAGE VALUES T_BOND_DAMAGE;
      
      
      
    END LOOP;
  CLOSE C_BOND_DAMAGE_CUR;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PR_DAMAGE_BOND END');
  
END;