CREATE OR REPLACE PROCEDURE ISS.PR_NEW_BOND_EVENT (
--I_EVENT_IO            IN OUT EVENT_IO     -- EVNET I/O Object
  I_EVENT_DATE          IN     CHAR(8)      -- 거래일자(EVENT 발생일)
, I_FUND_CODE           IN     CHAR(10)     -- 펀드코드
, I_BOND_CODE           IN     CHAR(12)     -- 종목코드
, I_SETL_DATE           IN     CHAR(8)      -- 결제일자
, I_TRD_QTY             IN     NUMBER(22)   -- 거래수량
, I_TRD_PRICE           IN     NUMBER(22)   -- 거래단가
, I_SELL_RT             IN     NUMBER(10,5) -- 매도율
, I_TRD_TYPE_CD         IN     CHAR(1)      -- 매매유형코드(1.인수, 2.직매수)
, I_GOODS_BUY_SELL_SECT IN     CHAR(1)      -- 상품매수매도구분(1.상품매수, 2.상품매도)
, I_STT_TERM_SECT       IN     CHAR(1)      -- 결제기간구분(0.당일, 1.익일)
, O_RESULT_MSG          IN OUT CHAR(500)    -- 결과 메시지
) IS
  --
  T_EVENT_INFO   PKG_EIR_NESTED_NSC.EVENT_INFO_TYPE; -- TYPE : EVENT INFO
  T_EIR_CALC     PKG_EIR_NESTED_NSC.EIR_CALC_INFO;   -- TYPE : EIR CALC INFO
  T_EVENT_RESULT EVENT_RESULT_NESTED_S%ROWTYPE;      -- ROWTYPE : 이벤트 결과 TABLE
  T_BOND_TRADE   BOND_TRADE%ROWTYPE;                 -- ROWTYPE : 거래내역 TABLE
  T_BOND_BALANCE BOND_BALANCE%ROWTYPE;               -- ROWTYPE : 잔고 TABLE
BEGIN
  -- 1)입력값 검증
  PR_INPUT_VALUE_CHECK(I_EVENT_IO);
  
  
  
  -- 2)변수초기화
  --   * Object들을 초기화 및 Default값으로 설정함
  T_EVENT_RESULT := FN_INIT_EVENT_RESULT();
  T_BOND_TRADE := FN_INIT_BOND_TRADE();
  T_BOND_BALANCE := FN_INIT_BOND_BALANCE();
  
  
  
  -- 3-1)이벤트 처리 INPUT 설정
  PR_CALC_BOND_INFO(I_EVENT_IO, T_EIR_CALC, T_EVENT_INFO);
  
  -- 3-2)이벤트 처리 프로시져 호출
  --   * 매수, 매도, 금리변경, 손상 등 이벤트 처리 프로시져
  --   * 경과이자, 현금흐름 생성, EIR산출, 상각표 생성 등을 처리함
  PKG_EIR_NESTED_NSC.PR_EVENT(T_EIR_CALC, T_EVENT_INFO, T_EVENT_RESULT);
  
  
  
  -- 4)기준정보 계산
  --   * 이벤트 결과 Data를 가지고 기준정보 설정
  --   * 기준정보에 필요한 조회 및 계산 로직 등을 구현
  PR_CALC_BOND_INFO(T_EVENT_RESULT, T_BOND_TRADE);
  
  
  
  -- 5-1)이벤트 결과 등록
  PR_INSERT_EVENT_RESULT(T_EVENT_RESULT);
  
  -- 5-2)거래내역 등록
  PR_INSERT_BOND_TRADE(T_BOND_TRADE);
  
  -- 5-3)잔고 등록
  PR_INSERT_BOND_BALANCE(T_BOND_TRADE, T_BOND_BALANCE);
  
  
END;