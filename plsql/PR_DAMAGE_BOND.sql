CREATE OR REPLACE PROCEDURE ISS.PR_DAMAGE_BOND (
  I_TRD_DATE     IN CHAR(8)
, I_BOND_CODE    IN CHAR(12)
, I_DAMAGE_PRICE IN NUMBER
, O_BOND_DAMAGE  OUT BOND_DAMAGE%ROWTYPE          -- ROWTYPE : 손상내역
) IS
  -- TYPE
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT   EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : 이벤트 OUTPUT
  T_BOND_BALANCE   BOND_BALANCE%ROWTYPE;          -- ROWTYPE : 잔고
  
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_TRD_DATE   -- 거래일자(잔고 PK)
       AND BOND_CODE = I_BOND_CODE  -- 종목코드(잔고 PK)
       AND BOOK_AMT  > 0;           -- 장부금액(0이상인 것)
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   I_TRD_DATE     -- 거래일자
  --   I_BOND_CODE    -- 종목코드
  --   I_DAMAGE_PRICE -- 손상단가
  ----------------------------------------------------------------------------------------------------
  
  
  
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
      -- 3)변수초기화
      --   * Object들을 초기화 및 Default값으로 설정함
      ----------------------------------------------------------------------------------------------------
      PKG_EIR_NESTED_NSC.PR_EVENT_INFO_TYPE_INIT(T_EVENT_INFO);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 4)손상 처리 프로시져 호출
      --   * INPUT 설정
      --   * 상각표 재산출, 상각이자 적용
      ----------------------------------------------------------------------------------------------------
      T_EVENT_INFO.FUND_CODE  := T_BOND_BALANCE.FUND_CODE; -- 펀드코드(잔고 PK)
      T_EVENT_INFO.BOND_CODE  := T_BOND_BALANCE.BOND_CODE; -- 종목코드(잔고 PK)
      T_EVENT_INFO.BUY_DATE   := T_BOND_BALANCE.BIZ_DATE;  -- 매수일자(잔고 PK)
      T_EVENT_INFO.BUY_PRICE  := T_BOND_BALANCE.BUY_PRICE; -- 매수단가(잔고 PK)
      T_EVENT_INFO.BALAN_SEQ  := T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
      T_EVENT_INFO.EVENT_DATE := I_TRD_DATE;               -- 이벤트일
      T_EVENT_INFO.EVENT_TYPE := '4';                      -- Event종류(1.매수, 2.매도, 3.금리변동, 4.손상, 5.회복)
      T_EVENT_INFO.DL_UV      := I_DAMAGE_PRICE;           -- 거래단가
      
      PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 5)손상내역 등록
      --   * 손상내역 TABLE에 내역 등록
      ----------------------------------------------------------------------------------------------------
      O_BOND_DAMAGE.DAMAGE_DT := I_TRD_DATE; -- 손상일자(PK)
      
      -- 거래일련번호 채번 RULE //
      SELECT NVL(MAX(DAMAGE_SEQ), 0) + 1 AS DAMAGE_SEQ
        INTO O_BOND_DAMAGE.DAMAGE_SEQ                    -- 손상일련번호(PK)
        FROM BOND_DAMAGE
       WHERE DAMAGE_DT = I_TRD_DATE;
      -- // END
      
      O_BOND_DAMAGE.FUND_CODE      := T_BOND_BALANCE.FUND_CODE; -- 펀드코드
      O_BOND_DAMAGE.BOND_CODE      := T_BOND_BALANCE.BOND_CODE; -- 종목코드
      O_BOND_DAMAGE.BUY_DATE       := T_BOND_BALANCE.BUY_DATE;  -- 매수일자
      O_BOND_DAMAGE.BUY_PRICE      := T_BOND_BALANCE.BUY_PRICE; -- 매수단가
      O_BOND_DAMAGE.BALAN_SEQ      := T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호
      O_BOND_DAMAGE.REDUCTION_AM   := ; -- 감액금액
      
      -- INSERT : 손상내역 등록
      INSERT INTO BOND_DAMAGE VALUES O_BOND_DAMAGE;
      
      
      
      ----------------------------------------------------------------------------------------------------
      -- 6)잔고 업데이트
      --   * 손상시 잔고에서 변경되는 부분 업데이트
      ----------------------------------------------------------------------------------------------------
      T_BOND_BALANCE.BOOK_AMT := ; -- 장부금액
      T_BOND_BALANCE.BOOK_PRC_AMT := ; -- 장부원금
      T_BOND_BALANCE.BTRM_UNPAID_INT := ; -- 미수이자
      T_BOND_BALANCE.SANGGAK_AMT := ; -- 할인상각이자
      
      -- UPDATE : 잔고 업데이트
      UPDATE BOND_BALANCE 
         SET ROW = T_BOND_BALANCE
       WHERE BIZ_DATE  = T_BOND_BALANCE.BIZ_DATE   -- 영업일자(잔고 PK)
         AND FUND_CODE = T_BOND_BALANCE.FUND_CODE  -- 펀드코드(잔고 PK)
         AND BOND_CODE = T_BOND_BALANCE.BOND_CODE  -- 종목코드(잔고 PK)
         AND BUY_DATE  = T_BOND_BALANCE.BUY_DATE   -- 매수일자(잔고 PK)
         AND BUY_PRICE = T_BOND_BALANCE.BUY_PRICE  -- 매수단가(잔고 PK)
         AND BALAN_SEQ = T_BOND_BALANCE.BALAN_SEQ; -- 잔고일련번호(잔고 PK)
      
    END LOOP;
  CLOSE C_BOND_BALANCE_CUR;
  
  COMMIT;
  DBMS_OUTPUT.PUT_LINE('PR_DAMAGE_BOND END');
  
END;