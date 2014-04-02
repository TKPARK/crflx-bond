CREATE OR REPLACE PROCEDURE ISS.PR_NEW_BOND_EVENT (
  I_BOND_TRADE IN OUT BOND_TRADE%ROWTYPE -- ROWTYPE : 거래내역 TABLE
) IS
  --
  T_EVENT_INFO   EVENT_INFO_TYPE;        -- TYPE : EVENT_INFO_TYPE
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;   -- ROWTYPE : 잔고 TABLE
BEGIN
  ----------------------------------------------------------------------------------------------------
  -- 1)입력값 검증
  ----------------------------------------------------------------------------------------------------
  -- 매수단가
  IF I_BOND_TRADE.BUY_PRICE <= 0 THEN
    PCZ_RAISE(-20999, '매수단가 오류');
  END IF;
  -- 매매수량
  IF I_BOND_TRADE.TRD_QTY <= 0 THEN
    PCZ_RAISE(-20999, '매매수량 오류');
  END IF;
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 2)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO := FN_INIT_EVENT_INFO();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  -- 잔고TABLE 일련번호 채번
  SELECT NVL(MAX(A.BALAN_SEQ), 0) + 1 AS BALAN_SEQ
    INTO I_BOND_TRADE.BALAN_SEQ
    FROM BOND_BALANCE A
   WHERE A.BIZ_DATE  = I_BOND_TRADE.BIZ_DATE
     AND A.FUND_CODE = I_BOND_TRADE.FUND_CODE
     AND A.BOND_CODE = I_BOND_TRADE.BOND_CODE
     AND A.BUY_DATE  = I_BOND_TRADE.BUY_DATE
     AND A.BUY_PRICE = I_BOND_TRADE.BUY_PRICE;

  -- 이벤트 결과 TABLE SEQ 채번
--  SELECT NVL(MAX(A.EVENT_SEQ), 0) + 1 AS EVENT_SEQ
--    INTO I_BOND_TRADE.EVENT_SEQ
--    FROM EVENT_RESULT_NESTED_S A
--   WHERE A.FUND_CODE  = I_BOND_TRADE.FUND_CODE
--     AND A.BOND_CODE  = I_BOND_TRADE.BOND_CODE
--     AND A.BUY_DATE   = I_BOND_TRADE.BUY_DATE
--     AND A.BUY_PRICE  = I_BOND_TRADE.BUY_PRICE
--     AND A.BALAN_SEQ  = I_BOND_TRADE.BALAN_SEQ
--     AND A.EVENT_DATE = I_BOND_TRADE.EVENT_DATE;

  
  
  ----------------------------------------------------------------------------------------------------
  -- 3-1)INPUT 설정
  ----------------------------------------------------------------------------------------------------
  T_EVENT_INFO.FUND_CODE  := I_BOND_TRADE.FUND_CODE;           -- 펀드코드 (채권잔고의 PK)
  T_EVENT_INFO.BOND_CODE  := I_BOND_TRADE.BOND_CODE;           -- 종목코드 (채권잔고의 PK)
  T_EVENT_INFO.BUY_DATE   := I_BOND_TRADE.BUY_DATE;            -- Buy Date (채권잔고의 PK)
  T_EVENT_INFO.BUY_PRICE  := I_BOND_TRADE.BUY_PRICE;           -- 매수단가 (채권잔고의 PK)
  T_EVENT_INFO.BALAN_SEQ  := I_BOND_TRADE.BALAN_SEQ;           -- 잔고일련번호 (채권잔고의 PK)
  T_EVENT_INFO.EVENT_DATE := I_BOND_TRADE.EVENT_DATE;          -- 이벤트일 (PK)
  T_EVENT_INFO.EVENT_SEQ  := I_BOND_TRADE.EVENT_SEQ;           -- 이벤트SEQ(PK)
  T_EVENT_INFO.EVENT_TYPE := I_BOND_TRADE.GOODS_BUY_SELL_SECT; -- Event 종류
  T_EVENT_INFO.DL_UV      := I_BOND_TRADE.BUY_PRICE;           -- 거래단가
  T_EVENT_INFO.DL_QT      := I_BOND_TRADE.TRD_QTY;             -- 거래수량
  T_EVENT_INFO.STL_DT_TP  := I_BOND_TRADE.STT_TERM_SECT;       -- 결제일구분
  T_EVENT_INFO.IR         := I_BOND_TRADE.BOND_IR;             -- 표면이자율
  
  ----------------------------------------------------------------------------------------------------
  -- 3-2)최초 매수 이벤트 처리 프로시져 호출
  --   * 경과이자, 현금흐름 생성, EIR산출, 상각표 생성 처리
  ----------------------------------------------------------------------------------------------------
  PKG_EIR_NESTED_NSC.PR_EVENT(T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  ----------------------------------------------------------------------------------------------------
  -- 4)기준정보 계산
  --   * T_EVENT_RESULT 데이터를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  ----------------------------------------------------------------------------------------------------
  I_BOND_TRADE.ACCRUED_INT  := T_EVENT_RESULT.ACCRUED_INT;                                -- 경과이자
  I_BOND_TRADE.BOND_EIR     := T_EVENT_RESULT.EIR;                                        -- 유효이자율
  I_BOND_TRADE.TRD_FACE_AMT := I_BOND_TRADE.TRD_QTY * 1000;                               -- 매매액면(수량 * 1000)
  I_BOND_TRADE.TRD_AMT      := TRUNC(I_BOND_TRADE.BUY_PRICE * I_BOND_TRADE.TRD_QTY / 10); -- 매매금액(수량 * 단가 / 10)
  I_BOND_TRADE.TRD_NET_AMT  := I_BOND_TRADE.TRD_AMT-I_BOND_TRADE.ACCRUED_INT;             -- 매매정산금액(매매금액 - 경과이자)
  I_BOND_TRADE.BOOK_AMT     := I_BOND_TRADE.TRD_NET_AMT;                                  -- 장부금액
  I_BOND_TRADE.BOOK_PRC_AMT := I_BOND_TRADE.TRD_NET_AMT;                                  -- 장부원가
  
  
  ----------------------------------------------------------------------------------------------------
  -- 5-1)거래내역 등록
  ----------------------------------------------------------------------------------------------------
  INSERT INTO ISS.BOND_TRADE VALUES I_BOND_TRADE;
  
  ----------------------------------------------------------------------------------------------------
  -- 5-2)잔고 등록
  ----------------------------------------------------------------------------------------------------
  INSERT INTO ISS.BOND_BALANCE VALUES T_BOND_BALANCE;
  
  
END;