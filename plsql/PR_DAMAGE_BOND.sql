CREATE OR REPLACE PROCEDURE ISS.PR_DAMAGE_BOND (
  I_DAMAGE_INFO  IN  SELL_DAMAGE_TYPE             -- TYPE    : 손상정보
, O_BOND_TRADE OUT BOND_TRADE%ROWTYPE             -- ROWTYPE : 거래내역
) IS
  -- TYPE
  T_EVENT_INFO     EVENT_INFO_TYPE;               -- TYPE    : 이벤트 INPUT
  T_EVENT_RESULT   EVENT_RESULT_EIR%ROWTYPE;      -- ROWTYPE : 이벤트 OUTPUT
  
  -- CURSOR : 잔고
  CURSOR C_BOND_BALANCE_CUR IS
    SELECT *
      FROM BOND_BALANCE
     WHERE BIZ_DATE  = I_DAMAGE_INFO.TRD_DATE   -- 거래일자(잔고 PK)
       AND FUND_CODE = I_DAMAGE_INFO.FUND_CODE  -- 펀드코드(잔고 PK)
       AND BOND_CODE = I_DAMAGE_INFO.BOND_CODE  -- 종목코드(잔고 PK)
       AND BOOK_AMT > 0;                        -- 장부금액(0이상인 것)
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증(INPUT 필드)
  --   TRD_DATE   -- 거래일자(잔고 PK)
  --   FUND_CODE  -- 펀드코드(잔고 PK)
  --   BOND_CODE  -- 종목코드(잔고 PK)
  ----------------------------------------------------------------------------------------------------
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)잔고 조회
  --   * 손상된 종목을 가지고 있는 잔고 조회
  --   * FOR LOOP로 한건씩 손상 처리함
  ----------------------------------------------------------------------------------------------------
  FOR C1 IN C_BOND_BALANCE_CUR LOOP
    ----------------------------------------------------------------------------------------------------
    -- 3)장부금액 확인
    --   * 장부금액이 0이하인지 확인하고 0이하인 경우 CONTINUE;
    ----------------------------------------------------------------------------------------------------
    IF C1.BOOK_AMT <= 0 THEN
      CONTINUE;
    END IF;
    
    
    ----------------------------------------------------------------------------------------------------
    -- 4)변수초기화
    --   * Object들을 초기화 및 Default값으로 설정함
    ----------------------------------------------------------------------------------------------------
    PR_INIT_EVENT_INFO(T_EVENT_INFO);
    PR_INIT_EVENT_RESULT(T_EVENT_RESULT);    
    
    
    ----------------------------------------------------------------------------------------------------
    -- 5)손상 처리 프로시져 호출
    --   * INPUT 설정
    --   * 상각표 재산출, 상각이자 적용
    ----------------------------------------------------------------------------------------------------
    T_EVENT_INFO.FUND_CODE  := C1.FUND_CODE;             -- 펀드코드(잔고 PK)
    T_EVENT_INFO.BOND_CODE  := C1.BOND_CODE;             -- 종목코드(잔고 PK)
    T_EVENT_INFO.BUY_DATE   := C1.BIZ_DATE;              -- 매수일자(잔고 PK)
    T_EVENT_INFO.BUY_PRICE  := C1.BUY_PRICE;             -- 매수단가(잔고 PK)
    T_EVENT_INFO.BALAN_SEQ  := C1.BALAN_SEQ;             -- 잔고일련번호(잔고 PK)
    T_EVENT_INFO.EVENT_DATE := I_DAMAGE_INFO.SETL_DATE;  -- 이벤트일
    T_EVENT_INFO.EVENT_TYPE := '4';                      -- Event종류(1.매수,2.매도,3.금리변동,4.손상,5.회복)
    T_EVENT_INFO.DL_UV      := I_DAMAGE_INFO.SELL_PRICE; -- 거래단가
    
    PKG_EIR_NESTED_NSC.PR_APPLY_ADD_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
    
    
    ----------------------------------------------------------------------------------------------------
    -- 6)손상내역 등록
    --   * 
    ----------------------------------------------------------------------------------------------------
    
    
    ----------------------------------------------------------------------------------------------------
    -- 7)잔고 업데이트
    --   * 
    ----------------------------------------------------------------------------------------------------
    
    
    
  END LOOP;
  
  COMMIT;
  
  DBMS_OUTPUT.PUT_LINE('PR_DAMAGE_BOND END');
  
END;